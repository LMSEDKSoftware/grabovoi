import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/custom_button.dart';
import '../../services/user_progress_service.dart';
import '../../services/auth_service_simple.dart';
import '../../services/permissions_service.dart';
import '../../main.dart';

class UserAssessmentScreen extends StatefulWidget {
  const UserAssessmentScreen({super.key});

  @override
  State<UserAssessmentScreen> createState() => _UserAssessmentScreenState();
}

class _UserAssessmentScreenState extends State<UserAssessmentScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final AuthServiceSimple _authService = AuthServiceSimple();
  final UserProgressService _progressService = UserProgressService();
  bool _hasShownModal = false;

  // Respuestas de la encuesta
  String _knowledgeLevel = '';
  final List<String> _goals = [];
  String _experienceLevel = '';
  String _timeAvailable = '';
  final List<String> _preferences = [];
  String _motivation = '';

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Conocimiento sobre Secuencias Gravitacionales',
      'subtitle': '¿Cuál es tu nivel de conocimiento sobre las secuencias de Grigori Grabovoi?',
      'type': 'single_choice',
      'options': [
        {
          'value': 'beginner',
          'label': 'Principiante',
          'description': 'Nunca he usado secuencias gravitacionales o las conozco muy poco',
          'icon': Icons.school_outlined,
        },
        {
          'value': 'intermediate',
          'label': 'Intermedio',
          'description': 'He practicado algunas veces y conozco los conceptos básicos',
          'icon': Icons.trending_up,
        },
        {
          'value': 'advanced',
          'label': 'Avanzado',
          'description': 'Tengo experiencia significativa con las secuencias gravitacionales',
          'icon': Icons.psychology,
        },
      ],
    },
    {
      'title': 'Objetivos Personales',
      'subtitle': '¿Qué te gustaría lograr con las secuencias de Grabovoi?',
      'type': 'multiple_choice',
      'options': [
        {
          'value': 'salud',
          'text': 'Mejorar la salud',
          'description': 'Sanación física y mental',
          'icon': Icons.favorite,
        },
        {
          'value': 'abundancia',
          'text': 'Atraer abundancia',
          'description': 'Prosperidad económica y material',
          'icon': Icons.attach_money,
        },
        {
          'value': 'amor',
          'text': 'Encontrar amor',
          'description': 'Relaciones armoniosas y amor verdadero',
          'icon': Icons.favorite_border,
        },
        {
          'value': 'proteccion',
          'text': 'Protección energética',
          'description': 'Protegerte de energías negativas',
          'icon': Icons.shield,
        },
        {
          'value': 'crecimiento',
          'text': 'Crecimiento espiritual',
          'description': 'Desarrollo personal y espiritual',
          'icon': Icons.self_improvement,
        },
        {
          'value': 'paz',
          'text': 'Paz interior',
          'description': 'Tranquilidad y equilibrio emocional',
          'icon': Icons.spa,
        },
      ],
    },
    {
      'title': 'Experiencia con Secuencias',
      'subtitle': '¿Has trabajado antes con secuencias numéricas o sistemas similares?',
      'type': 'single_choice',
      'options': [
        {
          'value': 'nunca',
          'text': 'Nunca',
          'description': 'Esta es mi primera experiencia con secuencias numéricas',
          'icon': Icons.new_releases,
        },
        {
          'value': 'poco',
          'text': 'Muy poco',
          'description': 'He probado algunas secuencias ocasionalmente',
          'icon': Icons.touch_app,
        },
        {
          'value': 'regular',
          'text': 'Regularmente',
          'description': 'Uso secuencias numéricas de forma regular',
          'icon': Icons.schedule,
        },
        {
          'value': 'experto',
          'text': 'Soy experto',
          'description': 'Tengo amplia experiencia con secuencias numéricas',
          'icon': Icons.psychology,
        },
      ],
    },
    {
      'title': 'Tiempo Disponible',
      'subtitle': '¿Cuánto tiempo puedes dedicar diariamente a la práctica?',
      'type': 'single_choice',
      'options': [
        {
          'value': '5min',
          'text': '5 minutos',
          'description': 'Sesiones cortas y efectivas',
          'icon': Icons.timer,
        },
        {
          'value': '15min',
          'text': '15 minutos',
          'description': 'Tiempo moderado para práctica',
          'icon': Icons.schedule,
        },
        {
          'value': '30min',
          'text': '30 minutos',
          'description': 'Sesiones más profundas',
          'icon': Icons.hourglass_empty,
        },
        {
          'value': '60min',
          'text': '1 hora o más',
          'description': 'Práctica intensiva y completa',
          'icon': Icons.all_inclusive,
        },
      ],
    },
    {
      'title': 'Preferencias de Práctica',
      'subtitle': '¿Qué elementos te gustaría incluir en tu práctica?',
      'type': 'multiple_choice',
      'options': [
        {
          'value': 'audio',
          'text': 'Música de fondo',
          'description': 'Frecuencias y sonidos relajantes',
          'icon': Icons.music_note,
        },
        {
          'value': 'meditacion',
          'text': 'Meditación guiada',
          'description': 'Instrucciones paso a paso',
          'icon': Icons.self_improvement,
        },
        {
          'value': 'visualizacion',
          'text': 'Visualización',
          'description': 'Imágenes mentales y visualizaciones',
          'icon': Icons.visibility,
        },
        {
          'value': 'respiración',
          'text': 'Técnicas de respiración',
          'description': 'Ejercicios de respiración consciente',
          'icon': Icons.air,
        },
        {
          'value': 'afirmaciones',
          'text': 'Afirmaciones',
          'description': 'Frases positivas y afirmaciones',
          'icon': Icons.record_voice_over,
        },
        {
          'value': 'seguimiento',
          'text': 'Seguimiento de progreso',
          'description': 'Estadísticas y evolución personal',
          'icon': Icons.trending_up,
        },
      ],
    },
    {
      'title': 'Motivación Principal',
      'subtitle': '¿Qué te motiva más a usar las secuencias de Grabovoi?',
      'type': 'single_choice',
      'options': [
        {
          'value': 'curiosidad',
          'text': 'Curiosidad',
          'description': 'Quiero explorar algo nuevo e interesante',
          'icon': Icons.explore,
        },
        {
          'value': 'necesidad',
          'text': 'Necesidad específica',
          'description': 'Tengo un problema o situación que resolver',
          'icon': Icons.help,
        },
        {
          'value': 'crecimiento',
          'text': 'Crecimiento personal',
          'description': 'Busco desarrollo y evolución personal',
          'icon': Icons.trending_up,
        },
        {
          'value': 'bienestar',
          'text': 'Bienestar general',
          'description': 'Quiero mejorar mi calidad de vida',
          'icon': Icons.spa,
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    // Mostrar modal de confirmación al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showAssessmentModal();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Mostrar modal de confirmación para la evaluación
  Future<void> _showAssessmentModal() async {
    if (_hasShownModal) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2541),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: const Color(0xFFFFD700).withOpacity(0.5),
            width: 2,
          ),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: Color(0xFFFFD700),
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Evaluación Personalizada',
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFFFD700),
                  fontSize: 22,
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFFFD700),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Esta evaluación es OBLIGATORIA para personalizar tu experiencia con las secuencias de Grabovoi.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFFFFD700),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '¿Por qué es importante?',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildModalBulletPoint(
                'Personaliza tu experiencia según tu nivel de conocimiento',
              ),
              _buildModalBulletPoint(
                'Recomienda secuencias y prácticas adecuadas para ti',
              ),
              _buildModalBulletPoint(
                'Ajusta el contenido según tus objetivos personales',
              ),
              _buildModalBulletPoint(
                'Optimiza tu tiempo y práctica diaria',
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Comenzar Evaluación',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _hasShownModal = true;
      });
    } else {
      // Si el usuario cancela, salir de la pantalla
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Widget _buildModalBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFFFFD700),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeAssessment();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeAssessment() async {
    // Validar que todos los campos estén completos
    if (!_isAssessmentValid()) {
      _showValidationError();
      return;
    }

    try {
      // Guardar respuestas del usuario
      final assessmentData = {
        'knowledge_level': _knowledgeLevel,
        'goals': _goals,
        'experience_level': _experienceLevel,
        'time_available': _timeAvailable,
        'preferences': _preferences,
        'motivation': _motivation,
        'completed_at': DateTime.now().toIso8601String(),
        'is_complete': true, // Marcar como completa
      };

      print('💾 Guardando evaluación completa: $assessmentData');

      // Guardar en el progreso del usuario
      await _progressService.saveUserAssessment(assessmentData);

      print('✅ Evaluación guardada exitosamente');

      // Solicitar permisos antes de navegar a MainNavigation
      await PermissionsService().requestInitialPermissions();

      // Después de completar la evaluación, navegar a MainNavigation
      // El WelcomeModal y MuralModal se mostrarán automáticamente desde HomeScreen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      }
    } catch (e) {
      print('❌ Error guardando evaluación: $e');
      _showErrorDialog('Error al guardar la evaluación. Por favor, inténtalo de nuevo.');
    }
  }

  /// Validar que la evaluación esté completa
  bool _isAssessmentValid() {
    return _knowledgeLevel.isNotEmpty &&
           _goals.isNotEmpty &&
           _experienceLevel.isNotEmpty &&
           _timeAvailable.isNotEmpty &&
           _preferences.isNotEmpty &&
           _motivation.isNotEmpty;
  }

  /// Mostrar error de validación
  void _showValidationError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2541),
        title: Text(
          'Evaluación Incompleta',
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFFFD700),
            fontSize: 20,
          ),
        ),
        content: Text(
          'Por favor completa todas las preguntas antes de continuar. Esta evaluación es necesaria para personalizar tu experiencia con las secuencias de Grabovoi.',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Entendido',
              style: GoogleFonts.inter(
                color: const Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Mostrar diálogo de error
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2541),
        title: Text(
          'Error',
          style: GoogleFonts.playfairDisplay(
            color: Colors.red,
            fontSize: 20,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Reintentar',
              style: GoogleFonts.inter(
                color: const Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header con progreso
              _buildHeader(),
              
              // Contenido de la encuesta
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index]);
                  },
                ),
              ),
              
              // Navegación removida según solicitud
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Progreso
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: (_currentPage + 1) / _pages.length,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${_currentPage + 1}/${_pages.length}',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Título de la página actual
          Text(
            _pages[_currentPage]['title'],
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFFD700),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Subtítulo
          Text(
            _pages[_currentPage]['subtitle'],
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPage(Map<String, dynamic> page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // Esfera dorada removida según solicitud
            const SizedBox(height: 20),
            
            // Opciones
            ...page['options'].map<Widget>((option) => _buildOption(option, page['type'])),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(Map<String, dynamic> option, String type) {
    final isSelected = type == 'single_choice' 
        ? _getSingleSelection() == option['value']
        : _getMultipleSelection().contains(option['value']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectOption(option['value'], type),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? const Color(0xFFFFD700).withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected 
                    ? const Color(0xFFFFD700)
                    : Colors.white.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Icono
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? const Color(0xFFFFD700)
                        : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    option['icon'],
                    color: isSelected ? Colors.black : Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Contenido
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option['text'],
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? const Color(0xFFFFD700) : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        option['description'],
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Indicador de selección
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFFFFD700),
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigation() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (_currentPage > 0) ...[
            Expanded(
              child: CustomButton(
                text: 'Anterior',
                onPressed: _previousPage,
                isOutlined: true,
                icon: Icons.arrow_back,
              ),
            ),
            const SizedBox(width: 16),
          ],
          
          Expanded(
            flex: _currentPage > 0 ? 1 : 2,
            child: CustomButton(
              text: _currentPage == _pages.length - 1 ? 'Completar' : 'Siguiente',
              onPressed: _canProceed() ? _nextPage : null,
              icon: _currentPage == _pages.length - 1 ? Icons.check : Icons.arrow_forward,
            ),
          ),
        ],
      ),
    );
  }

  void _selectOption(String value, String type) {
    setState(() {
      if (type == 'single_choice') {
        _setSingleSelection(value);
      } else {
        _toggleMultipleSelection(value);
      }
    });
    
    // Avanzar automáticamente a la siguiente pregunta
    if (_currentPage < _pages.length - 1) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _nextPage();
      });
    } else {
      // Si es la última pregunta, completar la evaluación
      Future.delayed(const Duration(milliseconds: 300), () {
        _completeAssessment();
      });
    }
  }

  void _setSingleSelection(String value) {
    switch (_currentPage) {
      case 0:
        _knowledgeLevel = value;
        break;
      case 2:
        _experienceLevel = value;
        break;
      case 3:
        _timeAvailable = value;
        break;
      case 5:
        _motivation = value;
        break;
    }
  }

  String _getSingleSelection() {
    switch (_currentPage) {
      case 0:
        return _knowledgeLevel;
      case 2:
        return _experienceLevel;
      case 3:
        return _timeAvailable;
      case 5:
        return _motivation;
      default:
        return '';
    }
  }

  void _toggleMultipleSelection(String value) {
    switch (_currentPage) {
      case 1:
        if (_goals.contains(value)) {
          _goals.remove(value);
        } else {
          _goals.add(value);
        }
        break;
      case 4:
        if (_preferences.contains(value)) {
          _preferences.remove(value);
        } else {
          _preferences.add(value);
        }
        break;
    }
  }

  List<String> _getMultipleSelection() {
    switch (_currentPage) {
      case 1:
        return _goals;
      case 4:
        return _preferences;
      default:
        return [];
    }
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 0:
        return _knowledgeLevel.isNotEmpty;
      case 1:
        return _goals.isNotEmpty;
      case 2:
        return _experienceLevel.isNotEmpty;
      case 3:
        return _timeAvailable.isNotEmpty;
      case 4:
        return _preferences.isNotEmpty;
      case 5:
        return _motivation.isNotEmpty;
      default:
        return false;
    }
  }
}
