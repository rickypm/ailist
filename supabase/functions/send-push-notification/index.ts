import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

// FCM v1 API credentials (recommended)
const FIREBASE_PROJECT_ID = Deno.env.get('FIREBASE_PROJECT_ID')
const FIREBASE_SERVICE_ACCOUNT = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')

// Legacy API fallback (deprecated - remove after migration)
const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY')

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// ============================================================
// FCM v1 API: Generate OAuth 2.0 Access Token
// ============================================================

async function getAccessToken(): Promise<string> {
  if (!FIREBASE_SERVICE_ACCOUNT) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT not configured')
  }

  const serviceAccount = JSON.parse(FIREBASE_SERVICE_ACCOUNT)
  
  // Create JWT header and claim set
  const header = {
    alg: 'RS256',
    typ: 'JWT',
  }

  const now = Math.floor(Date.now() / 1000)
  const claimSet = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600, // 1 hour
  }

  // Base64URL encode
  const base64UrlEncode = (obj: object): string => {
    const json = JSON.stringify(obj)
    const base64 = btoa(json)
    return base64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
  }

  const headerEncoded = base64UrlEncode(header)
  const claimSetEncoded = base64UrlEncode(claimSet)
  const signatureInput = `${headerEncoded}.${claimSetEncoded}`

  // Sign with private key using Web Crypto API
  const privateKeyPem = serviceAccount.private_key
  const pemContents = privateKeyPem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\n/g, '')

  const binaryKey = Uint8Array.from(atob(pemContents), c => c.charCodeAt(0))

  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    binaryKey,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign']
  )

  const signatureBuffer = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    new TextEncoder().encode(signatureInput)
  )

  const signature = btoa(String.fromCharCode(...new Uint8Array(signatureBuffer)))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '')

  const jwt = `${signatureInput}.${signature}`

  // Exchange JWT for access token
  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  })

  if (!tokenResponse.ok) {
    const error = await tokenResponse.text()
    throw new Error(`Failed to get access token: ${error}`)
  }

  const tokenData = await tokenResponse.json()
  return tokenData.access_token
}

// ============================================================
// FCM v1 API: Send Push Notification
// ============================================================

interface FCMMessage {
  token: string
  notification: {
    title: string
    body: string
    image?: string
  }
  data?: Record<string, string>
  android?: {
    priority: 'high' | 'normal'
    notification?: {
      sound: string
      click_action?: string
      channel_id?: string
    }
  }
  apns?: {
    payload: {
      aps: {
        sound: string
        badge?: number
        'content-available'?: number
      }
    }
  }
}

async function sendFCMv1(
  accessToken: string,
  projectId: string,
  message: FCMMessage
): Promise<{ success: boolean; error?: string; messageId?: string }> {
  const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ message }),
    })

    const result = await response.json()

    if (response.ok) {
      return { success: true, messageId: result.name }
    } else {
      // Handle specific FCM errors
      const errorCode = result.error?.details?.[0]?.errorCode || result.error?.status
      
      // Token is invalid/expired - should remove from database
      if (errorCode === 'UNREGISTERED' || errorCode === 'INVALID_ARGUMENT') {
        return { success: false, error: `invalid_token:${errorCode}` }
      }
      
      return { success: false, error: result.error?.message || 'Unknown error' }
    }
  } catch (e) {
    return { success: false, error: (e as Error).message }
  }
}

// ============================================================
// Legacy FCM API (Fallback - Deprecated)
// ============================================================

