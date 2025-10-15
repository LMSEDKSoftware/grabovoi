import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  int _currentQuestion = 0;
  final Map<String, dynamic> _answers = {};

  final List<Question> _questions = [
    Question(
      id: 'main_goal',
      text: '¿Cuál es tu objetivo principal?',
      options: [
        'Mejorar mi salud y bienestar',
        'Atraer abundancia y prosperidad',
        'Fortalecer mis relaciones',
        'Crecimiento personal y espiritual',
        'Encontrar paz y armonía',
      ],
    ),
    Question(
      id: 'experience_level',
      text: '¿Tienes experiencia con prácticas de meditación o manifestación?',
      options: [
        'Soy principiante',
        'Tengo algo de experiencia',
        'Soy practicante regular',
        'Soy experto',
      ],
    ),
    Question(
      id: 'time_available',
      text: '¿Cuánto tiempo puedes dedicar diariamente?',
      options: [
        '5 minutos o menos',
        '10-15 minutos',
        '20-30 minutos',
        'Más de 30 minutos',
      ],
    ),
    Question(
      id: 'preferred_practices',
      text: '¿Qué prácticas te interesan más? (Puedes seleccionar varias)',
      options: [
        'Meditación guiada',
        'Ejercicios de respiración',
        'Visualización',
        'Journaling',
        'Afirmaciones',
      ],
      allowMultiple: true,
    ),
  ];

  void _answerQuestion(dynamic answer) {
    setState(() {
      _answers[_questions[_currentQuestion].id] = answer;
      
      if (_currentQuestion < _questions.length - 1) {
        _currentQuestion++;
      } else {
        _completeQuestionnaire();
      }
    });
  }

  Future<void> _completeQuestionnaire() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('questionnaire_answers', _answers.toString());
    await prefs.setBool('has_completed_questionnaire', true);
    
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      await authProvider.signInAnonymously();
    }
    
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentQuestion];
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personaliza tu experiencia'),
        leading: _currentQuestion > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _currentQuestion--;
                  });
                },
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: (_currentQuestion + 1) / _questions.length,
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Pregunta ${_currentQuestion + 1} de ${_questions.length}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                question.text,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: question.allowMultiple
                    ? _buildMultipleChoiceOptions(question)
                    : _buildSingleChoiceOptions(question),
              ),
              if (question.allowMultiple)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_answers[question.id] != null &&
                          (_answers[question.id] as List).isNotEmpty) {
                        _answerQuestion(_answers[question.id]);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Continuar'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleChoiceOptions(Question question) {
    return ListView.builder(
      itemCount: question.options.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(question.options[index]),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _answerQuestion(question.options[index]),
          ),
        );
      },
    );
  }

  Widget _buildMultipleChoiceOptions(Question question) {
    final selectedOptions = _answers[question.id] as List<String>? ?? [];
    
    return ListView.builder(
      itemCount: question.options.length,
      itemBuilder: (context, index) {
        final option = question.options[index];
        final isSelected = selectedOptions.contains(option);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : null,
          child: CheckboxListTile(
            title: Text(option),
            value: isSelected,
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  selectedOptions.add(option);
                } else {
                  selectedOptions.remove(option);
                }
                _answers[question.id] = selectedOptions;
              });
            },
          ),
        );
      },
    );
  }
}

class Question {
  final String id;
  final String text;
  final List<String> options;
  final bool allowMultiple;

  Question({
    required this.id,
    required this.text,
    required this.options,
    this.allowMultiple = false,
  });
}

