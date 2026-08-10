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

        await admin.from('user_subscriptions')
          .update({ is_active: false })
          .eq('user_id', userId)
          .eq('is_active', true)

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

      default:
        return new Response(JSON.stringify({ error: `Acción desconocida: ${action}` }), { status: 400, headers: corsHeaders })
    }
  } catch (err) {
    console.error('❌ admin-users error:', err)
    return new Response(JSON.stringify({ error: err instanceof Error ? err.message : String(err) }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
})
