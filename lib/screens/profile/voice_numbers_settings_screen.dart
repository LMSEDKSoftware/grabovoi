import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glow_background.dart';
import '../../services/rewards_service.dart';

/// Pantalla de configuración: voz numérica en pilotajes (Premium).
/// Switch para activar/desactivar y selector Hombre/Mujer.
class VoiceNumbersSettingsScreen extends StatefulWidget {
  const VoiceNumbersSettingsScreen({super.key});

  @override
  State<VoiceNumbersSettingsScreen> createState() => _VoiceNumbersSettingsScreenState();
}

class _VoiceNumbersSettingsScreenState extends State<VoiceNumbersSettingsScreen> {
  final RewardsService _rewardsService = RewardsService();
  bool _voiceNumbersEnabled = false;
  String _voiceGender = 'female';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rewards = await _rewardsService.getUserRewards();
      if (mounted) {
        setState(() {
          _voiceNumbersEnabled = rewards.voiceNumbersEnabled;
          _voiceGender = rewards.voiceGender == 'male' ? 'male' : 'female';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _setEnabled(bool value) async {
    setState(() => _isSaving = true);
    try {
      await _rewardsService.saveVoiceNumbersSettings(
        enabled: value,
        gender: _voiceGender,
      );
      if (mounted) setState(() {
        _voiceNumbersEnabled = value;
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración guardada'),
            backgroundColor: Color(0xFFFFD700),
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _setGender(String value) async {
    setState(() => _isSaving = true);
    try {
      await _rewardsService.saveVoiceNumbersSettings(
        enabled: _voiceNumbersEnabled,
        gender: value,
      );
      if (mounted) setState(() {
        _voiceGender = value;
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración guardada'),
            backgroundColor: Color(0xFFFFD700),
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B132B),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Repetición guiada',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFFD700),
          ),
        ),
      ),
      body: GlowBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'La voz se reproduce durante el pilotaje leyendo la secuencia dígito a dígito. Puedes desactivarla en cualquier momento.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  value: _voiceNumbersEnabled,
                  onChanged: _isSaving ? null : _setEnabled,
                  title: Text(
                    'Activar voz numérica',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Reproducir la secuencia con voz durante el pilotaje',
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                  ),
                  activeColor: const Color(0xFFFFD700),
                ),
                const SizedBox(height: 16),
                Text(
                  'Voz',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _GenderChip(
                        label: 'Mujer',
                        value: 'female',
                        selected: _voiceGender == 'female',
                        onTap: _isSaving ? null : () => _setGender('female'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _GenderChip(
                        label: 'Hombre',
                        value: 'male',
                        selected: _voiceGender == 'male',
                        onTap: _isSaving ? null : () => _setGender('male'),
                      ),
                    ),
                  ],
                ),
                if (_isSaving) ...[
                  const SizedBox(height: 24),
                  const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback? onTap;

  const _GenderChip({
    required this.label,
    required this.value,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? const Color(0xFFFFD700).withOpacity(0.25)
          : const Color(0xFF2C3E50).withOpacity(0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? const Color(0xFFFFD700) : Colors.white24,
              width: selected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: selected ? const Color(0xFFFFD700) : Colors.white70,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
