import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/journal_entry.dart';
import '../../providers/journal_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/codes_provider.dart';

class JournalEntryScreen extends StatefulWidget {
  final String? entryId;

  const JournalEntryScreen({super.key, this.entryId});

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  final _intentionController = TextEditingController();
  final _sensationsController = TextEditingController();
  final _gratitudeController = TextEditingController();
  final _sleepHoursController = TextEditingController(text: '8');
  
  String? _selectedCode;
  String _selectedMood = '😌 Tranquilo';
  bool _exercisedToday = false;
  
  JournalEntry? _existingEntry;
  bool _isLoading = true;

  final List<Map<String, String>> _moodOptions = [
    {'emoji': '😀', 'label': 'Feliz'},
    {'emoji': '😌', 'label': 'Tranquilo'},
    {'emoji': '⚡', 'label': 'Energizado'},
    {'emoji': '🙏', 'label': 'Grato'},
    {'emoji': '😐', 'label': 'Neutral'},
    {'emoji': '😴', 'label': 'Cansado'},
    {'emoji': '😩', 'label': 'Estresado'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.entryId != null) {
      _loadEntry();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadEntry() async {
    final entry = await context.read<JournalProvider>().getEntryById(widget.entryId!);
    if (entry != null && mounted) {
      setState(() {
        _existingEntry = entry;
        _intentionController.text = entry.intention ?? '';
        _sensationsController.text = entry.reflection ?? '';
        _gratitudeController.text = entry.notes ?? '';
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _intentionController.dispose();
    _sensationsController.dispose();
    _gratitudeController.dispose();
    _sleepHoursController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.getUserId();
    
    if (userId == null) return;

    final entry = JournalEntry(
      id: _existingEntry?.id ?? const Uuid().v4(),
      date: _existingEntry?.date ?? DateTime.now(),
      intention: _intentionController.text.isNotEmpty ? _intentionController.text : null,
      reflection: _sensationsController.text.isNotEmpty ? _sensationsController.text : null,
      gratitudes: _gratitudeController.text.isNotEmpty ? [_gratitudeController.text] : [],
      moodRatings: {
        'mood': _moodOptions.indexWhere((m) => m['label'] == _selectedMood.split(' ')[1]) + 1,
        'sleep': int.tryParse(_sleepHoursController.text) ?? 8,
        'exercise': _exercisedToday ? 1 : 0,
      },
      notes: _selectedCode,
    );

    try {
      await context.read<JournalProvider>().saveEntry(entry, userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entrada guardada exitosamente'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F23),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF8B5CF6),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEC4899).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFEC4899).withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.calendar_today,
                color: Color(0xFFEC4899),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Nueva Entrada',
              style: TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF94A3B8)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Color(0xFF8B5CF6)),
            onPressed: _saveEntry,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildCodeSection(),
            const SizedBox(height: 24),
            _buildIntentionSection(),
            const SizedBox(height: 24),
            _buildMoodSection(),
            const SizedBox(height: 24),
            _buildSensationsSection(),
            const SizedBox(height: 24),
            _buildSleepSection(),
            const SizedBox(height: 24),
            _buildGratitudeSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFEC4899).withOpacity(0.1),
            const Color(0xFF8B5CF6).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFEC4899).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Registra tu práctica de hoy',
            style: TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Completa tu diario místico y observa tu evolución',
            style: TextStyle(
              color: const Color(0xFF94A3B8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeSection() {
    return Consumer<CodesProvider>(
      builder: (context, codesProvider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Código Utilizado (opcional)',
              style: TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF1A1A2E),
                  width: 1,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCode,
                  hint: const Text(
                    'Selecciona un código',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 16,
                    ),
                  ),
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  dropdownColor: const Color(0xFF16213E),
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 16,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: '520',
                      child: Text('520 - Sanación física y emocional'),
                    ),
                    const DropdownMenuItem(
                      value: '318',
                      child: Text('318 - Prosperidad y abundancia'),
                    ),
                    const DropdownMenuItem(
                      value: '741',
                      child: Text('741 - Protección energética'),
                    ),
                    const DropdownMenuItem(
                      value: '888',
                      child: Text('888 - Manifestación acelerada'),
                    ),
                    const DropdownMenuItem(
                      value: '123',
                      child: Text('123 - Presencia del Creador'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCode = value;
                    });
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIntentionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Intención',
              style: TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF1A1A2E),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _intentionController,
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 16,
            ),
            decoration: const InputDecoration(
              hintText: '¿Qué deseas manifestar o trabajar hoy?',
              hintStyle: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildMoodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estado de Ánimo',
          style: TextStyle(
            color: Color(0xFFE2E8F0),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF1A1A2E),
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedMood,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              dropdownColor: const Color(0xFF16213E),
              style: const TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 16,
              ),
              items: _moodOptions.map((mood) {
                return DropdownMenuItem<String>(
                  value: '${mood['emoji']} ${mood['label']}',
                  child: Row(
                    children: [
                      Text(
                        mood['emoji']!,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(mood['label']!),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMood = value!;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSensationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sensaciones y Resultados',
          style: TextStyle(
            color: Color(0xFFE2E8F0),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF1A1A2E),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _sensationsController,
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 16,
            ),
            decoration: const InputDecoration(
              hintText: 'Describe cómo te sientes durante y después de la práctica...',
              hintStyle: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
            maxLines: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildSleepSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Horas de Sueño',
          style: TextStyle(
            color: Color(0xFFE2E8F0),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF1A1A2E),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _sleepHoursController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 16,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF1A1A2E),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _exercisedToday,
                      onChanged: (value) {
                        setState(() {
                          _exercisedToday = value ?? false;
                        });
                      },
                      activeColor: const Color(0xFF8B5CF6),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Hice ejercicio hoy',
                        style: TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGratitudeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gratitud',
          style: TextStyle(
            color: Color(0xFFE2E8F0),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF1A1A2E),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _gratitudeController,
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 16,
            ),
            decoration: const InputDecoration(
              hintText: '¿Por qué estás agradecido/a hoy?',
              hintStyle: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
            maxLines: 4,
          ),
        ),
      ],
    );
  }
}