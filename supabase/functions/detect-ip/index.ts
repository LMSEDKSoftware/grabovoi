// Función temporal para detectar la IP desde la cual se ejecuta Supabase Edge Functions
// Esta función debe ser eliminada después de obtener la IP

import 'jsr:@supabase/functions-js/edge-runtime.d.ts'

Deno.serve(async (req) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Content-Type': 'application/json',
  }

  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders })
  }

  // Obtener información de la solicitud
  const url = new URL(req.url)
  const clientIP = req.headers.get('x-forwarded-for') || 
                   req.headers.get('x-real-ip') || 
                   'unknown'
  
  // Intentar obtener la IP pública haciendo una solicitud a un servicio externo
  let publicIP = 'unknown'
  try {
    const ipResponse = await fetch('https://api.ipify.org?format=json')
    const ipData = await ipResponse.json()
    publicIP = ipData.ip
  } catch (e) {
    console.error('Error obteniendo IP pública:', e)
  }

  // Información adicional
  const info = {
    timestamp: new Date().toISOString(),
    clientIP: clientIP,
    publicIP: publicIP,
    headers: Object.fromEntries(req.headers.entries()),
    url: req.url,
    method: req.method,
    region: Deno.env.get('SUPABASE_REGION') || 'unknown',
  }

  console.log('🌐 Información de IP detectada:', JSON.stringify(info, null, 2))

  return new Response(JSON.stringify({
    success: true,
    message: 'IP detectada. Revisa los logs de Supabase para ver la IP completa.',
    info: info,
    instructions: [
      '1. Revisa los logs de esta función en Supabase Dashboard',
      '2. Busca el mensaje "🌐 Información de IP detectada"',
      '3. Copia la IP pública (publicIP)',
      '4. Agrega esa IP a la whitelist de SendGrid',
      '5. Elimina esta función después de obtener la IP'
    ]
  }), { 
    status: 200, 
    headers: corsHeaders 
  })
})



