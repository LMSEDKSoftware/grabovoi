import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/glow_background.dart';
import '../../models/code_model.dart';
import '../codes/repetition_session_screen.dart';
import '../../services/ai/openai_codes_service.dart';

class BibliotecaScreen extends StatefulWidget {
  const BibliotecaScreen({super.key});

  @override
  State<BibliotecaScreen> createState() => _BibliotecaScreenState();
}

class _BibliotecaScreenState extends State<BibliotecaScreen> {
  List<CodigoGrabovoi> codigos = [];
  List<CodigoGrabovoi> filtrados = [];
  bool isLoading = true;
  String _query = '';
  String _filtroCategoria = 'Todos';
  String _tab = 'Todos'; // Todos | Favoritos | Popularidad
  final List<String> _categorias = const [
    'Todos', 'Salud', 'Abundancia', 'Protección', 'Amor', 'Armonía', 'Sanación'
  ];

  Set<String> _favoritos = {};
  Map<String, int> _popularidad = {};

  late final OpenAICodesService _openai;

  @override
  void initState() {
    super.initState();
    _openai = OpenAICodesService(
      apiKey: const String.fromEnvironment('OPENAI_API_KEY', defaultValue: ''),
    );
    _restoreState().then((_) => _loadCodigos());
  }

  Future<void> _restoreState() async {
    final prefs = await SharedPreferences.getInstance();
    _favoritos = prefs.getStringList('favoritos')?.toSet() ?? {};
    final popJson = prefs.getString('popularidad');
    if (popJson != null) {
      final map = json.decode(popJson) as Map<String, dynamic>;
      _popularidad = map.map((k, v) => MapEntry(k, (v as num).toInt()));
    }
  }

