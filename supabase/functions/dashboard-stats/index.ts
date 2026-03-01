import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const ADMIN_EMAILS = ['ifernandez@lmsedk.com']

const corsHeaders = {
  'Access-Control-Allow-Origin': '*', // Cambiar a 'https://manigrab.app' en producción final
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // --- SEGURIDAD: Verificar JWT ---
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) throw new Error('No se proporcionó token de autorización')
    
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabase.auth.getUser(token)
    
    if (authError || !user) throw new Error('Sesión inválida')
    if (!ADMIN_EMAILS.includes(user.email ?? '')) {
      console.error(`Acceso denegado para: ${user.email}`)
      return new Response(JSON.stringify({ error: 'No autorizado' }), { status: 403, headers: corsHeaders })
    }
    // --------------------------------

    const urlParams = new URL(req.url).searchParams
    const section = urlParams.get('section')
    const offset = parseInt(urlParams.get('offset') || '0')
    const limit = parseInt(urlParams.get('limit') || '30')

    const now = new Date().toISOString()
    const todayStart = new Date()
    todayStart.setHours(0, 0, 0, 0)
    const thirtyDaysAgo = new Date()
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30)
    const sevenDaysAgo = new Date()
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7)

    const safeCount = async (table: string, opts?: { column?: string; eq?: [string, string]; gte?: [string, string] }) => {
      try {
        let q = supabase.from(table).select('*', { count: 'exact', head: true })
        if (opts?.eq) q = q.eq(opts.eq[0], opts.eq[1])
        if (opts?.gte) q = q.gte(opts.gte[0], opts.gte[1])
        const { count } = await q
        return count ?? 0
      } catch { return null }
    }

    // --- Función Helper para Engagement History ---
    const fetchEngagementHistory = async (off: number, lim: number) => {
      const { data: raw } = await supabase
        .from('user_actions')
        .select('user_id, action_type, action_data, recorded_at')
        .in('action_type', ['sesionPilotaje', 'codigoRepetido'])
        .order('recorded_at', { ascending: false })
        .range(off, off + lim - 1)

      const actionCodes = (raw || []).map((a: any) => a.action_data?.codeId || a.action_data?.codigo).filter(Boolean)
      const { data: nombres } = actionCodes.length
        ? await supabase.from('codigos_grabovoi').select('codigo, nombre').in('codigo', actionCodes)
        : { data: [] }
      const nMap: Record<string, string> = {}
      ;(nombres || []).forEach((c: any) => nMap[c.codigo] = c.nombre)

      const { data: uInfo } = await supabase.from('users').select('id, email, name')
      const uMap: Record<string, string> = {}
      ;(uInfo || []).forEach((u: any) => uMap[u.id] = u.name || u.email)

      return (raw || []).map((a: any) => {
        const cId = a.action_data?.codeId || a.action_data?.codigo || '—'
        return {
          user: uMap[a.user_id] || 'Anon',
          tipo: a.action_type,
          codigo: cId,
          nombre: nMap[cId] || '—',
          fecha: a.recorded_at
        }
      })
    }

    // --- Si solo se pide una sección específica ---
    if (section === 'engagement_history') {
      const history = await fetchEngagementHistory(offset, limit)
      return new Response(JSON.stringify({ engagement_history: history }), { headers: corsHeaders })
    }

    // --- Resumen ---
    const totalUsers = await safeCount('users')
    const { count: activeSubscriptions } = await supabase
      .from('user_subscriptions')
      .select('*', { count: 'exact', head: true })
      .eq('is_active', true)
      .gte('expires_at', now)
      .then(r => ({ count: r.count ?? 0 }))
    const { data: subsRows } = await supabase.from('user_subscriptions').select('product_id').eq('is_active', true).gte('expires_at', now)
    const monthlyCount = subsRows?.filter(s => (s.product_id || '').includes('monthly') || (s.product_id || '') === 'subscription_monthly').length ?? 0
    const yearlyCount = (subsRows?.length ?? 0) - monthlyCount

    // --- Engagement: user_actions (Resumen de DASHBOARD) ---
    const { count: sessionsToday } = await supabase
      .from('user_actions')
      .select('*', { count: 'exact', head: true })
      .eq('action_type', 'sesionPilotaje')
      .gte('recorded_at', todayStart.toISOString())
    const { count: repetitionsTotal } = await supabase
      .from('user_actions')
      .select('*', { count: 'exact', head: true })
      .eq('action_type', 'codigoRepetido')
    const { data: topPopularidad } = await supabase
      .from('codigo_popularidad')
      .select('codigo_id, contador')
      .order('contador', { ascending: false })
      .limit(100)
    const codigosIds = (topPopularidad || []).map(p => p.codigo_id)
    const { data: codigosNombres } = codigosIds.length
      ? await supabase.from('codigos_grabovoi').select('codigo, nombre, categoria').in('codigo', codigosIds)
      : { data: [] }
    const nombresMap: Record<string, { nombre: string; categoria: string }> = {}
    ;(codigosNombres || []).forEach((c: { codigo: string; nombre: string; categoria: string }) => { nombresMap[c.codigo] = { nombre: c.nombre, categoria: c.categoria } })
    
    // Top códigos (Dashboard)
    const topCodigos = (topPopularidad || []).slice(0, 5).map((p: any, i: number) => ({
      rank: i + 1,
      codigo: p.codigo_id,
      nombre: nombresMap[p.codigo_id]?.nombre || '',
      categoria: nombresMap[p.codigo_id]?.categoria || '',
      uso: p.contador,
    }))

    // Historial Reciente inicial (Dashboard)
    const recentActions = await fetchEngagementHistory(0, 30)

    // --- Estadísticas por Categoría ---
    const catStats: Record<string, number> = {}
    ;(codigosNombres || []).forEach((c: any) => {
      const topCount = (topPopularidad || []).find(p => p.codigo_id === c.codigo)?.contador || 0
      catStats[c.categoria] = (catStats[c.categoria] || 0) + topCount
    })
    const categoriesComparison = Object.entries(catStats)
      .sort((a, b) => b[1] - a[1])
      .map(([name, value]) => ({ name, value }))

    const { data: favoritosByCodigo } = await supabase.from('usuario_favoritos').select('codigo_id')
    const favCount: Record<string, number> = {}
    ;(favoritosByCodigo || []).forEach((f: { codigo_id: string }) => { favCount[f.codigo_id] = (favCount[f.codigo_id] || 0) + 1 })
    const topFavoritos = Object.entries(favCount)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
      .map(([codigo]) => ({ codigo, count: favCount[codigo] }))
    const favoritosConNombre = await Promise.all(
      topFavoritos.map(async (f: { codigo: string; count: number }) => {
        const { data: c } = await supabase.from('codigos_grabovoi').select('codigo, categoria').eq('codigo', f.codigo).maybeSingle()
        return { codigo: f.codigo, categoria: (c as { categoria?: string })?.categoria || '', favoritos: f.count }
      })
    )

    // --- Calidad / IA ---
    const { data: busquedas } = await supabase
      .from('busquedas_profundas')
      .select('codigo_buscado, codigo_encontrado, duracion_ms, costo_estimado, fecha_busqueda')
      .order('fecha_busqueda', { ascending: false })
      .limit(50)

    const searchesHistory = (busquedas || []).slice(0, 10).map(b => ({
      query: b.codigo_buscado,
      codigo_encontrado: b.codigo_encontrado,
      duracion_ms: b.duracion_ms,
      costo_estimado: b.costo_estimado,
      created_at: b.fecha_busqueda
    }))
    
    const totalBusquedas = busquedas?.length ?? 0
    const encontradas = busquedas?.filter(b => b.codigo_encontrado).length ?? 0
    const tasaExitoIA = totalBusquedas > 0 ? Math.round((encontradas / totalBusquedas) * 1000) / 10 : null
    const latenciaMedia = busquedas?.length
      ? Math.round((busquedas.reduce((a: any, b: any) => a + (b.duracion_ms || 0), 0) / busquedas.length))
      : null
    const costoTokens = busquedas?.reduce((a: any, b: any) => a + (Number(b.costo_estimado) || 0), 0) ?? 0
    
    // --- Gestión de Códigos y Auditoría ---
    const { data: reportes } = await supabase
      .from('reportes_codigos')
      .select('codigo_id, tipo_reporte, estatus, created_at')
      .order('created_at', { ascending: false })
      .limit(30)

    const { data: sugerencias } = await supabase
      .from('sugerencias_codigos')
      .select('codigo_existente, tema_sugerido, descripcion_sugerida, estado, fecha_sugerencia')
      .order('fecha_sugerencia', { ascending: false })
      .limit(30)

    // Combinar reportes y sugerencias en una sola lista para el panel
    const reportesLista = [
      ...(reportes || []).map(r => ({
        codigo_id: r.codigo_id,
        tipo_reporte: `Reporte: ${r.tipo_reporte}`,
        descripcion: 'Reportado por usuario',
        estatus: r.estatus,
        fecha: r.created_at
      })),
      ...(sugerencias || []).map(s => ({
        codigo_id: s.codigo_existente,
        tipo_reporte: `Sugerencia IA: ${s.tema_sugerido}`,
        descripcion: s.descripcion_sugerida || 'Sin descripción',
        estatus: s.estado,
        fecha: s.fecha_sugerencia
      }))
    ].sort((a, b) => new Date(b.fecha).getTime() - new Date(a.fecha).getTime()).slice(0, 20)

    // --- Detección de Conflictos y Duplicados ---
    const { data: codesRaw } = await supabase.from('codigos_grabovoi').select('codigo, nombre, categoria')
    const { data: titulosRel } = await supabase.from('codigos_titulos_relacionados').select('codigo_existente, titulo')

    // 1. Diferentes códigos con el mismo nombre
    const nameToCodes: Record<string, string[]> = {}
    ;(codesRaw || []).forEach((c: any) => {
      if (!nameToCodes[c.nombre]) nameToCodes[c.nombre] = []
      nameToCodes[c.nombre].push(c.codigo)
    })

    const duplicates: any[] = []
    Object.entries(nameToCodes).forEach(([nombre, codigos]) => {
      if (codigos.length > 1) {
        duplicates.push({ 
          codigo: nombre, // Usamos el nombre como identificador del conflicto
          nombres: codigos.map(id => `Código: ${id}`),
          count: codigos.length,
          tipo: 'Nombre duplicado'
        })
      }
    })

    // 2. Códigos con múltiples títulos relacionados
    const codeToTitulos: Record<string, string[]> = {}
    ;(titulosRel || []).forEach((t: any) => {
      if (!codeToTitulos[t.codigo_existente]) codeToTitulos[t.codigo_existente] = []
      codeToTitulos[t.codigo_existente].push(t.titulo)
    })

    Object.entries(codeToTitulos).forEach(([codigo, titulos]) => {
      if (titulos.length > 0) {
        duplicates.push({
          codigo: codigo,
          nombres: titulos.map(t => `Alt: ${t}`),
          count: titulos.length + 1,
          tipo: 'Múltiples títulos'
        })
      }
    })

    // --- Desafíos ---
    const { count: desafiosIniciados } = await supabase.from('user_challenges').select('*', { count: 'exact', head: true })
    const { count: desafiosCompletados } = await supabase
      .from('user_challenges')
      .select('*', { count: 'exact', head: true })
      .eq('status', 'completado')
    const tasaFinalizacion = (desafiosIniciados ?? 0) > 0
      ? Math.round(((desafiosCompletados ?? 0) / (desafiosIniciados ?? 1)) * 1000) / 10
      : null

    // --- Recompensas ---
    const { data: rewardsRows } = await supabase.from('user_rewards').select('cristales_energia, luz_cuantica')
    let totalCristales = 0
    let usuariosLuz100 = 0
    let usuariosCon100Cristales = 0
    ;(rewardsRows || []).forEach((r: any) => {
      totalCristales += r.cristales_energia ?? 0
      if ((r.luz_cuantica ?? 0) >= 100) usuariosLuz100++
      if ((r.cristales_energia ?? 0) >= 100) usuariosCon100Cristales++
    })

    // --- Diario ---
    const { count: entradasDiario30 } = await supabase
      .from('diario_entradas')
      .select('*', { count: 'exact', head: true })
      .gte('created_at', thirtyDaysAgo.toISOString())
    const { data: diarioUserIds } = await supabase
      .from('diario_entradas')
      .select('user_id')
      .gte('created_at', thirtyDaysAgo.toISOString())
    const usuariosConEntrada = new Set((diarioUserIds || []).map((d: any) => d.user_id)).size
    const { count: assessmentsCount } = await supabase.from('user_assessments').select('*', { count: 'exact', head: true })
    const assessmentPct = (totalUsers ?? 0) > 0
      ? Math.round(((assessmentsCount ?? 0) / (totalUsers ?? 1)) * 100)
      : null

    // --- Resumen Detallado ---
    const { data: usersDetailsRaw } = await supabase.from('users').select('id, email, name, created_at').order('created_at', { ascending: false }).limit(100)
    const { data: subsDetailsRaw } = await supabase.from('user_subscriptions').select('user_id, product_id, expires_at').eq('is_active', true).gte('expires_at', now).order('expires_at', { ascending: true })
    
    // Mapear correos para las suscripciones
    const userEmailsMap: Record<string, string> = {}
    ;(usersDetailsRaw || []).forEach((u: any) => { userEmailsMap[u.id] = u.email })

    const usersDetails = (usersDetailsRaw || []).map((u: any) => ({
      id: u.id,
      email: u.email,
      display_name: u.name,
      created_at: u.created_at
    }))
    
    const subsDetails = (subsDetailsRaw || []).map((s: any) => ({
      email: userEmailsMap[s.user_id] || 'Oculto/Anon',
      plan: s.product_id,
      expires_at: s.expires_at
    }))

    const payload = {
      resumen: {
        totalUsers: totalUsers ?? 0,
        activeSubscriptions: activeSubscriptions ?? 0,
        monthlyCount,
        yearlyCount,
        usersDetails: usersDetails,
        subsDetails: subsDetails,
      },
      engagement: {
        sessionsToday: sessionsToday ?? 0,
        repetitionsTotal: repetitionsTotal ?? 0,
        topCodigos: topCodigos || [],
        topFavoritos: favoritosConNombre || [],
        recentActions,
        categoriesComparison,
      },
      calidad: {
        tasaExitoIA,
        latenciaMedia,
        costoTokens: Math.round(costoTokens * 100) / 100,
        searchesHistory,
        reportesLista: reportesLista || [],
        duplicates,
      },
      desafios: {
        iniciados: desafiosIniciados ?? 0,
        completados: desafiosCompletados ?? 0,
        tasaFinalizacion: tasaFinalizacion ?? 0,
      },
      recompensas: {
        totalCristales,
        usuariosLuz100,
        usuariosCon100Cristales,
      },
      diario: {
        entradas30d: entradasDiario30 ?? 0,
        usuariosConEntrada,
        assessmentPct: assessmentPct ?? 0,
        totalConAssessment: assessmentsCount ?? 0,
      },
    }

    return new Response(JSON.stringify(payload), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error(err)
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
