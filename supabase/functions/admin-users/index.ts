import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Operaciones administrativas (gestionar admins, otorgar/revocar ManiGrabLovers)
// que antes se hacían desde el cliente Flutter usando el service_role key
// directamente (lib/services/admin_service.dart). Ese patrón exponía la key
// completa (bypass total de RLS) en el APK/IPA/bundle web. Ahora la key vive
// solo aquí, server-side, y cada acción se valida contra es_admin(auth.uid())
// antes de ejecutarse.

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

const TIPOS_VALIDOS = ['monthly', 'yearly']
const PRODUCT_IDS: Record<string, string> = {
  monthly: 'manigrab_lovers_monthly',
  yearly: 'manigrab_lovers_yearly',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
    const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

    // --- SEGURIDAD: verificar JWT + rol admin (tabla users_admin vía es_admin()) ---
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'No se proporcionó token de autorización' }), { status: 401, headers: corsHeaders })
    }
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await admin.auth.getUser(token)
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Sesión inválida' }), { status: 401, headers: corsHeaders })
    }
    const { data: isAdmin, error: adminCheckError } = await admin.rpc('es_admin', { user_uuid: user.id })
    if (adminCheckError || !isAdmin) {
      console.error(`Acceso admin denegado para: ${user.email}`)
      return new Response(JSON.stringify({ error: 'No autorizado' }), { status: 403, headers: corsHeaders })
    }
    // --------------------------------------------------------------------------

    const body = await req.json().catch(() => ({}))
    const action = body.action as string

    async function buscarUsuarioPorEmail(email: string) {
      const { data, error } = await admin
        .from('users')
        .select('id')
        .eq('email', email.toLowerCase().trim())
        .maybeSingle()
      if (error) throw error
      return data?.id as string | undefined
    }

    switch (action) {
      case 'list_admins': {
        const { data, error } = await admin
          .from('users_admin')
          .select('id, user_id, users!inner(id, email, name, created_at)')
          .order('id', { ascending: false })
        if (error) throw error
        return new Response(JSON.stringify({ data }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
      }

      case 'add_titulo_relacionado': {
        const { codigoExistente, titulo, descripcion, categoria, fuente, sugerenciaId, usuarioId } = body
        if (!codigoExistente || !titulo) throw new Error('codigoExistente y titulo requeridos')
        const { data, error } = await admin
          .from('codigos_titulos_relacionados')
          .insert({
            codigo_existente: codigoExistente,
            titulo,
            descripcion: descripcion ?? null,
            categoria: categoria ?? null,
            fuente: fuente ?? 'sugerencia_aprobada',
            sugerencia_id: sugerenciaId ?? null,
            usuario_id: usuarioId ?? null,
          })
          .select('id')
          .single()
        if (error) throw error
        return new Response(JSON.stringify({ id: data.id }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
      }

      case 'add_admin': {
        const userId = body.userId as string
        if (!userId) throw new Error('userId requerido')
        const { error } = await admin.from('users_admin').insert({ user_id: userId })
        if (error) throw error
        return new Response(JSON.stringify({ success: true }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
      }

      case 'remove_admin': {
        const userId = body.userId as string
        if (!userId) throw new Error('userId requerido')
        const { error } = await admin.from('users_admin').delete().eq('user_id', userId)
        if (error) throw error
        return new Response(JSON.stringify({ success: true }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
      }

      case 'search_user_by_email': {
        const email = body.email as string
        if (!email) throw new Error('email requerido')
        const userId = await buscarUsuarioPorEmail(email)
        return new Response(JSON.stringify({ userId: userId ?? null }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
      }

      case 'grant_subscription': {
        const email = body.email as string
        const tipo = body.tipo as string
        if (!email || !TIPOS_VALIDOS.includes(tipo)) throw new Error('email y tipo (monthly|yearly) requeridos')

        const userId = await buscarUsuarioPorEmail(email)
        if (!userId) throw new Error(`Usuario no encontrado con el email: ${email}`)

        const expiryDate = new Date()
        expiryDate.setDate(expiryDate.getDate() + (tipo === 'monthly' ? 30 : 365))

        // Solo desactivar cortesías ManiGrabLovers previas del usuario, NUNCA
        // una suscripción real (Play Store/App Store) que comparte esta misma
        // tabla — antes este update no filtraba por product_id y desactivaba
        // CUALQUIER suscripción activa, incluida una ya pagada, sin forma de
        // restaurarla automáticamente después.
        await admin.from('user_subscriptions')
          .update({ is_active: false })
          .eq('user_id', userId)
          .eq('is_active', true)
          .filter('product_id', 'in', '("manigrab_lovers_monthly","manigrab_lovers_yearly")')

        const { error } = await admin.from('user_subscriptions').insert({
          user_id: userId,
          product_id: PRODUCT_IDS[tipo],
          purchase_id: `manigrab_lovers_admin_${Date.now()}`,
          transaction_date: new Date().toISOString(),
          expires_at: expiryDate.toISOString(),
          is_active: true,
          created_at: new Date().toISOString(),
        })
        if (error) throw error
        return new Response(JSON.stringify({ success: true, expiresAt: expiryDate.toISOString() }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
      }

      case 'revoke_subscription': {
        const email = body.email as string
        if (!email) throw new Error('email requerido')
        const userId = await buscarUsuarioPorEmail(email)
        if (!userId) throw new Error(`Usuario no encontrado con el email: ${email}`)

        const { error } = await admin.from('user_subscriptions')
          .update({ is_active: false })
          .eq('user_id', userId)
          .filter('product_id', 'in', '("manigrab_lovers_monthly","manigrab_lovers_yearly")')
          .eq('is_active', true)
        if (error) throw error
        return new Response(JSON.stringify({ success: true }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
      }

      case 'get_subscription': {
        const email = body.email as string
        if (!email) throw new Error('email requerido')
        const userId = await buscarUsuarioPorEmail(email)
        if (!userId) return new Response(JSON.stringify({ data: null }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })

        const { data, error } = await admin.from('user_subscriptions')
          .select('*')
          .eq('user_id', userId)
          .filter('product_id', 'in', '("manigrab_lovers_monthly","manigrab_lovers_yearly")')
          .eq('is_active', true)
          .order('expires_at', { ascending: false })
          .limit(1)
          .maybeSingle()
        if (error) throw error
        return new Response(JSON.stringify({ data }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
      }

      case 'list_subscriptions': {
        const { data: subs, error } = await admin.from('user_subscriptions')
          .select('id, user_id, product_id, expires_at, created_at')
          .filter('product_id', 'in', '("manigrab_lovers_monthly","manigrab_lovers_yearly")')
          .eq('is_active', true)
          .order('expires_at', { ascending: false })
        if (error) throw error

        const result = []
        for (const row of subs ?? []) {
          const { data: userData } = await admin.from('users').select('email, name').eq('id', row.user_id).maybeSingle()
          result.push({ ...row, user_email: userData?.email, user_name: userData?.name })
        }
        return new Response(JSON.stringify({ data: result }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
      }

      // ===== FOUNDERS EDITION (Origen 369): pago único vía Hotmart, fuera =====
      // ===== del flujo de IAP/Supabase. No hay webhook automático todavía, =====
      // ===== así que el admin lo asigna manualmente tras confirmar el pago. ====
      case 'grant_founder': {
        const email = body.email as string
        if (!email) throw new Error('email requerido')
        const userId = await buscarUsuarioPorEmail(email)
        if (!userId) throw new Error(`Usuario no encontrado con el email: ${email}`)

        // "Acceso vitalicio": expiración muy lejana en vez de NULL, para
        // reutilizar la misma lógica de "suscripción activa" que ya usa
        // checkSubscriptionStatus()/isFreeUser en el cliente.
        const lifetimeExpiry = new Date('2099-12-31T23:59:59Z')

        // Igual que en grant_subscription: solo desactivar un Founders Edition
        // previo, nunca una suscripción real activa de otro producto.
        await admin.from('user_subscriptions')
          .update({ is_active: false })
          .eq('user_id', userId)
          .eq('is_active', true)
          .eq('product_id', 'founders_edition_369')

        const { error: subError } = await admin.from('user_subscriptions').insert({
          user_id: userId,
          product_id: 'founders_edition_369',
          purchase_id: `founder_admin_${Date.now()}`,
          transaction_date: new Date().toISOString(),
          expires_at: lifetimeExpiry.toISOString(),
          is_active: true,
          created_at: new Date().toISOString(),
        })
        if (subError) throw subError

        const { data: userRow, error: userErr } = await admin.from('users').select('achievements').eq('id', userId).maybeSingle()
        if (userErr) throw userErr
        const current: string[] = userRow?.achievements ?? []
        if (!current.includes('founder_369')) {
          const { error: achError } = await admin.from('users')
            .update({ achievements: [...current, 'founder_369'] })
            .eq('id', userId)
          if (achError) throw achError
        }

        return new Response(JSON.stringify({ success: true, expiresAt: lifetimeExpiry.toISOString() }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
      }

      case 'revoke_founder': {
        const email = body.email as string
        if (!email) throw new Error('email requerido')
        const userId = await buscarUsuarioPorEmail(email)
        if (!userId) throw new Error(`Usuario no encontrado con el email: ${email}`)

        const { error: subError } = await admin.from('user_subscriptions')
          .update({ is_active: false })
          .eq('user_id', userId)
          .eq('product_id', 'founders_edition_369')
          .eq('is_active', true)
        if (subError) throw subError

        const { data: userRow, error: userErr } = await admin.from('users').select('achievements').eq('id', userId).maybeSingle()
        if (userErr) throw userErr
        const current: string[] = userRow?.achievements ?? []
        const { error: achError } = await admin.from('users')
          .update({ achievements: current.filter((a: string) => a !== 'founder_369') })
          .eq('id', userId)
        if (achError) throw achError

        return new Response(JSON.stringify({ success: true }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
      }

      case 'list_founders': {
        const { data: subs, error } = await admin.from('user_subscriptions')
          .select('id, user_id, expires_at, created_at')
          .eq('product_id', 'founders_edition_369')
          .eq('is_active', true)
          .order('created_at', { ascending: false })
        if (error) throw error

        const result = []
        for (const row of subs ?? []) {
          const { data: userData } = await admin.from('users').select('email, name').eq('id', row.user_id).maybeSingle()
          result.push({ ...row, user_email: userData?.email, user_name: userData?.name })
        }
        return new Response(JSON.stringify({ data: result }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
      }

      // Botón "Probar Notificaciones" (solo admin, en Perfil > Configuración):
      // manda un push real al propio admin usando notify_push_from_db, el
      // mismo camino que usan los triggers/crons reales. El push secret
      // nunca sale de este servidor — el cliente solo pide "envíame esta
      // prueba" con su propio JWT, ya verificado como admin arriba.
      case 'send_test_notification': {
        const title = body.title as string
        const notifBody = body.body as string
        if (!title || !notifBody) throw new Error('title y body requeridos')

        const { error } = await admin.rpc('notify_push_from_db', {
          p_user_id: user.id,
          p_title: title,
          p_body: notifBody,
          p_data: { type: 'admin_test' },
        })
        if (error) throw error

        return new Response(JSON.stringify({ success: true }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
      }

      // Notifica al usuario que reportó un código cuando un admin cambia el
      // estatus de su reporte (Ver Reportes > detalle). Antes esto se hacía
      // con NotificationHistory.addNotification(), que escribe en
      // SharedPreferences del dispositivo que ejecuta el código — es decir,
      // el del propio admin, no el del usuario que reportó. El usuario nunca
      // se enteraba. Usa el mismo camino real que send_test_notification.
      case 'notify_report_status': {
        const targetUserId = body.userId as string
        const title = body.title as string
        const notifBody = body.body as string
        if (!targetUserId || !title || !notifBody) throw new Error('userId, title y body requeridos')

        const { error } = await admin.rpc('notify_push_from_db', {
          p_user_id: targetUserId,
          p_title: title,
          p_body: notifBody,
          p_data: { type: 'reporte_estatus' },
        })
        if (error) throw error

        return new Response(JSON.stringify({ success: true }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
      }

      // Código Especial del Mes (monthlySpecialCode): el admin lo dispara a
      // mano — se envía como broadcast (topic 'all', todo usuario se
      // suscribe a él al iniciar la app) en vez de un push por cron, porque
      // depende de una decisión editorial del admin, no de un evento medible.
      case 'broadcast_special_code': {
        const codigo = body.codigo as string
        const nombre = (body.nombre as string) || ''
        if (!codigo) throw new Error('codigo requerido')

        const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''
        const pushSecret = Deno.env.get('PUSH_SECRET') ?? ''
        if (!pushSecret) throw new Error('PUSH_SECRET no configurado')

        const title = '🔑 Código Especial del Mes'
        const bodyText = nombre
          ? `Este mes desbloqueamos un código exclusivo: ${codigo} - ${nombre}`
          : `Este mes desbloqueamos un código exclusivo: ${codigo}`

        const resp = await fetch(`${SUPABASE_URL}/functions/v1/send-push`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${anonKey}`,
            'x-push-secret': pushSecret,
          },
          body: JSON.stringify({ topic: 'all', title, body: bodyText, data: { type: 'monthly_special_code', codigo } }),
        })
        if (!resp.ok) {
          const text = await resp.text().catch(() => '')
          throw new Error(`send-push falló: ${resp.status} ${text.slice(0, 200)}`)
        }

        const monthKey = new Date().toISOString().slice(0, 7)
        await admin.from('app_config').upsert(
          { key: 'monthly_special_code', value: JSON.stringify({ codigo, nombre, month: monthKey }) },
          { onConflict: 'key' },
        )

        return new Response(JSON.stringify({ success: true }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
      }

      // ===== MURAL: CRUD de mural_messages. La tabla solo tiene política de =====
      // ===== SELECT para is_active=true (RLS), así que ni siquiera un admin =====
      // ===== autenticado puede insertar/editar/ver inactivos directo desde el =====
      // ===== cliente — todo pasa por aquí, ya verificado como admin arriba. =====
      case 'mural_list_all': {
        const { data, error } = await admin
          .from('mural_messages')
          .select()
          .order('created_at', { ascending: false })
        if (error) throw error
        return new Response(JSON.stringify({ data }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
      }

      // Sube la imagen server-side (service role) para no depender de
      // políticas RLS de storage.objects, que hoy no tienen ninguna regla
      // para INSERT desde el cliente.
      case 'mural_upload_image': {
        const { fileName, base64Data, contentType } = body
        if (!fileName || !base64Data) throw new Error('fileName y base64Data requeridos')

        const binary = Uint8Array.from(atob(base64Data), (c) => c.charCodeAt(0))
        const filePath = `mural/${Date.now()}_${fileName}`

        const { error: uploadError } = await admin.storage.from('images').upload(filePath, binary, {
          contentType: contentType || 'image/jpeg',
          upsert: true,
        })
        if (uploadError) throw uploadError

        const { data: urlData } = admin.storage.from('images').getPublicUrl(filePath)
        return new Response(JSON.stringify({ url: urlData.publicUrl }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
      }

      case 'mural_create': {
        const { title, message, imageUrl, actionUrl, type, expiresAt } = body
        if (!title || !message) throw new Error('title y message requeridos')

        const { data, error } = await admin.from('mural_messages').insert({
          title,
          message,
          image_url: imageUrl || null,
          action_url: actionUrl || null,
          type: type || 'info',
          is_active: true,
          expires_at: expiresAt || null,
        }).select().single()
        if (error) throw error

        return new Response(JSON.stringify({ data }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
      }

      case 'mural_update': {
        const { id, title, message, imageUrl, actionUrl, type, isActive, expiresAt } = body
        if (!id) throw new Error('id requerido')

        const updateData: Record<string, unknown> = {}
        if (title !== undefined) updateData.title = title
        if (message !== undefined) updateData.message = message
        if (imageUrl !== undefined) updateData.image_url = imageUrl || null
        if (actionUrl !== undefined) updateData.action_url = actionUrl || null
        if (type !== undefined) updateData.type = type
        if (isActive !== undefined) updateData.is_active = isActive
        if (expiresAt !== undefined) updateData.expires_at = expiresAt || null

        const { data, error } = await admin
          .from('mural_messages')
          .update(updateData)
          .eq('id', id)
          .select()
          .single()
        if (error) throw error

        return new Response(JSON.stringify({ data }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
      }

      case 'mural_delete': {
        const { id } = body
        if (!id) throw new Error('id requerido')

        const { error: readsError } = await admin.from('mural_message_reads').delete().eq('message_id', id)
        if (readsError) throw readsError
        const { error } = await admin.from('mural_messages').delete().eq('id', id)
        if (error) throw error

        return new Response(JSON.stringify({ success: true }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
      }

      default:
        return new Response(JSON.stringify({ error: `Acción desconocida: ${action}` }), { status: 400, headers: corsHeaders })
    }
  } catch (err) {
    console.error('❌ admin-users error:', err)
    return new Response(JSON.stringify({ error: err instanceof Error ? err.message : String(err) }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
})
