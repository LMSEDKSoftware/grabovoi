import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

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

    // --- Engagement: user_actions ---
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
      .limit(5)
    const codigosIds = (topPopularidad || []).map(p => p.codigo_id)
    const { data: codigosNombres } = codigosIds.length
      ? await supabase.from('codigos_grabovoi').select('codigo, nombre').in('codigo', codigosIds)
      : { data: [] }
    const nombresMap: Record<string, string> = {}
    ;(codigosNombres || []).forEach((c: { codigo: string; nombre: string }) => { nombresMap[c.codigo] = c.nombre })
    const topCodigos = (topPopularidad || []).map((p: { codigo_id: string; contador: number }, i: number) => ({
      rank: i + 1,
      codigo: p.codigo_id,
      nombre: nombresMap[p.codigo_id] || '',
      uso: p.contador,
    }))
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
    const { data: busquedas } = await supabase.from('busquedas_profundas').select('codigo_encontrado, duracion_ms, costo_estimado')
    const totalBusquedas = busquedas?.length ?? 0
    const encontradas = busquedas?.filter(b => b.codigo_encontrado).length ?? 0
    const tasaExitoIA = totalBusquedas > 0 ? Math.round((encontradas / totalBusquedas) * 1000) / 10 : null
    const latenciaMedia = busquedas?.length
      ? Math.round((busquedas.reduce((a, b) => a + (b.duracion_ms || 0), 0) / busquedas.length))
      : null
    const costoTokens = busquedas?.reduce((a, b) => a + (Number(b.costo_estimado) || 0), 0) ?? 0
    const { count: sugerenciasPendientes } = await supabase
      .from('sugerencias_codigos')
      .select('*', { count: 'exact', head: true })
      .eq('estado', 'pendiente')
    const { count: reportesPendientes } = await supabase
      .from('reportes_codigos')
      .select('*', { count: 'exact', head: true })
      .eq('estatus', 'pendiente')
    const { data: sugerenciasLista } = await supabase
      .from('sugerencias_codigos')
      .select('codigo_existente, tema_sugerido')
      .eq('estado', 'pendiente')
      .limit(5)
    const { data: reportesLista } = await supabase
      .from('reportes_codigos')
      .select('codigo_id, tipo_reporte, estatus')
      .eq('estatus', 'pendiente')
      .limit(5)

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
    ;(rewardsRows || []).forEach((r: { cristales_energia?: number; luz_cuantica?: number }) => {
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
    const usuariosConEntrada = new Set((diarioUserIds || []).map((d: { user_id: string }) => d.user_id)).size
    const { count: assessmentsCount } = await supabase.from('user_assessments').select('*', { count: 'exact', head: true })
    const assessmentPct = (totalUsers ?? 0) > 0
      ? Math.round(((assessmentsCount ?? 0) / (totalUsers ?? 1)) * 100)
      : null

    const payload = {
      resumen: {
        totalUsers: totalUsers ?? 0,
        activeSubscriptions: activeSubscriptions ?? 0,
        monthlyCount,
        yearlyCount,
      },
      engagement: {
        sessionsToday: sessionsToday ?? 0,
        repetitionsTotal: repetitionsTotal ?? 0,
        topCodigos: topCodigos || [],
        topFavoritos: favoritosConNombre || [],
      },
      calidad: {
        tasaExitoIA,
        latenciaMedia,
        costoTokens: Math.round(costoTokens * 100) / 100,
        sugerenciasPendientes: sugerenciasPendientes ?? 0,
        reportesPendientes: reportesPendientes ?? 0,
        sugerenciasLista: sugerenciasLista || [],
        reportesLista: reportesLista || [],
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