  Future<void> _persistFavoritos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favoritos', _favoritos.toList());
  }

  Future<void> _persistPopularidad() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('popularidad', json.encode(_popularidad));
  }

  Future<void> _loadCodigos() async {
    try {
      final String jsonString = await rootBundle.loadString('lib/data/codigos_grabovoi.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      setState(() {
        codigos = jsonList.map((json) => CodigoGrabovoi.fromJson(json)).toList();
        if (codigos.length > 100) {
          codigos = codigos.take(100).toList();
        }
        filtrados = List.from(codigos);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint('Error cargando códigos: $e');
    }
  }

  void _aplicarFiltros() {
    List<CodigoGrabovoi> base = List.from(codigos);
    if (_filtroCategoria != 'Todos') {
      base = base.where((c) => c.categoria.toLowerCase() == _filtroCategoria.toLowerCase()).toList();
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      base = base.where((c) =>
        c.codigo.toLowerCase().contains(q) ||
        c.nombre.toLowerCase().contains(q) ||
        c.descripcion.toLowerCase().contains(q)
      ).toList();
    }

    if (_tab == 'Favoritos') {
      base = base.where((c) => _favoritos.contains(c.codigo)).toList();
    }

    setState(() {
      filtrados = base;
    });
  }

  Future<void> _buscarConOpenAI() async {
    if (_query.trim().isEmpty) return;
    final sugeridos = await _openai.sugerirCodigosPorIntencion(_query.trim());
    if (!mounted) return;
    if (sugeridos.isEmpty) {
      _mostrarDialogoSugerirPilotaje();
      return;
    }
    
    // Mostrar códigos sugeridos como seleccionables
    _mostrarCodigosSugeridos(sugeridos);
  }

  void _mostrarCodigosSugeridos(List<Map<String, String>> sugeridos) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C2541),
        title: Text(
          'Códigos Sugeridos para "${_query}"',
          style: GoogleFonts.inter(color: Colors.white, fontSize: 18),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sugeridos.length,
            itemBuilder: (context, index) {
              final sugerido = sugeridos[index];
              return Card(
                color: Colors.white.withOpacity(0.05),
                child: ListTile(
                  title: Text(
                    sugerido['codigo']!,
                    style: GoogleFonts.spaceMono(
                      color: const Color(0xFFFFD700),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    sugerido['descripcion']!,
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.arrow_forward, color: Color(0xFFFFD700)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _iniciarPilotajeConCodigo(sugerido['codigo']!, sugerido['descripcion']!);
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar', style: TextStyle(color: Color(0xFFFFD700))),
          ),
        ],
      ),
    );
  }

  void _iniciarPilotajeConCodigo(String codigo, String descripcion) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RepetitionSessionScreen(
          codigo: codigo,
          nombre: descripcion,
        ),
      ),
    );
  }

  void _mostrarDialogoSugerirPilotaje() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C2541),
        title: Text('Crea tu propio pilotaje', style: GoogleFonts.inter(color: Colors.white)),
        content: Text(
          'No encontramos resultados entre los 100 códigos.\nPuedes crear tu propio pilotaje basado en tu intención.',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar', style: TextStyle(color: Color(0xFFFFD700))),
          ),
        ],
      ),
    );
  }

  void _toggleFavorito(String codigo) {
    setState(() {
      if (_favoritos.contains(codigo)) {
        _favoritos.remove(codigo);
      } else {
        _favoritos.add(codigo);
      }
    });
    _persistFavoritos();
  }

  void _sumarPopularidad(String codigo) {
    _popularidad[codigo] = (_popularidad[codigo] ?? 0) + 1;
    _persistPopularidad();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Biblioteca Sagrada',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFD700),
                        shadows: [
                          Shadow(
                            color: const Color(0xFFFFD700).withOpacity(0.5),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Códigos numéricos de manifestación',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: (v) {
                        _query = v;
                        _aplicarFiltros();
                      },
                      onSubmitted: (_) {
                        if (filtrados.isEmpty) _buscarConOpenAI();
                      },
                      decoration: InputDecoration(
                        hintText: 'Buscar código, intención o categoría...',
                        hintStyle: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                          borderSide: BorderSide(color: Color(0xFFFFD700)),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (final t in const ['Todos', 'Favoritos'])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(t, style: GoogleFonts.inter()),
                              selected: _tab == t,
                              onSelected: (_) {
                                setState(() => _tab = t);
                                _aplicarFiltros();
                              },
                              selectedColor: const Color(0xFFFFD700),
                              backgroundColor: Colors.white.withOpacity(0.08),
                              labelStyle: TextStyle(
                                color: _tab == t ? const Color(0xFF0B132B) : Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categorias.map((cat) {
                          final selected = _filtroCategoria == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(cat),
                              selected: selected,
                              onSelected: (_) {
                                setState(() => _filtroCategoria = cat);
                                _aplicarFiltros();
                              },
                              selectedColor: const Color(0xFFFFD700),
                              backgroundColor: Colors.white.withOpacity(0.08),
                              labelStyle: TextStyle(
                                color: selected ? const Color(0xFF0B132B) : Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFFD700),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filtrados.length,
                        itemBuilder: (context, index) {
                          final codigo = filtrados[index];
                          return _buildCodigoCard(codigo);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodigoCard(CodigoGrabovoi codigo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getCategoryColor(codigo.categoria).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            _sumarPopularidad(codigo.codigo);
            _showCodigoDetail(codigo);
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(codigo.categoria).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        codigo.categoria,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: _getCategoryColor(codigo.categoria),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        codigo.nombre,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        IconButton(
                          onPressed: () => _toggleFavorito(codigo.codigo),
                          icon: Icon(
                            _favoritos.contains(codigo.codigo) ? Icons.favorite : Icons.favorite_border,
                            color: _favoritos.contains(codigo.codigo) ? const Color(0xFFFFD700) : Colors.white70,
                          ),
                        ),
                        Text(
                          'Popularidad: ${_popularidad[codigo.codigo] ?? 0}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  codigo.codigo,
                  style: GoogleFonts.spaceMono(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD700),
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  codigo.descripcion,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'salud':
        return const Color(0xFF4CAF50);
      case 'abundancia':
        return const Color(0xFFFFD700);
      case 'protección':
      case 'proteccion':
        return const Color(0xFF2196F3);
      case 'amor':
        return const Color(0xFFE91E63);
      case 'armonía':
      case 'armonia':
        return const Color(0xFF9C27B0);
      case 'sanación':
      case 'sanacion':
        return const Color(0xFF00BCD4);
      default:
        return const Color(0xFFFFD700);
    }
  }

  void _showCodigoDetail(CodigoGrabovoi codigo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1C2541),
              Color(0xFF0B132B),
            ],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              codigo.nombre,
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFD700),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              codigo.codigo,
              style: GoogleFonts.spaceMono(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFD700),
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              codigo.descripcion,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RepetitionSessionScreen(
                            codigo: codigo.codigo,
                            nombre: codigo.nombre,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: const Color(0xFF0B132B),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(
                      'Iniciar sesión de repetición',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

