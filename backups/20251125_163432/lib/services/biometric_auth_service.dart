import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class BiometricAuthService {
  static final BiometricAuthService _instance = BiometricAuthService._internal();
  factory BiometricAuthService() => _instance;
  BiometricAuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();

  // Verificar si el dispositivo soporta autenticación biométrica
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      print('Error verificando soporte biométrico: $e');
      return false;
    }
  }

  // Verificar si hay métodos biométricos disponibles
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      print('Error verificando disponibilidad biométrica: $e');
      return false;
    }
  }

  // Obtener métodos biométricos disponibles
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Error obteniendo métodos biométricos: $e');
      return [];
    }
  }

  // Verificar si hay credenciales guardadas para autenticación biométrica
  Future<bool> hasBiometricCredentials() async {
    try {
      final availableBiometrics = await getAvailableBiometrics();
      return availableBiometrics.isNotEmpty && await canCheckBiometrics();
    } catch (e) {
      print('Error verificando credenciales biométricas: $e');
      return false;
    }
  }

  // Autenticar con biométrica
  Future<bool> authenticate({
    String reason = 'Autentícate para acceder a tu cuenta',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      final isAvailable = await canCheckBiometrics();
      if (!isAvailable) {
        print('⚠️ Autenticación biométrica no disponible');
        return false;
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true, // Solo usar biométrica, no PIN/patrón
        ),
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      print('❌ Error en autenticación biométrica: $e');
      return false;
    } catch (e) {
      print('❌ Error desconocido en autenticación biométrica: $e');
      return false;
    }
  }

  // Obtener el nombre del método biométrico disponible
  Future<String> getBiometricTypeName() async {
    try {
      final availableBiometrics = await getAvailableBiometrics();
      
      if (availableBiometrics.isEmpty) {
        return 'Biometría';
      }

      // Priorizar Face ID en iOS
      if (Platform.isIOS && availableBiometrics.contains(BiometricType.face)) {
        return 'Face ID';
      }
      
      // Priorizar huella dactilar
      if (availableBiometrics.contains(BiometricType.fingerprint)) {
        return 'Huella dactilar';
      }
      
      // Face ID
      if (availableBiometrics.contains(BiometricType.face)) {
        return 'Face ID';
      }
      
      // Iris (menos común)
      if (availableBiometrics.contains(BiometricType.iris)) {
        return 'Iris';
      }
      
      // Strong (Android - puede ser huella o Face)
      if (availableBiometrics.contains(BiometricType.strong)) {
        return 'Biometría';
      }
      
      // Weak (Android - puede ser reconocimiento facial menos seguro)
      if (availableBiometrics.contains(BiometricType.weak)) {
        return 'Reconocimiento facial';
      }

      return 'Biometría';
    } catch (e) {
      print('Error obteniendo nombre de tipo biométrico: $e');
      return 'Biometría';
    }
  }

  // Obtener el ícono apropiado según el tipo de biométrica
  String getBiometricIcon() {
    // Retornamos el nombre del ícono, el widget lo manejará
    // 'fingerprint' para huella, 'face' para Face ID
    return 'fingerprint'; // Por defecto, se puede mejorar detectando el tipo
  }

  // Detener autenticación en curso
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (e) {
      print('Error deteniendo autenticación: $e');
    }
  }
}