async function sendLegacyFCM(
  serverKey: string,
  deviceToken: string,
  notification: { title: string; body: string; image_url?: string },
  data: Record<string, string>
): Promise<{ success: boolean; error?: string }> {
  try {
    const response = await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        'Authorization': `key=${serverKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        to: deviceToken,
        notification: {
          title: notification.title,
          body: notification.body,
          image: notification.image_url,
          sound: 'default',
        },
        data: {
          ...data,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: { priority: 'high' },
      }),
    })

    const result = await response.json()
    
    if (result.success === 1) {
      return { success: true }
    } else {
      return { success: false, error: result.results?.[0]?.error || 'Unknown error' }
    }
  } catch (e) {
    return { success: false, error: (e as Error).message }
  }
}

// ============================================================
// Main Handler
// ============================================================

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { notification_id } = await req.json()

    if (!notification_id) {
      throw new Error('notification_id is required')
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    // Get notification details
    const { data: notification, error: notifError } = await supabase
      .from('push_notifications')
      .select('*')
      .eq('id', notification_id)
      .single()

    if (notifError || !notification) {
      throw new Error('Notification not found')
    }

    // Update status to sending
    await supabase
      .from('push_notifications')
      .update({ status: 'sending' })
      .eq('id', notification_id)

    // Build device query
    let deviceQuery = supabase
      .from('user_devices')
      .select('device_token, user_id, platform')
      .eq('is_active', true)

    // Filter by specific users
    if (notification.target_user_ids && notification.target_user_ids.length > 0) {
      deviceQuery = deviceQuery.in('user_id', notification.target_user_ids)
    } 
    // Filter by audience type
    else if (notification.target_audience !== 'all') {
      const { data: targetUsers } = await supabase
        .from('users')
        .select('id')
        .or(
          notification.target_audience === 'users' ? 'role.eq.user' :
          notification.target_audience === 'partners' ? 'role.in.(partner,professional)' :
          notification.target_audience === 'free' ? 'subscription_plan.eq.free' :
          'subscription_plan.in.(basic,plus,pro,starter,business)'
        )

      if (targetUsers && targetUsers.length > 0) {
        const userIds = targetUsers.map(u => u.id)
        deviceQuery = deviceQuery.in('user_id', userIds)
      }
    }

    const { data: devices, error: devicesError } = await deviceQuery

    if (devicesError) {
      console.error('❌ Device query error:', devicesError)
    }

    if (!devices || devices.length === 0) {
      await supabase
        .from('push_notifications')
        .update({ 
          status: 'sent', 
          sent_at: new Date().toISOString(), 
          sent_count: 0 
        })
        .eq('id', notification_id)

      return new Response(
        JSON.stringify({ success: true, sent: 0, message: 'No devices to send to' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`📤 Sending to ${devices.length} devices...`)

    let sentCount = 0
    let failedCount = 0
    const invalidTokenDeviceIds: string[] = []

    // ✅ Use FCM v1 API (Recommended)
    if (FIREBASE_PROJECT_ID && FIREBASE_SERVICE_ACCOUNT) {
      console.log('🚀 Using FCM v1 API')
      
      try {
        const accessToken = await getAccessToken()
        
        for (const device of devices) {
          const message: FCMMessage = {
            token: device.device_token,
            notification: {
              title: notification.title,
              body: notification.body,
              image: notification.image_url || undefined,
            },
            data: {
              action_type: notification.action_type || 'open_app',
              action_data: notification.action_data || '',
              notification_id: notification_id,
            },
            android: {
              priority: 'high',
              notification: {
                sound: 'default',
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
                channel_id: 'high_importance_channel',
              },
            },
            apns: {
              payload: {
                aps: {
                  sound: 'default',
                  'content-available': 1,
                },
              },
            },
          }

          const result = await sendFCMv1(accessToken, FIREBASE_PROJECT_ID, message)
          
          if (result.success) {
            sentCount++
            console.log(`✅ Sent to device: ${device.device_token.substring(0, 20)}...`)
          } else {
            failedCount++
            console.error(`❌ Failed for device ${device.id}: ${result.error}`)
            
            // Track invalid tokens for cleanup
            if (result.error?.startsWith('invalid_token')) {
              invalidTokenDeviceIds.push(device.id)
            }
          }
        }
      } catch (e) {
        console.error('❌ FCM v1 API error:', e)
        // Fall through to legacy if v1 fails completely
        if (FCM_SERVER_KEY) {
          console.log('⚠️ Falling back to Legacy API...')
        }
      }
    }
    
    // ⚠️ Fallback to Legacy API (Deprecated)
    if (sentCount === 0 && failedCount === 0 && FCM_SERVER_KEY) {
      console.log('⚠️ Using Legacy FCM API (deprecated)')
      
      for (const device of devices) {
        const result = await sendLegacyFCM(
          FCM_SERVER_KEY,
          device.device_token,
          notification,
          {
            action_type: notification.action_type || 'open_app',
            action_data: notification.action_data || '',
            notification_id: notification_id,
          }
        )
        
        if (result.success) {
          sentCount++
        } else {
          failedCount++
          console.error(`❌ Legacy failed: ${result.error}`)
          
          if (result.error === 'NotRegistered' || result.error === 'InvalidRegistration') {
            invalidTokenDeviceIds.push(device.id)
          }
        }
      }
    }

    // No API configured
    if (sentCount === 0 && failedCount === 0) {
      console.error('❌ No FCM API configured!')
      failedCount = devices.length
    }

    // 🧹 Cleanup invalid tokens
    if (invalidTokenDeviceIds.length > 0) {
      console.log(`🧹 Removing ${invalidTokenDeviceIds.length} invalid device tokens...`)
      await supabase
        .from('user_devices')
        .update({ is_active: false })
        .in('id', invalidTokenDeviceIds)
    }

    // Update notification status
    await supabase
      .from('push_notifications')
      .update({
        status: 'sent',
        sent_at: new Date().toISOString(),
        sent_count: sentCount,
        failed_count: failedCount,
      })
      .eq('id', notification_id)

    console.log(`📊 Results: ${sentCount} sent, ${failedCount} failed`)

    return new Response(
      JSON.stringify({ 
        success: true, 
        sent: sentCount, 
        failed: failedCount,
        total_devices: devices.length,
        invalid_tokens_removed: invalidTokenDeviceIds.length,
        api_used: FIREBASE_PROJECT_ID ? 'fcm_v1' : 'legacy'
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('❌ Push notification error:', error)
    return new Response(
      JSON.stringify({ success: false, error: (error as Error).message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})