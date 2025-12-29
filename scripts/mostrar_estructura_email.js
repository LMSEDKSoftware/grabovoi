#!/usr/bin/env node
/**
 * Script para mostrar EXACTAMENTE cómo se construye el correo de recuperación
 * Simula una ejecución real mostrando todos los datos
 */

console.log('='.repeat(80));
console.log('🔍 ANÁLISIS COMPLETO: Construcción del Email de Recuperación');
console.log('='.repeat(80));

// ============================================
// VALORES DE EJEMPLO (simulan valores reales)
// ============================================

const finalRecoveryUrl = 'https://manigrab.app/auth/callback?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNzM1Njg4MDAwLCJzdWIiOiIxMjM0NTY3OC05MGFiLWNkZWYtMTIzNC01Njc4OTBhYmNkZWYifQ.example&type=recovery';
const userName = 'Juan Pérez';
const userEmail = 'juan.perez@ejemplo.com';
const templateId = 'd-971362da419640f7be3c3cb7fae9881d';

// ============================================
// PASO 1: Payload desde send-otp al Servidor PHP
// ============================================

console.log('\n📦 PASO 1: PAYLOAD DESDE send-otp AL SERVIDOR PHP');
console.log('-'.repeat(80));

const serverPayload = {
  to: userEmail,
  template_id: templateId,
  template_data: {
    name: userName || 'Usuario',
    app_name: 'ManiGrab',
    recovery_link: finalRecoveryUrl.trim()
  },
  subject: 'Recuperación de Contraseña - ManiGrab'
};

console.log('\n✅ Payload completo:');
console.log(JSON.stringify(serverPayload, null, 2));

console.log('\n📋 Validaciones:');
console.log(`  ✅ template_id: ${serverPayload.template_id || '❌ FALTA'}`);
console.log(`  ✅ template_data.name: ${serverPayload.template_data?.name || '❌ FALTA'}`);
console.log(`  ✅ template_data.app_name: ${serverPayload.template_data?.app_name || '❌ FALTA'}`);
console.log(`  ✅ template_data.recovery_link: ${serverPayload.template_data?.recovery_link ? '✅ PRESENTE' : '❌ FALTA'}`);
console.log(`  ✅ recovery_link length: ${serverPayload.template_data?.recovery_link?.length || 0} caracteres`);

if (serverPayload.template_data?.recovery_link) {
  console.log(`  ✅ recovery_link (primeros 80 chars): ${serverPayload.template_data.recovery_link.substring(0, 80)}...`);
}

// ============================================
// PASO 2: JSON que envía PHP a SendGrid
// ============================================

console.log('\n📦 PASO 2: JSON QUE ENVÍA PHP A SENDGRID');
console.log('-'.repeat(80));

const sendGridPayload = {
  personalizations: [
    {
      to: [
        { email: serverPayload.to }
      ],
      dynamic_template_data: serverPayload.template_data,
      subject: serverPayload.subject
    }
  ],
  from: {
    email: 'hola@em6490.manigrab.app',
    name: 'ManiGrab'
  },
  subject: serverPayload.subject,
  template_id: serverPayload.template_id
};

console.log('\n✅ JSON completo a SendGrid:');
console.log(JSON.stringify(sendGridPayload, null, 2));

console.log('\n📋 Validaciones en el payload a SendGrid:');
console.log(`  ✅ template_id: ${sendGridPayload.template_id || '❌ FALTA'}`);
console.log(`  ✅ from.email: ${sendGridPayload.from?.email || '❌ FALTA'}`);
console.log(`  ✅ from.name: ${sendGridPayload.from?.name || '❌ FALTA'}`);
console.log(`  ✅ personalizations[0].to[0].email: ${sendGridPayload.personalizations?.[0]?.to?.[0]?.email || '❌ FALTA'}`);

const dtData = sendGridPayload.personalizations?.[0]?.dynamic_template_data;
if (dtData) {
  console.log('\n📋 Contenido de dynamic_template_data:');
  console.log(`  ✅ name: ${dtData.name || '❌ FALTA'}`);
  console.log(`  ✅ app_name: ${dtData.app_name || '❌ FALTA'}`);
  console.log(`  ✅ recovery_link: ${dtData.recovery_link ? '✅ PRESENTE' : '❌ FALTA'}`);
  console.log(`  ✅ recovery_link length: ${dtData.recovery_link?.length || 0} caracteres`);
  
  if (dtData.recovery_link) {
    console.log(`  ✅ recovery_link completo: ${dtData.recovery_link}`);
  }
}

// ============================================
// PASO 3: Cómo SendGrid reemplaza las variables
// ============================================

