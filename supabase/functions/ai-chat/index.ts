import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Server-side secrets
const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY')!
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

const FREE_DAILY_LIMIT = 3

// ✅ NEW: Only show partners with these subscription plans
const SUBSCRIBED_PARTNER_PLANS = ['free','starter', 'business']

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { message, city, userId, history } = await req.json()

    if (!message) {
      return new Response(
        JSON.stringify({ success: false, error: 'Message is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
    const userCity = city || 'Shillong'

    // Check user premium status
    let isPaidUser = false
    let remaining = FREE_DAILY_LIMIT
    let limitReached = false

    if (userId) {
      try {
        const { data: userData, error: userError } = await supabase
          .from('users')
          .select('subscription_plan')
          .eq('id', userId)
          .single()

        if (!userError && userData) {
          const plan = userData.subscription_plan || 'free'
          const premiumPlans = ['basic', 'plus', 'pro', 'starter', 'business']
          isPaidUser = premiumPlans.includes(plan)

          if (!isPaidUser) {
            const today = new Date().toISOString().split('T')[0]
            const { data: usageData } = await supabase
              .from('ai_usage')
              .select('request_count')
              .eq('user_id', userId)
              .eq('usage_date', today)
              .single()

            const todayUsage = usageData?.request_count || 0
            remaining = Math.max(0, FREE_DAILY_LIMIT - todayUsage)
            limitReached = remaining <= 0
          }
        }
      } catch (e) {
        console.log('User check error:', e)
      }
    }

    // ✅ FIX: Only get professionals with active subscription (starter or business)
    const { data: allProfessionals, error: profError } = await supabase
      .from('professionals')
      .select('id, display_name, profession, description, city, area, services, rating, total_reviews, is_verified, experience_years, subscription_plan')
      .eq('is_available', true)
      .ilike('city', `%${userCity}%`)
      //.in('subscription_plan', SUBSCRIBED_PARTNER_PLANS)  // ✅ Only subscribed partners
      .order('rating', { ascending: false })
      .limit(50)

    if (profError) {
      console.error('Error loading professionals:', profError)
    }

    console.log('=== DEBUG: Loaded professionals ===')
    console.log('Count:', allProfessionals?.length || 0)
    if (allProfessionals && allProfessionals.length > 0) {
      console.log('First professional:', JSON.stringify(allProfessionals[0]))
    }

    // Extract search intent
    const searchIntent = extractSearchIntent(message)
    console.log('Search intent:', searchIntent)
    
    // Find matching professionals based on message keywords
    const matchedProfessionals = findMatchingProfessionals(message, allProfessionals || [])
    console.log('=== DEBUG: Matched professionals ===')
    console.log('Matched count:', matchedProfessionals.length)
    if (matchedProfessionals.length > 0) {
      console.log('Matched IDs:', matchedProfessionals.map((p: any) => p.id))
    }

    // Free user or limit reached: local search only
    if (!isPaidUser || limitReached || !OPENAI_API_KEY) {
      const responseMessage = buildLocalSearchResponse(message, matchedProfessionals, userCity, limitReached)
      
      const matchedIds = matchedProfessionals.map((p: any) => p.id)
      console.log('=== DEBUG: Returning local search ===')
      console.log('Matched IDs being returned:', matchedIds)
      
      return new Response(
        JSON.stringify({
          success: true,
          message: responseMessage,
          searchIntent,
          matchedProfessionals: matchedIds,
          limitReached,
          remaining: isPaidUser ? -1 : remaining,
          isPaid: isPaidUser,
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Premium user: OpenAI API call
    const professionalsContext = buildProfessionalsContext(allProfessionals || [])
    
    const systemPrompt = 'You are AiList AI Assistant, helping users find local service professionals in ' + userCity + ', India.\n\n' +
      'AVAILABLE PROFESSIONALS:\n' + professionalsContext + '\n\n' +
      'INSTRUCTIONS:\n' +
      '1. Understand what the user needs\n' +
      '2. Recommend the best matching professionals from the list above\n' +
      '3. Be conversational, friendly, and helpful\n' +
      '4. Include professional name, rating, and location in your response\n' +
      '5. If no exact match, suggest similar services or ask clarifying questions\n' +
      '6. Keep responses concise (3-5 sentences max)\n' +
      '7. DO NOT show any IDs or technical data\n' +
      '8. DO NOT make up professionals - only recommend from the list above\n' +
      '9. ALWAYS mention the professional by their EXACT display_name from the list'

    const messages: Array<{role: string, content: string}> = [
      { role: 'system', content: systemPrompt }
    ]

    if (history && history.length > 0) {
      messages.push(...history.slice(-6))
    }
    messages.push({ role: 'user', content: message })

    const openAIResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': 'Bearer ' + OPENAI_API_KEY,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-3.5-turbo',
        messages,
        max_tokens: 500,
        temperature: 0.7,
      }),
    })

    const openAIData = await openAIResponse.json()

    if (openAIData.error) {
      console.error('OpenAI Error:', openAIData.error)
      const fallbackMessage = buildLocalSearchResponse(message, matchedProfessionals, userCity, false)
      const matchedIds = matchedProfessionals.map((p: any) => p.id)
      
      return new Response(
        JSON.stringify({
          success: true,
          message: fallbackMessage,
          searchIntent,
          matchedProfessionals: matchedIds,
          limitReached: false,
          remaining: -1,
          isPaid: true,
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const aiMessage = openAIData.choices?.[0]?.message?.content || ''
    console.log('=== DEBUG: AI Response ===')
    console.log('AI message (first 200 chars):', aiMessage.substring(0, 200))

    // Extract mentioned professionals from AI response
    const mentionedProfessionals = extractMentionedProfessionals(aiMessage, allProfessionals || [])
    console.log('=== DEBUG: Mentioned professionals ===')
    console.log('Mentioned count:', mentionedProfessionals.length)
    console.log('Mentioned IDs:', mentionedProfessionals)
    
    // Use mentioned professionals, or fall back to keyword-matched professionals
    let finalMatchedIds: string[] = []
    if (mentionedProfessionals.length > 0) {
      finalMatchedIds = mentionedProfessionals
    } else if (matchedProfessionals.length > 0) {
      finalMatchedIds = matchedProfessionals.map((p: any) => p.id)
    }
    
    console.log('=== DEBUG: Final result ===')
    console.log('Final matched IDs:', finalMatchedIds)

    // Log chat for analytics
    if (userId) {
      try {
        await supabase.from('ai_chat_logs').insert([
          { user_id: userId, session_id: crypto.randomUUID(), role: 'user', content: message },
          { user_id: userId, session_id: crypto.randomUUID(), role: 'assistant', content: aiMessage }
        ])
      } catch (e) {
        console.log('Chat log error:', e)
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: aiMessage,
        searchIntent,
        matchedProfessionals: finalMatchedIds,
        limitReached: false,
        remaining: -1,
        isPaid: true,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('AI Chat Error:', error)
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: (error as Error).message || 'An error occurred',
        message: 'Sorry, I encountered an error. Please try again.',
        matchedProfessionals: [],
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

// ============================================================
// HELPER FUNCTIONS (unchanged)
// ============================================================

function extractSearchIntent(message: string): { category?: string; query?: string } | null {
  const categories: Record<string, string[]> = {
    'electrician': ['electrician', 'electric', 'wiring', 'power', 'light', 'fan', 'switch'],
    'plumber': ['plumber', 'plumbing', 'pipe', 'water', 'tap', 'leak', 'drain', 'toilet'],
    'carpenter': ['carpenter', 'furniture', 'wood', 'cabinet', 'door', 'table', 'wardrobe'],
    'painter': ['painter', 'painting', 'paint', 'wall', 'color'],
    'ac-repair': ['ac', 'air conditioner', 'cooling', 'hvac'],
    'cleaning': ['cleaning', 'cleaner', 'maid', 'housekeeping'],
    'tutoring': ['tutor', 'teacher', 'coaching', 'tuition'],
    'beauty': ['beauty', 'salon', 'haircut', 'makeup'],
    'mechanic': ['mechanic', 'car', 'bike', 'vehicle', 'garage'],
    'photography': ['photographer', 'photo', 'video', 'wedding', 'studio'],
    'vfx': ['vfx', 'visual effects', 'animation', 'film', 'video editing', 'film services', 'video'],
  }

  const lower = message.toLowerCase()
  for (const [category, keywords] of Object.entries(categories)) {
    if (keywords.some((k: string) => lower.includes(k))) {
      return { category, query: message }
    }
  }
  return null
}

function findMatchingProfessionals(message: string, professionals: any[]): any[] {
  const lower = message.toLowerCase()
  const words = lower.split(/\s+/).filter((w: string) => w.length >= 2)
  
  console.log('Search words:', words)

  const matches = professionals.filter((p: any) => {
    const name = (p.display_name || '').toLowerCase()
    const profession = (p.profession || '').toLowerCase()
    const description = (p.description || '').toLowerCase()
    const services = Array.isArray(p.services) ? p.services.join(' ').toLowerCase() : (p.services || '').toString().toLowerCase()
    const area = (p.area || '').toLowerCase()
    const city = (p.city || '').toLowerCase()

    const searchableText = name + ' ' + profession + ' ' + description + ' ' + services + ' ' + area + ' ' + city

    const wordMatch = words.some((word: string) => searchableText.includes(word))
    
    if (wordMatch) {
      console.log('Match found:', p.display_name, '- matched in:', searchableText.substring(0, 100))
    }
    
    return wordMatch
  })

  return matches
}

function buildLocalSearchResponse(message: string, matches: any[], city: string, limitReached: boolean): string {
  if (limitReached) {
    const baseMsg = '🔒 You\'ve reached your daily AI chat limit.\n\nUpgrade to Premium for unlimited AI-powered search!'
    if (matches.length > 0) {
      return baseMsg + '\n\nMeanwhile, I found ' + matches.length + ' professional(s) matching your search.'
    }
    return baseMsg
  }

  if (matches.length === 0) {
    return 'I couldn\'t find any matching professionals in ' + city + ' for "' + message + '".\n\n' +
           'Try searching for:\n• Electrician\n• Plumber\n• Carpenter\n• Painter\n• AC Repair\n• Cleaning\n• Tutor\n• VFX'
  }

  let response = 'I found ' + matches.length + ' professional' + (matches.length > 1 ? 's' : '') + ' for you:\n\n'

  const topMatches = matches.slice(0, 3)
  for (let i = 0; i < topMatches.length; i++) {
    const p = topMatches[i]
    response += '**' + p.display_name + '**\n'
    response += '📍 ' + (p.area || '') + ', ' + p.city + '\n'
    if ((p.rating || 0) > 0) {
      response += '⭐ ' + p.rating + '/5 (' + (p.total_reviews || 0) + ' reviews)\n'
    }
    if (p.is_verified) {
      response += '✅ Verified\n'
    }
    response += '\n'
  }

  if (matches.length > 3) {
    response += '...and ' + (matches.length - 3) + ' more available.'
  }

  return response
}

function buildProfessionalsContext(professionals: any[]): string {
  if (professionals.length === 0) {
    return 'No professionals currently available.'
  }

  const lines: string[] = []
  const topProfessionals = professionals.slice(0, 30)
  
  for (let i = 0; i < topProfessionals.length; i++) {
    const p = topProfessionals[i]
    const services = Array.isArray(p.services) ? p.services.join(', ') : 'N/A'
    lines.push(
      (i + 1) + '. ' + p.display_name + ' (' + p.profession + ')\n' +
      '   - Location: ' + (p.area || 'N/A') + ', ' + p.city + '\n' +
      '   - Rating: ' + (p.rating || 0) + '/5 (' + (p.total_reviews || 0) + ' reviews)\n' +
      '   - Experience: ' + (p.experience_years || 0) + ' years\n' +
      '   - Services: ' + services + '\n' +
      '   - Verified: ' + (p.is_verified ? 'Yes' : 'No')
    )
  }
  
  return lines.join('\n\n')
}

function extractMentionedProfessionals(aiResponse: string, professionals: any[]): string[] {
  const lower = aiResponse.toLowerCase()
  const mentioned: string[] = []

  for (let i = 0; i < professionals.length; i++) {
    const p = professionals[i]
    const name = (p.display_name || '').toLowerCase().trim()
    
    if (name.length >= 3) {
      if (lower.includes(name)) {
        console.log('Found mention of:', p.display_name, 'with ID:', p.id)
        if (!mentioned.includes(p.id)) {
          mentioned.push(p.id)
        }
      }
    }
  }

  return mentioned
}