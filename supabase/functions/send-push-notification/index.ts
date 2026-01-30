import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

// For Legacy API (if you have server key)
const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY')

// For FCM v1 API (recommended)
const FIREBASE_PROJECT_ID = Deno.env.get('FIREBASE_PROJECT_ID')
const FIREBASE_SERVICE_ACCOUNT = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

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
      console.error('Device query error:', devicesError)
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

    // Use Legacy API if server key is available
    if (FCM_SERVER_KEY) {
      for (const device of devices) {
        try {
          const fcmResponse = await fetch('https://fcm.googleapis.com/fcm/send', {
            method: 'POST',
            headers: {
              'Authorization': `key=${FCM_SERVER_KEY}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              to: device.device_token,
              notification: {
                title: notification.title,
                body: notification.body,
                image: notification.image_url,
                sound: 'default',
              },
              data: {
                action_type: notification.action_type || 'open_app',
                action_data: notification.action_data || '',
                notification_id: notification_id,
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
              },
              android: {
                priority: 'high',
              },
            }),
          })

          const fcmResult = await fcmResponse.json()
          
          if (fcmResult.success === 1) {
            sentCount++
          } else {
            failedCount++
            console.error(`❌ Failed:`, fcmResult)
          }
        } catch (e) {
          failedCount++
          console.error(`❌ Error:`, e)
        }
      }
    } else {
      // No FCM key configured
      console.log('⚠️ FCM_SERVER_KEY not configured')
      failedCount = devices.length
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
        total_devices: devices.length 
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Push notification error:', error)
    return new Response(
      JSON.stringify({ success: false, error: (error as Error).message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})