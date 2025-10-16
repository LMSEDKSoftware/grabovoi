import 'package:flutter/material.dart';
import '../../services/net_diag.dart';

class DiagScreen extends StatefulWidget {
  const DiagScreen({super.key});
  @override
  State<DiagScreen> createState() => _DiagScreenState();
}

class _DiagScreenState extends State<DiagScreen> {
  String _report = 'Pulsa "Probar red" para iniciar diagnóstico';
  bool _isRunning = false;

  Future<void> _run() async {
    setState(() {
      _isRunning = true;
      _report = 'Ejecutando diagnóstico...';
    });

    final diag = NetDiagnostics(
      host: 'whtiazgcxdnemrrgjjqf.supabase.co',
      httpsPath: '/functions/v1/get-codigos',
    );
    final r = await diag.run();
    
    setState(() {
      _report = r.toString();
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C2541),
        title: const Text('🔍 Diagnóstico de Red', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1C2541),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _isRunning ? null : _run,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: const Color(0xFF0B132B),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: _isRunning 
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0B132B)),
                          ),
                          SizedBox(width: 8),
                          Text('Ejecutando...'),
                        ],
                      )
                    : const Text('🔍 Probar Red', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Este diagnóstico probará DNS, TCP, TLS y HTTP paso a paso',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: SelectableText(
                  _report, 
                  style: const TextStyle(
                    fontFamily: 'monospace', 
                    fontSize: 11,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
