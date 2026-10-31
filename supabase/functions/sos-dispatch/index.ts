import { createClient } from 'jsr:@supabase/supabase-js@2'

type SosRequest = { institution_id: string; location_label?: string }

Deno.serve(async (request) => {
  if (request.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  const authorization = request.headers.get('Authorization')
  if (!authorization) {
    return Response.json({ error: 'Authentication is required.' }, { status: 401 })
  }

  const projectUrl = Deno.env.get('SUPABASE_URL')
  const publishableKey = Deno.env.get('SUPABASE_ANON_KEY')
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  if (!projectUrl || !publishableKey || !serviceRoleKey) {
    return Response.json({ error: 'Function configuration is incomplete.' }, { status: 500 })
  }

  const callerClient = createClient(projectUrl, publishableKey, { global: { headers: { Authorization: authorization } } })
  const { data: userData, error: userError } = await callerClient.auth.getUser()
  if (userError || !userData.user) {
    return Response.json({ error: 'Invalid session.' }, { status: 401 })
  }

  const payload = await request.json() as SosRequest
  if (!payload.institution_id || typeof payload.institution_id !== 'string') {
    return Response.json({ error: 'institution_id is required.' }, { status: 400 })
  }
  if (payload.location_label && (typeof payload.location_label !== 'string' || payload.location_label.length > 160)) {
    return Response.json({ error: 'location_label is invalid.' }, { status: 400 })
  }

  const adminClient = createClient(projectUrl, serviceRoleKey)
  const userId = userData.user.id
  const { data: membership } = await adminClient.from('institution_memberships').select('role, active').eq('institution_id', payload.institution_id).eq('user_id', userId).eq('role', 'student').eq('active', true).maybeSingle()
  if (!membership) {
    return Response.json({ error: 'This account cannot send an SOS for this institution.' }, { status: 403 })
  }

  const { data: emergency, error: emergencyError } = await adminClient.from('emergency_events').insert({ institution_id: payload.institution_id, student_id: userId, location_label: payload.location_label?.trim() || null }).select('id, requested_at').single()
  if (emergencyError) {
    console.error('Unable to create emergency event', emergencyError)
    return Response.json({ error: 'Unable to create emergency event.' }, { status: 500 })
  }

  const { data: responders } = await adminClient.from('institution_memberships').select('user_id').eq('institution_id', payload.institution_id).eq('active', true).in('role', ['super_admin', 'institution_admin', 'security'])
  const notifications = (responders ?? []).map((responder) => ({ recipient_id: responder.user_id, institution_id: payload.institution_id, kind: 'emergency', title: 'Student SOS requires review', body: 'An SOS request was created. Open the authorised response workspace for details.', related_emergency_id: emergency.id }))
  if (notifications.length > 0) {
    const { error: notificationError } = await adminClient.from('notifications').insert(notifications)
    if (notificationError) console.error('Emergency notification queue error', notificationError)
  }

  return Response.json({ emergency_id: emergency.id, requested_at: emergency.requested_at, status: 'reported' }, { status: 201 })
})

