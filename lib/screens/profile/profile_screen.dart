import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/custom_button.dart';
import '../../services/auth_service_simple.dart';
import '../../services/user_progress_service.dart';
import '../../services/audio_service.dart';
import '../../services/audio_manager_service.dart';
import '../../services/supabase_service.dart';
import '../../repositories/codigos_repository.dart';
import '../auth/login_screen.dart';
import '../sugerencias/sugerencias_screen.dart';
import 'edit_profile_screen.dart';
import 'notifications_settings_screen.dart';
import 'notification_history_screen.dart';
import '../mural/mural_history_screen.dart';
import '../../services/admin_service.dart';
import '../../screens/home/home_screen.dart';
import '../admin/approve_suggestions_screen.dart';
import '../admin/view_reports_screen.dart';
import '../rewards/premium_store_screen.dart';
import '../rewards/mantras_screen.dart';
import '../resources/resources_screen.dart';
import '../subscription/subscription_screen.dart';
import '../../models/notification_history_item.dart';
import '../../services/notification_count_service.dart';
import '../../services/subscription_service.dart';
import '../../widgets/subscription_required_modal.dart';
import '../../services/biometric_auth_service.dart';
import '../../scripts/test_all_notifications.dart';
import '../../services/legal_links_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  final AuthServiceSimple _authService = AuthServiceSimple();
  final UserProgressService _progressService = UserProgressService();
  
  Map<String, dynamic>? _userProgress;
  bool _isLoading = true;
  bool _isAdmin = false;
  int _unreadNotificationsCount = 0;
  
  // Animaciones
  late AnimationController _quantumController;
  late AnimationController _fadeController;
  late Animation<double> _quantumAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initAnimations();
  }
  
  void _initAnimations() {
    _quantumController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();
    
    _quantumAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _quantumController, curve: Curves.linear),
    );
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
  }
  
  @override
  void dispose() {
    _quantumController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (!_authService.isLoggedIn) return;
    
    try {
      final progress = await _progressService.getUserProgress();
      final esAdmin = await AdminService.esAdmin();
      final unreadCount = await NotificationHistory.getUnreadCount();
      
      setState(() {
        _userProgress = progress;
        _isAdmin = esAdmin;
        _unreadNotificationsCount = unreadCount;
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando datos del usuario: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recargar conteo de notificaciones cuando la pantalla se vuelve visible
    _loadNotificationCount();
  }
  
  Future<void> _loadNotificationCount() async {
    final unreadCount = await NotificationHistory.getUnreadCount();
    if (mounted) {
      setState(() {
        _unreadNotificationsCount = unreadCount;
      });
      // Actualizar el servicio compartido para sincronizar la burbuja en el icono de Perfil
      await NotificationCountService().updateCount();
    }
  }

  Future<void> _signOut() async {
    try {
      // Detener todos los servicios de audio antes de cerrar sesión
      final audioService = AudioService();
      await audioService.stopMusic();
      
      final audioManagerService = AudioManagerService();
      await audioManagerService.stop();
      
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error cerrando sesión: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Ocultar el teclado cuando se toca fuera de cualquier campo
        FocusScope.of(context).unfocus();
      },
      child: SizedBox.expand(
        child: _buildQuantumBackground(
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    // Avatar circular con iniciales
                    _buildAvatar(),
                    const SizedBox(height: 24),
                    // Información del usuario
                    if (_authService.isLoggedIn && _authService.currentUser != null) ...[
                      Text(
                        _authService.currentUser!.name,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFD700),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _authService.currentUser!.email,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: const Color(0xFFFFD700),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 30),
                    // Botones de acción organizados en grid de 2 columnas
                    // Para usuarios gratuitos, solo mostrar Suscripciones
                    Builder(
                      builder: (context) {
                        final subscriptionService = SubscriptionService();
                        final isFreeUser = subscriptionService.isFreeUser;
                        
                        if (isFreeUser) {
                          // Usuario gratuito - solo mostrar botón de Suscripciones
                          return Column(
                            children: [
                            _buildSubscriptionButton(context),
                            ],
                          );
                        }
                        
                        // Usuario premium - mostrar todos los botones
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 3.0,
                          padding: EdgeInsets.zero,
                          children: [
                            _buildCompactButton(
                              text: 'Editar Perfil',
                              icon: Icons.edit,
                              onPressed: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const EditProfileScreen(),
                                  ),
                                );
                                if (mounted) {
                                  setState(() {});
                                  await _loadUserData();
                                }
                              },
                            ),
                            _buildCompactButton(
                              text: 'Configuración',
                              icon: Icons.settings,
                              onPressed: () => _showConfigurationMenu(context),
                            ),
                            _buildCompactButton(
                              text: 'Mis Sugerencias',
                              icon: Icons.lightbulb_outline,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SugerenciasScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildCompactButton(
                              text: 'Notificaciones',
                              icon: Icons.notifications,
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const NotificationHistoryScreen(),
                                  ),
                                );
                                // Recargar conteo después de volver de la pantalla de notificaciones
                                if (mounted) {
                                  await _loadNotificationCount();
                                }
                              },
                              notificationCount: _unreadNotificationsCount,
                            ),
                            _buildCompactButton(
                              text: 'Historial del Mural',
                              icon: Icons.campaign,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const MuralHistoryScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildCompactButton(
                              text: 'Tienda Cuántica',
                              icon: Icons.store,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PremiumStoreScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildSubscriptionButton(context),
                            _buildCompactButton(
                              text: 'Recursos',
                              icon: Icons.library_books,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ResourcesScreen(),
                                  ),
                                );
                              },
                            ),
                            // Botones de administrador (solo si es admin)
                            if (_isAdmin) ...[
                              _buildCompactButton(
                                text: 'Aprobar Sugerencias',
                                icon: Icons.admin_panel_settings,
                                color: const Color(0xFFFFD700),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ApproveSuggestionsScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildCompactButton(
                                text: 'Ver Reportes',
                                icon: Icons.report,
                                color: const Color(0xFFFF6B6B),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ViewReportsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    // Sección de links legales
                    _buildLegalSection(),
                    const SizedBox(height: 20),
                    // Botón de cerrar sesión (ancho completo)
                    _buildButton(
                      text: 'Cerrar Sesión',
                      icon: Icons.logout,
                      color: Colors.orange,
                      onPressed: _signOut,
                    ),
                    const SizedBox(height: 20),
                    // Créditos
                    Text(
                      'Creado por: Iván Fernández',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Fondo cuántico con partículas animadas
  Widget _buildQuantumBackground({required Widget child}) {
    return AnimatedBuilder(
      animation: _quantumAnimation,
      builder: (context, _) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0B132B),
                Color(0xFF1C2541),
                Color(0xFF2C3E50),
              ],
            ),
          ),
          child: CustomPaint(
            painter: _QuantumFieldPainter(_quantumAnimation.value),
            child: child,
          ),
        );
      },
    );
  }
  
  // Avatar circular con iniciales o imagen, con icono de editar
  Widget _buildAvatar() {
    if (_authService.currentUser == null) return const SizedBox();
    
    final name = _authService.currentUser!.name;
    final initials = name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join().toUpperCase();
    final avatarUrl = _authService.currentUser!.avatar;
    
    return GestureDetector(
      onTap: _pickAndUploadAvatar,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFFD700), width: 3),
              gradient: avatarUrl == null ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFD700).withOpacity(0.2),
            const Color(0xFFFFD700).withOpacity(0.05),
          ],
              ) : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
            child: avatarUrl != null && avatarUrl.isNotEmpty
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: avatarUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: Text(
                          initials,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFFD700),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Text(
                          initials,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFFD700),
                          ),
                        ),
                      ),
                    ),
                  )
                : Center(
        child: Text(
          initials,
          style: GoogleFonts.playfairDisplay(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFFD700),
          ),
        ),
      ),
          ),
          // Icono de editar en la esquina inferior derecha
          Positioned(
            right: -5,
            bottom: -5,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF1a1a2e), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.edit,
                color: Color(0xFF1a1a2e),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Seleccionar y subir avatar
  Future<void> _pickAndUploadAvatar() async {
    if (_authService.currentUser == null) return;
    
    try {
      // Determinar qué permiso usar según la versión de Android
      // En Android 13+ usar Permission.photos, en versiones anteriores Permission.storage
      Permission permissionToUse = Permission.photos;
      
      // Verificar si photos está disponible (Android 13+)
      final photosStatus = await Permission.photos.status;
      if (photosStatus.isPermanentlyDenied) {
        // Si está permanentemente denegado, abrir configuración
        if (mounted) {
          final shouldOpen = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Permiso requerido'),
              content: const Text(
                'Se necesita acceso a las fotos para seleccionar un avatar. '
                '¿Deseas abrir la configuración para otorgar el permiso?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Abrir configuración'),
                ),
              ],
            ),
          );
          
          if (shouldOpen == true) {
            await openAppSettings();
            return;
          }
        }
        return;
      }
      
      // Intentar con Permission.photos primero (Android 13+)
      if (!photosStatus.isGranted) {
        final result = await Permission.photos.request();
        if (!result.isGranted) {
          // Si falla, intentar con storage (para Android anteriores)
          if (result.isPermanentlyDenied) {
            if (mounted) {
              final shouldOpen = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Permiso requerido'),
                  content: const Text(
                    'Se necesita acceso a las fotos. '
                    '¿Deseas abrir la configuración?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Abrir configuración'),
                    ),
                  ],
                ),
              );
              
              if (shouldOpen == true) {
                await openAppSettings();
              }
            }
            return;
          }
          
          // Intentar con storage como fallback
          final storageStatus = await Permission.storage.status;
          if (!storageStatus.isGranted) {
            final storageResult = await Permission.storage.request();
            if (!storageResult.isGranted) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Se necesitan permisos para acceder a las fotos'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 4),
                  ),
                );
              }
              return;
            }
          }
        }
      }
      
      // Seleccionar imagen
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 500,
        maxHeight: 500,
      );
      
      if (image == null) return;
      
      // Mostrar indicador de carga
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: Color(0xFFFFD700)),
          ),
        );
      }
      
      // Subir a Supabase
      final userId = _authService.currentUser!.id;
      final avatarUrl = await SupabaseService.uploadAvatar(userId, image);
      
      // Actualizar perfil del usuario
      await _authService.updateProfile(avatarUrl: avatarUrl);
      
      // Cerrar diálogo de carga
      if (mounted) {
        Navigator.of(context).pop();
        
        // Recargar datos del usuario
        await _authService.initialize();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Avatar actualizado correctamente'),
            backgroundColor: Color(0xFFFFD700),
          ),
        );
        
        setState(() {}); // Refrescar UI
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Cerrar diálogo si está abierto
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al subir avatar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Mostrar menú de configuración
  void _showConfigurationMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C2541),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildConfigMenuItem(
              context: context,
              icon: Icons.notifications,
              title: 'Notificaciones',
              subtitle: 'Gestionar preferencias de notificaciones',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsSettingsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildConfigMenuItem(
              context: context,
              icon: Icons.security,
              title: 'Autorizaciones de Permisos',
              subtitle: 'Gestionar permisos de la aplicación',
              onTap: () {
                Navigator.pop(context);
                _showPermissionsDialog(context);
              },
            ),
            const SizedBox(height: 16),
            _buildConfigMenuItem(
              context: context,
              icon: Icons.fingerprint,
              title: 'Autenticación Biométrica',
              subtitle: 'Face ID / Huella dactilar',
              onTap: () {
                Navigator.pop(context);
                _showBiometricSettings(context);
              },
            ),
            const SizedBox(height: 16),
            // Opción de prueba de notificaciones (solo visible para administradores)
            if (_isAdmin)
              _buildConfigMenuItem(
                context: context,
                icon: Icons.science,
                title: 'Probar Notificaciones',
                subtitle: 'Enviar todas las notificaciones de prueba',
                onTap: () async {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🧪 Iniciando prueba de notificaciones...'),
                    backgroundColor: Color(0xFFFFD700),
                  ),
                );
                // Importar dinámicamente para evitar problemas de dependencias circulares si las hubiera
                // pero como es un script, mejor usarlo directamente si ya está importado o importarlo arriba.
                // Como no puedo añadir imports arriba fácilmente sin ver todo el archivo, usaré reflexión o asumo que puedo añadir el import.
                // Mejor añado el import arriba en otro paso si es necesario, pero aquí usaré el nombre de la clase asumiendo que se importará.
                // Para evitar errores de compilación si no está importado, usaré un enfoque más seguro:
                // Crear una función local o usar el import que añadiré.
                
                // NOTA: Se requiere importar TestAllNotifications. 
                // Como no puedo añadir el import en este bloque, lo haré en un paso separado o confiaré en que el usuario lo añada.
                // Pero para ser más autónomo, voy a usar un truco: definir la llamada aquí y luego añadir el import.
                
                try {
                   // Usar el script existente
                   await TestAllNotifications.sendAllTestNotifications(
                     userName: _authService.currentUser?.name ?? 'Usuario Test',
                     delaySeconds: 5, // Más rápido para pruebas
                   );
                } catch (e) {
                  print('Error probando notificaciones: $e');
                }
              },
              ),
            const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
  
  // Item del menú de configuración
  Widget _buildConfigMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2C3E50).withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFFFD700).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFFFFD700),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFFFFD700),
            ),
          ],
        ),
      ),
    );
  }
  
  // Mostrar configuración de autenticación biométrica
  void _showBiometricSettings(BuildContext context) {
    final biometricService = BiometricAuthService();
    bool biometricEnabled = false;
    bool isChecking = true;
    bool biometricAvailable = false;
    String biometricTypeName = 'Biometría';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Verificar estado inicial
          if (isChecking) {
            Future.microtask(() async {
              final available = await biometricService.isDeviceSupported() &&
                  await biometricService.canCheckBiometrics();
              final enabled = await _authService.hasBiometricCredentials();
              final typeName = available
                  ? await biometricService.getBiometricTypeName()
                  : 'Biometría';

              setDialogState(() {
                biometricAvailable = available;
                biometricEnabled = enabled;
                biometricTypeName = typeName;
                isChecking = false;
              });
            });
          }

          if (isChecking) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1C2541),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFFFD700), width: 2),
              ),
              content: const SizedBox(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                  ),
                ),
              ),
            );
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF1C2541),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFFFD700), width: 2),
            ),
            title: Row(
              children: [
                Icon(
                  biometricTypeName.toLowerCase().contains('face')
                      ? Icons.face
                      : Icons.fingerprint,
                  color: const Color(0xFFFFD700),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Autenticación Biométrica',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!biometricAvailable)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.orange,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Tu dispositivo no soporta autenticación biométrica o no está configurada.',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    Text(
                      'Habilita $biometricTypeName para iniciar sesión de forma rápida y segura.',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C3E50).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFFD700).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Usar $biometricTypeName',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  biometricEnabled
                                      ? 'Activado - Inicia sesión con $biometricTypeName'
                                      : 'Desactivado - Usa email y contraseña',
                                  style: GoogleFonts.inter(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: biometricEnabled,
                            onChanged: biometricAvailable
                                ? (value) async {
                                    if (value) {
                                      // Activar: pedir autenticación biométrica
                                      final authenticated =
                                          await biometricService.authenticate(
                                        reason:
                                            'Autentícate con $biometricTypeName para habilitar el inicio de sesión biométrico',
                                      );

                                      if (authenticated) {
                                        // Obtener credenciales del usuario actual
                                        final user = _authService.currentUser;
                                        if (user != null) {
                                          // Necesitamos el email, pero no tenemos la contraseña
                                          // Mostrar diálogo para ingresar contraseña
                                          final passwordController =
                                              TextEditingController();
                                          final formKey = GlobalKey<FormState>();

                                          final shouldSave = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              backgroundColor:
                                                  const Color(0xFF1C2541),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                side: const BorderSide(
                                                  color: Color(0xFFFFD700),
                                                  width: 2,
                                                ),
                                              ),
                                              title: Text(
                                                'Confirmar Contraseña',
                                                style: GoogleFonts.inter(
                                                  color: const Color(0xFFFFD700),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              content: Form(
                                                key: formKey,
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      'Ingresa tu contraseña para guardar tus credenciales de forma segura.',
                                                      style: GoogleFonts.inter(
                                                        color: Colors.white70,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    TextFormField(
                                                      controller:
                                                          passwordController,
                                                      obscureText: true,
                                                      style: GoogleFonts.inter(
                                                          color: Colors.white),
                                                      decoration:
                                                          InputDecoration(
                                                        labelText: 'Contraseña',
                                                        labelStyle:
                                                            GoogleFonts.inter(
                                                          color: Colors.white70,
                                                        ),
                                                        prefixIcon:
                                                            const Icon(
                                                          Icons.lock_outline,
                                                          color:
                                                              Color(0xFFFFD700),
                                                        ),
                                                        filled: true,
                                                        fillColor: Colors.white
                                                            .withOpacity(0.1),
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                          borderSide:
                                                              BorderSide.none,
                                                        ),
                                                        enabledBorder:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                          borderSide:
                                                              BorderSide(
                                                            color: Colors.white
                                                                .withOpacity(
                                                                    0.2),
                                                          ),
                                                        ),
                                                        focusedBorder:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                          borderSide:
                                                              const BorderSide(
                                                            color: Color(
                                                                0xFFFFD700),
                                                            width: 2,
                                                          ),
                                                        ),
                                                      ),
                                                      validator: (value) {
                                                        if (value == null ||
                                                            value.isEmpty) {
                                                          return 'Por favor ingresa tu contraseña';
                                                        }
                                                        return null;
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(
                                                      context)
                                                      .pop(false),
                                                  child: Text(
                                                    'Cancelar',
                                                    style: GoogleFonts.inter(
                                                      color: Colors.white54,
                                                    ),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    if (formKey.currentState!
                                                        .validate()) {
                                                      Navigator.of(context).pop(
                                                          true);
                                                    }
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFFFFD700),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Guardar',
                                                    style: GoogleFonts.inter(
                                                      color:
                                                          const Color(0xFF1a1a2e),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (shouldSave == true &&
                                              passwordController.text.isNotEmpty) {
                                            // Guardar credenciales
                                            await _authService
                                                .saveBiometricCredentials(
                                              email: user.email,
                                              password: passwordController.text,
                                            );

                                            setDialogState(() {
                                              biometricEnabled = true;
                                            });

                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      '$biometricTypeName habilitado exitosamente'),
                                                  backgroundColor:
                                                      const Color(0xFF4CAF50),
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      } else {
                                        // Autenticación cancelada o fallida
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Autenticación biométrica cancelada'),
                                              backgroundColor: Colors.orange,
                                            ),
                                          );
                                        }
                                      }
                                    } else {
                                      // Desactivar: eliminar credenciales
                                      await _authService
                                          .removeBiometricCredentials();
                                      setDialogState(() {
                                        biometricEnabled = false;
                                      });

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                '$biometricTypeName deshabilitado'),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                : null,
                            activeColor: const Color(0xFFFFD700),
                            inactiveThumbColor: Colors.grey,
                            inactiveTrackColor: Colors.grey.withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              CustomButton(
                text: 'Cerrar',
                onPressed: () => Navigator.of(context).pop(),
                color: const Color(0xFFFFD700),
              ),
            ],
          );
        },
      ),
    );
  }

  // Mostrar diálogo de permisos
  void _showPermissionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2541),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFFD700), width: 2),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.security,
              color: Color(0xFFFFD700),
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Permisos de la Aplicación',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPermissionItem(
                context: context,
                permission: Permission.photos,
                title: 'Fotos y Galería',
                description: 'Necesario para seleccionar imágenes de avatar',
              ),
              const SizedBox(height: 16),
              _buildPermissionItem(
                context: context,
                permission: Permission.notification,
                title: 'Notificaciones',
                description: 'Para recibir recordatorios y alertas',
              ),
            ],
          ),
        ),
        actions: [
          CustomButton(
            text: 'Cerrar',
            onPressed: () => Navigator.of(context).pop(),
            color: const Color(0xFFFFD700),
          ),
        ],
      ),
    );
  }
  
  // Item de permiso
  Widget _buildPermissionItem({
    required BuildContext context,
    required Permission permission,
    required String title,
    required String description,
  }) {
    return FutureBuilder<PermissionStatus>(
      future: permission.status,
      builder: (context, snapshot) {
        final status = snapshot.data ?? PermissionStatus.denied;
        final isGranted = status.isGranted;
        final isPermanentlyDenied = status.isPermanentlyDenied;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2C3E50).withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isGranted
                  ? Colors.green.withOpacity(0.5)
                  : isPermanentlyDenied
                      ? Colors.red.withOpacity(0.5)
                      : Colors.orange.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isGranted 
                        ? Icons.check_circle 
                        : isPermanentlyDenied 
                            ? Icons.error 
                            : Icons.warning,
                    color: isGranted 
                        ? Colors.green 
                        : isPermanentlyDenied 
                            ? Colors.red 
                            : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (!isGranted)
                    Row(
                      children: [
                        TextButton(
                          onPressed: () async {
                            final result = await permission.request();
                            if (mounted) {
                              if (result.isGranted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✅ Permiso otorgado'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else if (result.isPermanentlyDenied) {
                                // Si está permanentemente denegado, ofrecer abrir configuración
                                final shouldOpen = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Permiso denegado'),
                                    content: Text(
                                      'El permiso $title está permanentemente denegado. '
                                      '¿Deseas abrir la configuración para habilitarlo?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text('Abrir configuración'),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (shouldOpen == true) {
                                  await openAppSettings();
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('❌ Permiso denegado. Intenta nuevamente o habilítalo en Configuración'),
                                    backgroundColor: Colors.orange,
                                    duration: Duration(seconds: 4),
                                  ),
                                );
                              }
                              Navigator.of(context).pop();
                              _showPermissionsDialog(context); // Recargar
                            }
                          },
                          child: const Text(
                            'Solicitar',
                            style: TextStyle(color: Color(0xFFFFD700)),
                          ),
                        ),
                        if (status.isPermanentlyDenied)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: TextButton(
                              onPressed: () async {
                                await openAppSettings();
                                if (mounted) {
                                  Navigator.of(context).pop();
                                  _showPermissionsDialog(context);
                                }
                              },
                              child: const Text(
                                'Configuración',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Botón con tamaño optimizado
  Widget _buildCompactButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
    int? notificationCount,
  }) {
    final buttonColor = color ?? const Color(0xFFFFD700);
    final showBadge = notificationCount != null && notificationCount > 0;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            buttonColor.withOpacity(0.15),
            buttonColor.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: buttonColor.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: buttonColor.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      icon,
                      color: Colors.white,
                      size: 18,
                    ),
                    if (showBadge)
                      Positioned(
                        right: -8,
                        top: -8,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF1C2541),
                              width: 1.5,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                            child: Text(
                              notificationCount > 99 ? '99+' : '$notificationCount',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    text,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Botón de Suscripciones con información de fechas cuando NO es FREE
  Widget _buildSubscriptionButton(BuildContext context) {
    final subscriptionService = SubscriptionService();
    final isFreeUser = subscriptionService.isFreeUser;
    final expiryDate = subscriptionService.subscriptionExpiryDate;
    
    return FutureBuilder<DateTime?>(
      future: subscriptionService.getSubscriptionStartDate(),
      builder: (context, snapshot) {
        final startDate = snapshot.data;
        
        String buttonText = 'Suscripciones';
        String? subtitle;
        
        // Si NO es FREE, mostrar fechas
        if (!isFreeUser && expiryDate != null) {
          final now = DateTime.now();
          final startDateStr = startDate != null 
              ? '${startDate.day}/${startDate.month}/${startDate.year}'
              : 'N/A';
          final expiryDateStr = '${expiryDate.day}/${expiryDate.month}/${expiryDate.year}';
          
          if (expiryDate.isAfter(now)) {
            subtitle = 'Válido hasta $expiryDateStr';
          } else {
            subtitle = 'Expirado el $expiryDateStr';
          }
        }
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFFD700).withOpacity(0.15),
                const Color(0xFFFFD700).withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFD700).withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.card_membership,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            buttonText,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    final buttonColor = color ?? const Color(0xFFFFD700);
    
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 60),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: buttonColor.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 0,
          ),
        ],
      ),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: buttonColor,
          side: BorderSide(color: buttonColor, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: const Color(0xFFFFD700),
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildLegalSection() {
    return FutureBuilder<Map<String, String>>(
      future: LegalLinksService.getLegalLinks(),
      builder: (context, snapshot) {
        final links = snapshot.data ?? {};
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Información Legal',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFD700),
                ),
              ),
              const SizedBox(height: 12),
              _buildLegalLink(
                'Política de Privacidad',
                links['privacy_policy'] ?? LegalLinksService.defaultLinks['privacy_policy']!,
                Icons.privacy_tip,
              ),
              const SizedBox(height: 8),
              _buildLegalLink(
                'Términos y Condiciones',
                links['terms'] ?? LegalLinksService.defaultLinks['terms']!,
                Icons.description,
              ),
              const SizedBox(height: 8),
              _buildLegalLink(
                'Política de Cookies',
                links['cookies'] ?? LegalLinksService.defaultLinks['cookies']!,
                Icons.cookie,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegalLink(String title, String url, IconData icon) {
    return InkWell(
      onTap: () async {
        try {
          // Asegurar que la URL tenga el protocolo https://
          String finalUrl = url.trim();
          if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
            finalUrl = 'https://$finalUrl';
          }
          
          final uri = Uri.parse(finalUrl);
          
          // Intentar abrir con platformDefault primero (más compatible en Android)
          try {
            final launched = await launchUrl(
              uri,
              mode: LaunchMode.platformDefault,
            );
            
            if (!launched) {
              // Si falla, intentar con externalApplication
              await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
            }
          } catch (launchError) {
            // Si falla platformDefault, intentar externalApplication
            try {
              await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('No se pudo abrir el enlace. Verifica tu conexión a internet.'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al abrir el enlace. Verifica tu conexión a internet.'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFFD700), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ),
            const Icon(
              Icons.open_in_new,
              color: Colors.white54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter para el campo cuántico animado
class _QuantumFieldPainter extends CustomPainter {
  final double rotationAngle;
  
  _QuantumFieldPainter(this.rotationAngle);
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Partículas flotantes
    _drawParticles(canvas, size);
    
    // Ondas cuánticas concentradas arriba
    _drawQuantumWaves(canvas, center);
  }
  
  void _drawParticles(Canvas canvas, Size size) {
    final particlePaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.3);
    
    // Generar partículas aleatorias pero consistentes
    final random = math.Random(42);
    for (int i = 0; i < 80; i++) {
      final x = (random.nextDouble() * size.width);
      final y = (random.nextDouble() * size.height);
      final particleSize = random.nextDouble() * 3 + 1;
      
      canvas.drawCircle(
        Offset(x, y),
        particleSize,
        particlePaint,
      );
    }
  }
  
  void _drawQuantumWaves(Canvas canvas, Offset center) {
    final wavePaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Ondas concentradas en la parte superior
    final topCenter = Offset(center.dx, center.dy * 0.3);
    
    for (int i = 1; i <= 6; i++) {
      final radius = 30.0 + (i * 20.0);
      final angle = rotationAngle + (i * 0.5);
      
      for (int j = 0; j < 3; j++) {
        final offsetAngle = angle + (j * (2 * math.pi / 3));
        final waveOffset = Offset(
          topCenter.dx + math.cos(offsetAngle) * 50,
          topCenter.dy + math.sin(offsetAngle) * 30,
        );
        
        canvas.drawCircle(waveOffset, radius, wavePaint);
      }
    }
    
    // Espirales cuánticas
    final spiralPaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    for (int i = 0; i < 2; i++) {
      final path = Path();
      final startRadius = 20.0;
      final turns = 1.5;
      
      for (double angle = 0; angle < turns * 2 * math.pi; angle += 0.1) {
        final radius = startRadius + (angle * 3);
        final x = topCenter.dx + radius * math.cos(angle + rotationAngle + (i * math.pi));
        final y = topCenter.dy + radius * math.sin(angle + rotationAngle + (i * math.pi));
        
        if (angle == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      
      canvas.drawPath(path, spiralPaint);
    }
  }
  
  @override
  bool shouldRepaint(_QuantumFieldPainter oldDelegate) {
    return oldDelegate.rotationAngle != rotationAngle;
  }
}
