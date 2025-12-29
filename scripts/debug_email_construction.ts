/**
 * Script de debug para mostrar EXACTAMENTE cómo se construye el correo de recuperación
 * 
 * Este script muestra:
 * 1. El payload que se envía desde send-otp al servidor PHP
 * 2. El payload que el servidor PHP envía a SendGrid
 * 3. El template_data completo con todos los valores
 */

// ============================================
// PASO 1: SIMULACIÓN DEL PAYLOAD DESDE send-otp
// ============================================

console.log('='.repeat(80))
console.log('PASO 1: PAYLOAD QUE SE ENVÍA DESDE send-otp AL SERVIDOR PHP')
console.log('='.repeat(80))

// Simular valores reales (estos son ejemplos)
const finalRecoveryUrl = 'https://manigrab.app/auth/callback?token=abc123XYZ&type=recovery'
const userName = 'Usuario de Prueba'
const requestEmail = 'test@example.com'

const serverPayloadFromSendOtp = {
  to: requestEmail,
  template_id: 'd-971362da419640f7be3c3cb7fae9881d',
  template_data: {
    name: userName || 'Usuario',
    app_name: 'ManiGrab',
    recovery_link: finalRecoveryUrl.trim() // URL final validada y trimmeada
  },
  subject: 'Recuperación de Contraseña - ManiGrab'
}

console.log('\n📦 PAYLOAD COMPLETO QUE SE ENVÍA AL SERVIDOR PHP:')
console.log(JSON.stringify(serverPayloadFromSendOtp, null, 2))

console.log('\n📋 VALIDACIONES:')
console.log('  ✅ template_id:', serverPayloadFromSendOtp.template_id || '❌ FALTA')
console.log('  ✅ template_data.name:', serverPayloadFromSendOtp.template_data?.name || '❌ FALTA')
console.log('  ✅ template_data.app_name:', serverPayloadFromSendOtp.template_data?.app_name || '❌ FALTA')
console.log('  ✅ template_data.recovery_link:', serverPayloadFromSendOtp.template_data?.recovery_link || '❌ FALTA')
console.log('  ✅ recovery_link length:', serverPayloadFromSendOtp.template_data?.recovery_link?.length || 0)
console.log('  ✅ recovery_link valor:', serverPayloadFromSendOtp.template_data?.recovery_link || 'VACÍO')

// ============================================
// PASO 2: SIMULACIÓN DEL PAYLOAD QUE ENVÍA PHP A SENDGRID
// ============================================

console.log('\n' + '='.repeat(80))
console.log('PASO 2: PAYLOAD QUE EL SERVIDOR PHP ENVÍA A SENDGRID')
console.log('='.repeat(80))

// Simular cómo PHP procesa el payload recibido
const templateData = serverPayloadFromSendOtp.template_data ?? []
const templateId = serverPayloadFromSendOtp.template_id ?? 'd-971362da419640f7be3c3cb7fae9881d'
const subject = serverPayloadFromSendOtp.subject ?? 'Recuperación de Contraseña - ManiGrab'
const fromEmail = 'hola@em6490.manigrab.app'
const fromName = 'ManiGrab'

// Este es el JSON EXACTO que PHP envía a SendGrid
const emailDataToSendGrid = {
  personalizations: [
    {
      to: [
        { email: serverPayloadFromSendOtp.to }
      ],
      dynamic_template_data: templateData,
      subject: subject
    }
  ],
  from: {
    email: fromEmail,
    name: fromName
  },
  subject: subject,
  template_id: templateId
}

console.log('\n📦 JSON COMPLETO QUE SE ENVÍA A SENDGRID API:')
console.log(JSON.stringify(emailDataToSendGrid, null, 2))

console.log('\n📋 VALIDACIONES EN EL PAYLOAD A SENDGRID:')
console.log('  ✅ template_id:', emailDataToSendGrid.template_id || '❌ FALTA')
console.log('  ✅ from.email:', emailDataToSendGrid.from?.email || '❌ FALTA')
console.log('  ✅ from.name:', emailDataToSendGrid.from?.name || '❌ FALTA')
console.log('  ✅ personalizations[0].to[0].email:', emailDataToSendGrid.personalizations?.[0]?.to?.[0]?.email || '❌ FALTA')
console.log('  ✅ personalizations[0].dynamic_template_data:', emailDataToSendGrid.personalizations?.[0]?.dynamic_template_data ? '✅ PRESENTE' : '❌ FALTA')

