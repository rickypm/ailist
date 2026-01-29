import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { createHmac } from "https://deno.land/std@0.168.0/node/crypto.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { 
      razorpay_order_id, 
      razorpay_payment_id, 
      razorpay_signature,
      subscription_id,
      user_id,
      plan 
    } = await req.json()

    // Get secret from environment
    const keySecret = Deno.env.get('RAZORPAY_KEY_SECRET')
    
    if (!keySecret) {
      throw new Error('Razorpay secret not configured')
    }

    // Verify signature
    const body = razorpay_order_id + "|" + razorpay_payment_id
    const expectedSignature = createHmac("sha256", keySecret)
      .update(body)
      .digest("hex")

    const isValid = expectedSignature === razorpay_signature

    if (!isValid) {
      return new Response(
        JSON.stringify({ success: false, error: 'Invalid signature' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
      )
    }

    // Signature valid - Update database
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey)

    const now = new Date().toISOString()
    const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString()

    // Update subscription
    if (subscription_id) {
      await supabase
        .from('subscriptions')
        .update({
          payment_id: razorpay_payment_id,
          order_id: razorpay_order_id,
          signature: razorpay_signature,
          status: 'active',
          starts_at: now,
          expires_at: expiresAt,
          updated_at: now,
          verified: true,
        })
        .eq('id', subscription_id)
    }

    // Update user plan
    if (user_id && plan) {
      let unlockBalance = 0
      if (plan === 'basic') unlockBalance = 3
      if (plan === 'plus' || plan === 'pro') unlockBalance = -1

      await supabase
        .from('users')
        .update({
          subscription_plan: plan,
          unlock_balance: unlockBalance,
          updated_at: now,
        })
        .eq('id', user_id)
    }

    return new Response(
      JSON.stringify({ success: true, verified: true }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})