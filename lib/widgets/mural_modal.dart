import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/mural_message.dart';
import '../services/mural_service.dart';
import 'custom_button.dart';

class MuralModal extends StatefulWidget {
  const MuralModal({super.key});

  @override
  State<MuralModal> createState() => _MuralModalState();
}

class _MuralModalState extends State<MuralModal> {
  final MuralService _muralService = MuralService();
  List<MuralMessage> _messages = [];
  bool _isLoading = true;
  Set<int> _readMessageIds = {};

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final messages = await _muralService.getActiveMessages();
      final readIds = await _muralService.getReadMessageIds();

      if (mounted) {
        setState(() {
          _messages = messages;
          _readMessageIds = readIds.toSet();
          _isLoading = false;
        });
        // Ya NO se marca todo como leído automáticamente al abrir: el
        // usuario decide con el check "No mostrar de nuevo" en cada
        // mensaje. Sin marcarlo, el mensaje sigue apareciendo la próxima
        // vez que entre a la app.
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleDontShowAgain(int messageId, bool value) async {
    setState(() {
      if (value) {
        _readMessageIds.add(messageId);
      } else {
        _readMessageIds.remove(messageId);
      }
    });
    if (value) {
      await _muralService.markAsRead(messageId);
    } else {
      await _muralService.markAsUnread(messageId);
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 500,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1C2541),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFFFD700).withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0B132B),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFFFFD700).withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.campaign,
                      color: Color(0xFFFFD700),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mural de la Comunidad',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Eventos y Anuncios Importantes',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
                  : _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.notifications_off_outlined,
                                size: 64,
                                color: Colors.white.withOpacity(0.2),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay anuncios por el momento',
                                style: GoogleFonts.inter(
                                  color: Colors.white54,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: _messages.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 20),
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final isNew = !_readMessageIds.contains(message.id);
                            
                            return _buildMessageCard(message, isNew);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard(MuralMessage message, bool isNew) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNew 
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
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 150,
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
                    if (isNew)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'NUEVO',
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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
                ),
                if (message.actionUrl != null && message.actionUrl!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: 'Ver Más',
                      onPressed: () => _launchUrl(message.actionUrl!),
                      icon: Icons.arrow_forward,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _toggleDontShowAgain(message.id, !_readMessageIds.contains(message.id)),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: Checkbox(
                            value: _readMessageIds.contains(message.id),
                            onChanged: (value) => _toggleDontShowAgain(message.id, value ?? false),
                            activeColor: const Color(0xFFFFD700),
                            checkColor: const Color(0xFF0B132B),
                            side: const BorderSide(color: Colors.white54),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'No mostrar de nuevo',
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
