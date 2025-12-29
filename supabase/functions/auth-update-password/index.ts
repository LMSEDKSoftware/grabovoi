// deno-lint-ignore-file no-explicit-any
import 'jsr:@supabase/functions-js/edge-runtime.d.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

/**
 * SISTEMA ROBUSTO DE ACTUALIZACIÓN DE CONTRASEÑA
 * Usa el flujo OFICIAL de Supabase (recovery token + updateUser)
 * 
 * Este endpoint recibe un token de recuperación y la nueva contraseña
 * Verifica el token y actualiza la contraseña usando el método estándar
 */

Deno.serve(async (req) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Content-Type': 'application/json',
  }

  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: corsHeaders,
    })
  }

  try {
    const { recovery_token, new_password } = await req.json().catch(() => ({}))
    
    if (!recovery_token || typeof recovery_token !== 'string') {
      return new Response(JSON.stringify({ error: 'recovery_token requerido' }), {
        status: 400,
        headers: corsHeaders,
      })
    }

    if (!new_password || typeof new_password !== 'string' || new_password.length < 6) {
      return new Response(JSON.stringify({ error: 'new_password requerido (mínimo 6 caracteres)' }), {
        status: 400,
        headers: corsHeaders,
      })
    }

    const SUPABASE_URL = Deno.env.get('SB_URL')!
    const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!
    
    if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
      return new Response(JSON.stringify({ error: 'Configuración del servidor incompleta' }), {
        status: 500,
        headers: corsHeaders,
      })
    }

    // Crear cliente con anon key para usar el método estándar
    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)

    console.log('🔐 Procesando actualización de contraseña con token de recuperación...')
    console.log(`   Token: ${recovery_token.substring(0, 20)}...`)
    console.log(`   Nueva contraseña: ${new_password.length} caracteres`)

    // PASO 1: Verificar el token de recuperación usando exchangeCodeForSession
    // Este es el método OFICIAL de Supabase
    console.log('🔑 Verificando token de recuperación...')
    
    try {
      const sessionResponse = await supabase.auth.exchangeCodeForSession(recovery_token)
      
      if (!sessionResponse.session) {
        console.error('❌ Token de recuperación inválido o expirado')
        return new Response(JSON.stringify({ 
          error: 'Token de recuperación inválido o expirado'
        }), {
          status: 400,
          headers: corsHeaders,
        })
      }

      console.log('✅ Token de recuperación verificado correctamente')
      console.log(`   Usuario: ${sessionResponse.session.user.email}`)

      // PASO 2: Actualizar contraseña usando el método estándar updateUser()
      // Este es el método OFICIAL que SIEMPRE funciona
      console.log('🔑 Actualizando contraseña usando método estándar updateUser()...')
      
      const updateResponse = await supabase.auth.updateUser({
        password: new_password,
      })

      if (!updateResponse.user) {
        console.error('❌ No se pudo actualizar la contraseña')
        return new Response(JSON.stringify({ 
          error: 'No se pudo actualizar la contraseña'
        }), {
          status: 500,
          headers: corsHeaders,
        })
      }

      console.log('✅ Contraseña actualizada exitosamente')
      console.log(`   Usuario: ${updateResponse.user.email}`)

      // PASO 3: Verificar que la contraseña funciona haciendo re-login
      console.log('🔐 Verificando que la nueva contraseña funciona...')
      
      // Cerrar sesión actual
      await supabase.auth.signOut()
      await new Promise(resolve => setTimeout(resolve, 500))

      // Hacer login con la nueva contraseña para verificar
      const loginResponse = await supabase.auth.signInWithPassword({
        email: updateResponse.user.email!,
        password: new_password,
      })

      if (!loginResponse.user || !loginResponse.session) {
        console.error('❌ La nueva contraseña no funciona')
        return new Response(JSON.stringify({ 
          error: 'La contraseña se actualizó pero no funciona para login'
        }), {
          status: 500,
          headers: corsHeaders,
        })
      }

      console.log('✅ Re-login exitoso - La contraseña funciona correctamente')

      // Cerrar sesión para que el usuario haga login normalmente después
      await supabase.auth.signOut()

      return new Response(JSON.stringify({ 
        ok: true,
        message: 'Contraseña actualizada exitosamente'
      }), {
        status: 200,
        headers: corsHeaders,
      })
    } catch (authError: any) {
      console.error('❌ Error en proceso de actualización:', authError)
      return new Response(JSON.stringify({ 
        error: 'Error actualizando contraseña',
        details: authError.message || String(authError)
      }), {
        status: 500,
        headers: corsHeaders,
      })
    }
  } catch (err: any) {
    console.error('❌ Error en auth-update-password:', err)
    return new Response(JSON.stringify({ 
      error: 'Error interno del servidor',
      details: err.message
    }), {
      status: 500,
      headers: corsHeaders,
    })
  }
})