if (emailDataToSendGrid.personalizations?.[0]?.dynamic_template_data) {
  const dtData = emailDataToSendGrid.personalizations[0].dynamic_template_data
  console.log('\n📋 CONTENIDO DE dynamic_template_data:')
  console.log('  ✅ name:', dtData.name || '❌ FALTA')
  console.log('  ✅ app_name:', dtData.app_name || '❌ FALTA')
  console.log('  ✅ recovery_link:', dtData.recovery_link || '❌ FALTA')
  console.log('  ✅ recovery_link length:', dtData.recovery_link?.length || 0)
  console.log('  ✅ recovery_link valor completo:', dtData.recovery_link || 'VACÍO')
  
  // Mostrar objeto completo
  console.log('\n📋 OBJETO dynamic_template_data COMPLETO:')
  console.log(JSON.stringify(dtData, null, 2))
}

// ============================================
// PASO 3: SIMULACIÓN DE CÓMO SENDGRID INTERPRETA EL TEMPLATE
// ============================================

console.log('\n' + '='.repeat(80))
console.log('PASO 3: CÓMO SENDGRID DEBERÍA INTERPRETAR EL TEMPLATE')
console.log('='.repeat(80))

console.log('\n📧 TEMPLATE ID:', templateId)
console.log('\n📋 VARIABLES QUE EL TEMPLATE ESPERA:')
console.log('  - {{name}} -> Se reemplaza por:', templateData.name || 'VACÍO')
console.log('  - {{app_name}} -> Se reemplaza por:', templateData.app_name || 'VACÍO')
console.log('  - {{recovery_link}} -> Se reemplaza por:', templateData.recovery_link || 'VACÍO')

console.log('\n📝 EJEMPLO DE CÓMO QUEDARÍA EL HTML DEL TEMPLATE:')
console.log(`
  <p>Hola ${templateData.name || '{{name}}'},</p>
  <p>Hemos recibido una solicitud para restablecer tu contraseña.</p>
  <a href="${templateData.recovery_link || '{{recovery_link}}'}">Restablecer Contraseña</a>
  <p>O copia y pega este enlace: ${templateData.recovery_link || '{{recovery_link}}'}</p>
  <p>© ${templateData.app_name || '{{app_name}}'}</p>
`)

// ============================================
// PASO 4: ANÁLISIS DE POSIBLES PROBLEMAS
// ============================================

console.log('\n' + '='.repeat(80))
console.log('PASO 4: ANÁLISIS DE POSIBLES PROBLEMAS')
console.log('='.repeat(80))

const problems: string[] = []

if (!templateData.recovery_link || templateData.recovery_link.trim() === '') {
  problems.push('❌ PROBLEMA CRÍTICO: recovery_link está vacío en template_data')
}

if (!templateData.name || templateData.name.trim() === '') {
  problems.push('⚠️ ADVERTENCIA: name está vacío (usará "Usuario" por defecto)')
}

if (!templateData.app_name || templateData.app_name.trim() === '') {
  problems.push('⚠️ ADVERTENCIA: app_name está vacío (usará "ManiGrab" por defecto)')
}

if (!templateId || templateId.trim() === '') {
  problems.push('❌ PROBLEMA CRÍTICO: template_id está vacío')
}

if (problems.length === 0) {
  console.log('\n✅ NO SE DETECTARON PROBLEMAS EN LA CONSTRUCCIÓN DEL CORREO')
  console.log('   Si el correo llega sin links, el problema puede estar en:')
  console.log('   1. El template de SendGrid no tiene configurada la variable {{recovery_link}}')
  console.log('   2. El template de SendGrid tiene un error de sintaxis')
  console.log('   3. SendGrid está rechazando la variable por algún motivo')
} else {
  console.log('\n❌ PROBLEMAS DETECTADOS:')
  problems.forEach((problem, index) => {
    console.log(`   ${index + 1}. ${problem}`)
  })
}

// ============================================
// PASO 5: EJEMPLO DE CÓMO VERIFICAR EN SENDGRID
// ============================================

console.log('\n' + '='.repeat(80))
console.log('PASO 5: CÓMO VERIFICAR EL TEMPLATE EN SENDGRID')
console.log('='.repeat(80))

console.log(`
📋 Para verificar que el template está bien configurado en SendGrid:

1. Ve a: https://app.sendgrid.com/email_templates
2. Busca el template con ID: ${templateId}
3. Verifica que tenga estas variables configuradas:
   - {{name}}
   - {{app_name}}
   - {{recovery_link}} ⚠️ ESTA ES LA MÁS IMPORTANTE

4. Busca en el HTML del template por:
   - <a href="{{recovery_link}}"> (para el botón)
   - {{recovery_link}} (para el link de texto)

5. Si no encuentras {{recovery_link}} en el template, AHÍ ESTÁ EL PROBLEMA.
   Necesitas agregar la variable al template.

6. También verifica en la versión de texto plano del template que tenga:
   {{recovery_link}}
`)

console.log('\n' + '='.repeat(80))
console.log('FIN DEL REPORTE DE DEBUG')
console.log('='.repeat(80))