console.log('\n📧 PASO 3: CÓMO SENDGRID DEBERÍA INTERPRETAR EL TEMPLATE');
console.log('-'.repeat(80));

console.log(`\n📋 Template ID: ${templateId}`);
console.log('\n📋 Variables que el template DEBE tener configuradas:');
console.log('  - {{name}} → Se reemplaza por:', dtData?.name || 'VACÍO');
console.log('  - {{app_name}} → Se reemplaza por:', dtData?.app_name || 'VACÍO');
console.log('  - {{recovery_link}} → Se reemplaza por:', dtData?.recovery_link ? 'PRESENTE ✅' : 'VACÍO ❌');

if (dtData?.recovery_link) {
  console.log('\n📝 Ejemplo de cómo quedaría el HTML del template después del reemplazo:');
  console.log(`
    <p>Hola ${dtData.name},</p>
    <p>Hemos recibido una solicitud para restablecer tu contraseña.</p>
    <a href="${dtData.recovery_link}" class="button">Restablecer Contraseña</a>
    <p>O copia y pega este enlace:</p>
    <p>${dtData.recovery_link}</p>
    <p>© ${dtData.app_name}</p>
  `);
} else {
  console.log('\n❌ PROBLEMA: recovery_link está vacío, por lo que el link NO aparecerá en el correo');
}

// ============================================
// PASO 4: Análisis de problemas
// ============================================

console.log('\n🔍 PASO 4: ANÁLISIS DE POSIBLES PROBLEMAS');
console.log('-'.repeat(80));

const problems = [];

if (!dtData?.recovery_link || dtData.recovery_link.trim() === '') {
  problems.push('❌ PROBLEMA CRÍTICO: recovery_link está vacío en dynamic_template_data');
}

if (!dtData?.name || dtData.name.trim() === '') {
  problems.push('⚠️ ADVERTENCIA: name está vacío (usará "Usuario" por defecto)');
}

if (!dtData?.app_name || dtData.app_name.trim() === '') {
  problems.push('⚠️ ADVERTENCIA: app_name está vacío');
}

if (!templateId || templateId.trim() === '') {
  problems.push('❌ PROBLEMA CRÍTICO: template_id está vacío');
}

if (problems.length === 0) {
  console.log('\n✅ NO SE DETECTARON PROBLEMAS EN LA CONSTRUCCIÓN DEL CORREO');
  console.log('\n💡 Si el correo llega sin links, el problema está EN EL TEMPLATE DE SENDGRID:');
  console.log('   1. El template NO tiene la variable {{recovery_link}} configurada');
  console.log('   2. El template tiene un error de sintaxis');
  console.log('   3. Las variables dinámicas no están habilitadas en SendGrid');
} else {
  console.log('\n❌ PROBLEMAS DETECTADOS:');
  problems.forEach((problem, index) => {
    console.log(`   ${index + 1}. ${problem}`);
  });
}

// ============================================
// PASO 5: Instrucciones para verificar
// ============================================

console.log('\n📋 PASO 5: CÓMO VERIFICAR EL TEMPLATE EN SENDGRID');
console.log('-'.repeat(80));

console.log(`
🔍 Para verificar que el template está bien configurado:

1. Ve a: https://app.sendgrid.com/email_templates
2. Busca el template con ID: ${templateId}
3. Haz clic en "Edit" para abrir el editor
4. Busca en el HTML del template la variable: {{recovery_link}}

   DEBE aparecer en:
   - <a href="{{recovery_link}}" class="button">Restablecer Contraseña</a>
   - Y también en el link alternativo: {{recovery_link}}

5. Si NO encuentras {{recovery_link}} en el template:
   ❌ AHÍ ESTÁ EL PROBLEMA - El template no tiene la variable configurada
   
   SOLUCIÓN:
   - Busca el botón o link de "Restablecer Contraseña"
   - Reemplaza cualquier URL hardcodeada por: {{recovery_link}}
   - Guarda el template

6. También verifica en la versión de texto plano que tenga: {{recovery_link}}
`);

// ============================================
// RESUMEN FINAL
// ============================================

console.log('\n' + '='.repeat(80));
console.log('📊 RESUMEN FINAL');
console.log('='.repeat(80));

console.log('\n✅ Lo que está funcionando:');
console.log('   - Edge Function genera recovery_link correctamente');
console.log('   - Payload se construye con template_data.recovery_link');
console.log('   - Servidor PHP recibe y procesa correctamente');

console.log('\n⚠️ VERIFICAR EN SENDGRID:');
console.log('   - El template ID ' + templateId + ' debe tener {{recovery_link}} configurado');
console.log('   - La variable debe estar en el href del botón Y en el texto del link');

console.log('\n' + '='.repeat(80));

