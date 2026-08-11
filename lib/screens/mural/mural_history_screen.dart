import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/mural_message.dart';
import '../../services/mural_service.dart';
import '../../services/admin_service.dart';

class MuralHistoryScreen extends StatefulWidget {
  const MuralHistoryScreen({super.key});

  @override
  State<MuralHistoryScreen> createState() => _MuralHistoryScreenState();
}

class _MuralHistoryScreenState extends State<MuralHistoryScreen> {
  final MuralService _muralService = MuralService();
  List<MuralMessage> _allMessages = [];
  Set<int> _readMessageIds = {};
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final isAdmin = await AdminService.esAdmin();
    if (mounted) setState(() => _isAdmin = isAdmin);
    await _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      // El admin ve todo (activas e inactivas); un usuario normal solo ve
      // las activas, porque mural_messages solo tiene política de SELECT
      // para is_active=true.
      final messages = _isAdmin
          ? (await AdminService.muralListAll()).map((json) => MuralMessage.fromJson(json)).toList()
          : await _muralService.getAllMessages();
      final readIds = await _muralService.getReadMessageIds();

      if (mounted) {
        setState(() {
          _allMessages = messages;
          _readMessageIds = readIds.toSet();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el enlace: $urlString')),
        );
      }
    }
  }

  Future<void> _openCreateDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => const _MuralFormDialog(),
    );
    if (created == true) await _loadMessages();
  }

  Future<void> _openEditDialog(MuralMessage message) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => _MuralFormDialog(existing: message),
    );
    if (updated == true) await _loadMessages();
  }

  Future<void> _toggleActive(MuralMessage message) async {
    try {
      await AdminService.muralUpdate(id: message.id, isActive: !message.isActive);
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmDelete(MuralMessage message) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2541),
        title: const Text('¿Eliminar publicación?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Se eliminará "${message.title}" permanentemente, junto con su historial de lecturas.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await AdminService.muralDelete(message.id);
      await _loadMessages();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Publicación eliminada'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C2541),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.campaign,
                color: Color(0xFFFFD700),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Historial del Mural',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              backgroundColor: const Color(0xFFFFD700),
              onPressed: _openCreateDialog,
              child: const Icon(Icons.add, color: Color(0xFF0B132B)),
            )
          : null,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD700)),
            )
          : _allMessages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay mensajes en el historial',
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
                  itemCount: _allMessages.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final message = _allMessages[index];
                    final isRead = _readMessageIds.contains(message.id);
                    final isActive = message.isActive;

                    return _buildMessageCard(message, isRead, isActive);
                  },
                ),
    );
  }

  Widget _buildMessageCard(MuralMessage message, bool isRead, bool isActive) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: !isRead && isActive
              ? const Color(0xFFFFD700).withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image if available
          if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: message.imageUrl!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 120,
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => const SizedBox.shrink(),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Badges
                    if (!isActive)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'INACTIVO',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    if (!isRead && isActive)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'NO VISTO',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0B132B),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        message.title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (_isAdmin)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white54, size: 20),
                        color: const Color(0xFF1C2541),
                        onSelected: (value) {
                          if (value == 'edit') _openEditDialog(message);
                          if (value == 'toggle') _toggleActive(message);
                          if (value == 'delete') _confirmDelete(message);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(children: [
                              Icon(Icons.edit, color: Color(0xFFFFD700), size: 18),
                              SizedBox(width: 8),
                              Text('Editar', style: TextStyle(color: Colors.white)),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'toggle',
                            child: Row(children: [
                              Icon(isActive ? Icons.visibility_off : Icons.visibility, color: Colors.orange, size: 18),
                              const SizedBox(width: 8),
                              Text(isActive ? 'Desactivar' : 'Activar', style: const TextStyle(color: Colors.white)),
                            ]),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              Icon(Icons.delete, color: Colors.red, size: 18),
                              SizedBox(width: 8),
                              Text('Eliminar', style: TextStyle(color: Colors.white)),
                            ]),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('d MMM yyyy').format(message.createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message.message,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (message.actionUrl != null && message.actionUrl!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => _launchUrl(message.actionUrl!),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Ver más'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFFD700),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Formulario de creación/edición de una publicación del mural (solo admin).
class _MuralFormDialog extends StatefulWidget {
  final MuralMessage? existing;
  const _MuralFormDialog({this.existing});

  @override
  State<_MuralFormDialog> createState() => _MuralFormDialogState();
}

class _MuralFormDialogState extends State<_MuralFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _messageCtrl;
  late final TextEditingController _imageUrlCtrl;
  late final TextEditingController _actionUrlCtrl;
  String _type = 'info';
  DateTime? _expiresAt;
  bool _saving = false;
  bool _uploadingImage = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _messageCtrl = TextEditingController(text: e?.message ?? '');
    _imageUrlCtrl = TextEditingController(text: e?.imageUrl ?? '');
    _actionUrlCtrl = TextEditingController(text: e?.actionUrl ?? '');
    _type = e?.type ?? 'info';
    _expiresAt = e?.expiresAt;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    _imageUrlCtrl.dispose();
    _actionUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
      if (file == null) return;

      setState(() => _uploadingImage = true);
      final url = await AdminService.muralUploadImage(file);
      if (mounted) {
        setState(() {
          _imageUrlCtrl.text = url;
          _uploadingImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error subiendo imagen: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickExpiresAt() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _expiresAt = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (_isEditing) {
        await AdminService.muralUpdate(
          id: widget.existing!.id,
          title: _titleCtrl.text.trim(),
          message: _messageCtrl.text.trim(),
          imageUrl: _imageUrlCtrl.text.trim(),
          actionUrl: _actionUrlCtrl.text.trim(),
          type: _type,
          expiresAt: _expiresAt,
          clearExpiresAt: _expiresAt == null,
        );
      } else {
        await AdminService.muralCreate(
          title: _titleCtrl.text.trim(),
          message: _messageCtrl.text.trim(),
          imageUrl: _imageUrlCtrl.text.trim().isEmpty ? null : _imageUrlCtrl.text.trim(),
          actionUrl: _actionUrlCtrl.text.trim().isEmpty ? null : _actionUrlCtrl.text.trim(),
          type: _type,
          expiresAt: _expiresAt,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = (String label) => InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85, maxWidth: 500),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1C2541),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isEditing ? 'Editar Publicación' : 'Nueva Publicación',
                  style: GoogleFonts.playfairDisplay(color: const Color(0xFFFFD700), fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration('Título'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _messageCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration('Mensaje'),
                  maxLines: 4,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _type,
                  dropdownColor: const Color(0xFF1C2541),
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration('Tipo'),
                  items: const [
                    DropdownMenuItem(value: 'info', child: Text('Info')),
                    DropdownMenuItem(value: 'event', child: Text('Evento')),
                  ],
                  onChanged: (v) => setState(() => _type = v ?? 'info'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageUrlCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration('URL de imagen (opcional)'),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _uploadingImage ? null : _pickAndUploadImage,
                    icon: _uploadingImage
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.photo_camera, size: 18),
                    label: Text(_uploadingImage ? 'Subiendo...' : 'Subir desde el dispositivo'),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFFFFD700)),
                  ),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _actionUrlCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: inputDecoration('Link "Ver más" (opcional)'),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickExpiresAt,
                  child: InputDecorator(
                    decoration: inputDecoration('Fecha de expiración (opcional)'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _expiresAt != null ? DateFormat('d MMM yyyy').format(_expiresAt!) : 'Sin fecha',
                          style: const TextStyle(color: Colors.white),
                        ),
                        if (_expiresAt != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: Colors.white54),
                            onPressed: () => setState(() => _expiresAt = null),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                        child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700)),
                        child: _saving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0B132B)))
                            : Text(_isEditing ? 'Guardar' : 'Publicar', style: const TextStyle(color: Color(0xFF0B132B), fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
