import 'dart:convert';
import 'dart:io';

import '../config/env.dart';

class NetDiagReport {
  final List<String> lines = [];
  void log(String msg) => lines.add('${DateTime.now().toIso8601String()}  $msg');
  @override
  String toString() => lines.join('\n');
}

class NetDiagnostics {
  final String host; // e.g. whtiazgcxdnemrrgjjqf.supabase.co
  final int port;    // 443
  final String httpsPath; // e.g. /functions/v1/get-codigos

  NetDiagnostics({
    required this.host,
    this.port = 443,
    required this.httpsPath,
  });

  Future<NetDiagReport> run() async {
    final rep = NetDiagReport();
    try {
      rep.log('=== DIAGNÓSTICO DE RED IN-APP ===');
      rep.log('Host: $host  Port: $port  Path: $httpsPath');

      // 1) DNS
      try {
        rep.log('DNS: resolviendo $host …');
        final addrs = await InternetAddress.lookup(host);
        for (final a in addrs) {
          rep.log('DNS OK → ${a.address} (${a.type})');
        }
      } catch (e) {
        rep.log('DNS FAIL → $e');
        return rep; // sin DNS no seguimos
      }

      // 2) TCP directo a 443
      InternetAddress ip;
      try {
        ip = (await InternetAddress.lookup(host)).first;
        rep.log('TCP: conectando a ${ip.address}:$port …');
        final socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 8));
        rep.log('TCP OK → connected local ${socket.address.address}:${socket.port}');
        await socket.close();
      } catch (e) {
        rep.log('TCP FAIL → $e');
        // Seguimos para ver si TLS/HTTP dan más pistas
      }

      // 3) TLS handshake e info del certificado
      try {
        rep.log('TLS: handshake con $host:$port …');
        final raw = await Socket.connect(host, port, timeout: const Duration(seconds: 8));
        final secure = await SecureSocket.secure(raw, host: host, onBadCertificate: (X509Certificate cert) {
          rep.log('TLS WARN: certificado NO confiable → ${cert.subject}');
          return false; // no aceptes en prod; sólo informativo
        });
        rep.log('TLS OK → protocolo: ${secure.selectedProtocol ?? "desconocido"}');
        if (secure.peerCertificate != null) {
          final c = secure.peerCertificate!;
          rep.log('Cert → Subject: ${c.subject}');
          rep.log('Cert → Issuer : ${c.issuer}');
          rep.log('Cert → Start  : ${c.startValidity}');
          rep.log('Cert → End    : ${c.endValidity}');
        }
        await secure.close();
      } catch (e) {
        rep.log('TLS FAIL → $e');
        // Si cae aquí, casi seguro es cadena/raíz no confiada o bloqueo TLS
      }

      // 4) HTTP HEAD / GET
      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 15);
        final uri = Uri.https(host, httpsPath);
        rep.log('HTTP: GET $uri …');
        final req = await client.getUrl(uri);
        // Cabeceras completas incluyendo autorización
        req.headers.set(HttpHeaders.userAgentHeader, 'Manifestacion/1.0');
        req.headers.set(HttpHeaders.acceptHeader, 'application/json');
        req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
        req.headers.set(HttpHeaders.authorizationHeader, 'Bearer ${Env.supabaseAnonKey}');
        final res = await req.close();
        rep.log('HTTP OK → status ${res.statusCode}');
        final body = await utf8.decodeStream(res);
        rep.log('HTTP body (trunc) → ${body.substring(0, body.length.clamp(0, 300))}');
      } catch (e) {
        rep.log('HTTP FAIL → $e');
      }

      rep.log('=== FIN DIAGNÓSTICO ===');
      return rep;
    } catch (e) {
      rep.log('EXCEPTION GLOBAL → $e');
      return rep;
    }
  }
}
