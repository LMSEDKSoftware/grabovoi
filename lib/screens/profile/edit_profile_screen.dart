import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service_simple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/custom_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final AuthServiceSimple _authService = AuthServiceSimple();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _avatarUrlCtrl = TextEditingController();
  String? _timezone;
  bool _saving = false;

  final List<String> _timezones = const [
    'UTC',
    'America/Mexico_City',
    'America/Monterrey',
    'America/Bogota',
    'America/Lima',
    'America/Santiago',
    'America/Buenos_Aires',
    'America/New_York',
    'America/Los_Angeles',
    'Europe/Madrid',
  ];

  @override
  void initState() {
    super.initState();
    final appUser = _authService.currentUser;
    final authUser = Supabase.instance.client.auth.currentUser;
    _nameCtrl.text = appUser?.name ?? authUser?.userMetadata?['name'] ?? '';
    _avatarUrlCtrl.text = authUser?.userMetadata?['avatar_url'] ?? '';
    _timezone = authUser?.userMetadata?['timezone'] ?? 'UTC';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _avatarUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _authService.updateProfile(
        name: _nameCtrl.text.trim(),
        avatarUrl: _avatarUrlCtrl.text.trim().isEmpty ? null : _avatarUrlCtrl.text.trim(),
        timezone: _timezone ?? 'UTC',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Perfil actualizado')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('❌ Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: const Color(0xFF1C2541),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Text('Nombre', style: GoogleFonts.inter(color: Colors.white70)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(hintText: 'Tu nombre'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              Text('Imagen de perfil (URL)', style: GoogleFonts.inter(color: Colors.white70)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _avatarUrlCtrl,
                decoration: const InputDecoration(hintText: 'https://...'),
              ),
              const SizedBox(height: 16),
              Text('Zona horaria', style: GoogleFonts.inter(color: Colors.white70)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _timezone,
                items: _timezones
                    .map((tz) => DropdownMenuItem(value: tz, child: Text(tz)))
                    .toList(),
                onChanged: (v) => setState(() => _timezone = v),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: _saving ? 'Guardando...' : 'Guardar',
                onPressed: _saving ? null : _save,
                icon: Icons.save,
                color: const Color(0xFFFFD700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


