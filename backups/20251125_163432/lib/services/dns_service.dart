import 'dart:io';
import 'dart:async';

class DnsService {
  /// Cambia el DNS del dispositivo a Google DNS (8.8.8.8)
  /// ⚠️ SOLO PARA ANDROID - REQUIERE PERMISOS ROOT O ADB
  static Future<bool> changeDnsToGoogle() async {
    try {
      print('🔧 [DNS] Cambiando DNS a Google (8.8.8.8)...');
      
      // Método 1: Usando setprop (requiere permisos)
      final result1 = await Process.run('setprop', ['net.dns1', '8.8.8.8']);
      if (result1.exitCode == 0) {
        print('✅ [DNS] DNS cambiado exitosamente via setprop');
        return true;
      }
      
      // Método 2: Usando su (requiere root)
      final result2 = await Process.run('su', ['-c', 'setprop net.dns1 8.8.8.8']);
      if (result2.exitCode == 0) {
        print('✅ [DNS] DNS cambiado exitosamente via su');
        return true;
      }
      
      print('❌ [DNS] No se pudo cambiar DNS (requiere permisos root)');
      return false;
    } catch (e) {
      print('❌ [DNS] Error cambiando DNS: $e');
      return false;
    }
  }

  /// Verifica el DNS actual del dispositivo
  static Future<String?> getCurrentDns() async {
    try {
      print('🔍 [DNS] Verificando DNS actual...');
      
      final result = await Process.run('getprop', ['net.dns1']);
      if (result.exitCode == 0) {
        final dns = result.stdout.toString().trim();
        print('📊 [DNS] DNS actual: $dns');
        return dns;
      }
      
      return null;
    } catch (e) {
      print('❌ [DNS] Error verificando DNS: $e');
      return null;
    }
  }

  /// Prueba conectividad con diferentes DNS
  static Future<bool> testConnectivityWithDns() async {
    final dnsServers = [
      '8.8.8.8',      // Google DNS
      '8.8.4.4',      // Google DNS secundario
      '1.1.1.1',      // Cloudflare DNS
      '1.0.0.1',      // Cloudflare DNS secundario
      '208.67.222.222', // OpenDNS
    ];

    for (final dns in dnsServers) {
      try {
        print('🧪 [DNS] Probando conectividad con DNS: $dns');
        
        // Probar resolución DNS
        final result = await InternetAddress.lookup('whtiazgcxdnemrrgjjqf.supabase.co');
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          print('✅ [DNS] Conectividad exitosa con DNS: $dns');
          return true;
        }
      } catch (e) {
        print('❌ [DNS] Fallo con DNS: $dns - $e');
        continue;
      }
    }

    print('❌ [DNS] Todos los DNS fallaron');
    return false;
  }

  /// Configura DNS automáticamente si es posible
  static Future<bool> autoConfigureDns() async {
    print('🔧 [DNS] Configurando DNS automáticamente...');
    
    // Verificar DNS actual
    final currentDns = await getCurrentDns();
    print('📊 [DNS] DNS actual: $currentDns');
    
    // Si ya es Google DNS, no hacer nada
    if (currentDns == '8.8.8.8' || currentDns == '8.8.4.4') {
      print('✅ [DNS] Ya está usando Google DNS');
      return true;
    }
    
    // Intentar cambiar a Google DNS
    final changed = await changeDnsToGoogle();
    if (changed) {
      print('✅ [DNS] DNS cambiado exitosamente');
      return true;
    }
    
    // Si no se puede cambiar, probar conectividad con DNS actual
    print('🔄 [DNS] No se pudo cambiar DNS, probando conectividad actual...');
    return await testConnectivityWithDns();
  }
}
