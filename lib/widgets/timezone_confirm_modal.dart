import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../services/auth_service_simple.dart';

/// Modal que se muestra UNA sola vez (mientras el usuario no tenga
/// user_metadata.timezone guardado) para detectar y confirmar su zona
/// horaria automáticamente. Los recordatorios y notificaciones programadas
/// del lado del servidor (desafíos, resumen semanal, prueba por terminar)
/// dependen de este valor para calcular la hora local de cada usuario; sin
/// él, todos corren en UTC por defecto.
class TimezoneConfirmModal extends StatefulWidget {
  const TimezoneConfirmModal({super.key});

  /// Solo debe mostrarse si el dispositivo soporta detección nativa (no web)
  /// y el usuario todavía no tiene una zona horaria guardada.
  static Future<bool> shouldShow() async {
    if (kIsWeb) return false;
    final metaTz = Supabase.instance.client.auth.currentUser?.userMetadata?['timezone'] as String?;
    return metaTz == null || metaTz.trim().isEmpty;
  }

  /// Abre el selector con búsqueda de zonas horarias (usado también desde
  /// Configuración para corregir la zona ya guardada).
  static Future<String?> showPicker(BuildContext context, {required String current}) {
    tz_data.initializeTimeZones();
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _TimezonePickerSheet(current: current),
    );
  }

  @override
  State<TimezoneConfirmModal> createState() => _TimezoneConfirmModalState();
}

class _TimezoneConfirmModalState extends State<TimezoneConfirmModal> {
  bool _detecting = true;
  bool _saving = false;
  String _detectedTz = 'UTC';

  @override
  void initState() {
    super.initState();
    _detect();
  }

  Future<void> _detect() async {
    try {
      tz_data.initializeTimeZones();
      final detected = await FlutterTimezone.getLocalTimezone();
      final valid = tz.timeZoneDatabase.locations.containsKey(detected) ? detected : 'UTC';
      if (mounted) setState(() { _detectedTz = valid; _detecting = false; });
    } catch (e) {
      debugPrint('⚠️ Error detectando zona horaria: $e');
      if (mounted) setState(() { _detectedTz = 'UTC'; _detecting = false; });
    }
  }

  Future<void> _save(String timezone) async {
    setState(() => _saving = true);
    try {
      await AuthServiceSimple().updateProfile(timezone: timezone);
    } catch (e) {
      debugPrint('⚠️ Error guardando zona horaria: $e');
    } finally {
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _openPicker() async {
    final selected = await TimezoneConfirmModal.showPicker(context, current: _detectedTz);
    if (selected != null) {
      await _save(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.public, size: 36, color: Color(0xFFFFD700)),
              ),
              const SizedBox(height: 20),
              Text(
                'Tu zona horaria',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (_detecting)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(color: Color(0xFFFFD700)),
                )
              else ...[
                Text(
                  'Detectamos que tu zona horaria es:',
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
                  ),
                  child: Text(
                    _detectedTz,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFFD700),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'La usaremos para que tus recordatorios y notificaciones lleguen a la hora correcta.',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _saving ? null : _openPicker,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.white.withOpacity(0.3)),
                          ),
                        ),
                        child: Text('Elegir otra', style: GoogleFonts.inter(color: Colors.white70)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _saving ? null : () => _save(_detectedTz),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: const Color(0xFF0B132B),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0B132B)),
                              )
                            : Text('Es correcta', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Selector con búsqueda entre todas las zonas horarias IANA disponibles
/// (reemplaza la lista fija de 10 zonas que tenía EditProfileScreen).
class _TimezonePickerSheet extends StatefulWidget {
  final String current;
  const _TimezonePickerSheet({required this.current});

  @override
  State<_TimezonePickerSheet> createState() => _TimezonePickerSheetState();
}

class _TimezonePickerSheetState extends State<_TimezonePickerSheet> {
  late final List<String> _allZones;
  late List<String> _filtered;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    tz_data.initializeTimeZones();
    _allZones = tz.timeZoneDatabase.locations.keys.toList()..sort();
    _filtered = _allZones;
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _allZones
          : _allZones.where((z) => z.toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
            ),
            TextField(
              controller: _searchCtrl,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar zona horaria (ej. Bogota, Madrid)',
                hintStyle: GoogleFonts.inter(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFFFD700)),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final zone = _filtered[index];
                  final isSelected = zone == widget.current;
                  return ListTile(
                    title: Text(zone, style: GoogleFonts.inter(color: Colors.white)),
                    trailing: isSelected ? const Icon(Icons.check, color: Color(0xFFFFD700)) : null,
                    onTap: () => Navigator.of(context).pop(zone),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
