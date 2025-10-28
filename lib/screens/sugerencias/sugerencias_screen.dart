import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/sugerencia_codigo_model.dart';
import '../../services/sugerencias_codigos_service.dart';
import '../../widgets/sugerencia_codigo_widget.dart';
import '../../config/supabase_config.dart';

class SugerenciasScreen extends StatefulWidget {
  const SugerenciasScreen({super.key});

  @override
  State<SugerenciasScreen> createState() => _SugerenciasScreenState();
}

class _SugerenciasScreenState extends State<SugerenciasScreen> {
  List<SugerenciaCodigo> _sugerencias = [];
  bool _isLoading = true;
  String _filtroEstado = 'todos';

  @override
  void initState() {
    super.initState();
    _cargarSugerencias();
  }

  Future<void> _cargarSugerencias() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final usuarioId = SupabaseConfig.client.auth.currentUser?.id;
      if (usuarioId == null) {
        print('❌ Usuario no autenticado');
        return;
      }

      final sugerencias = await SugerenciasCodigosService.getSugerenciasPorUsuario(usuarioId);
      
      setState(() {
        _sugerencias = sugerencias;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error cargando sugerencias: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<SugerenciaCodigo> _getSugerenciasFiltradas() {
    if (_filtroEstado == 'todos') {
      return _sugerencias;
    }
    return _sugerencias.where((s) => s.estado == _filtroEstado).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Mis Sugerencias',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (String estado) {
              setState(() {
                _filtroEstado = estado;
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'todos',
                child: Text('Todos'),
              ),
              const PopupMenuItem(
                value: 'pendiente',
                child: Text('Pendientes'),
              ),
              const PopupMenuItem(
                value: 'aprobada',
                child: Text('Aprobadas'),
              ),
              const PopupMenuItem(
                value: 'rechazada',
                child: Text('Rechazadas'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
            )
          : _sugerencias.isEmpty
              ? _buildEmptyState()
              : _buildSugerenciasList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes sugerencias aún',
            style: GoogleFonts.inter(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las sugerencias aparecerán cuando la IA encuentre\ncódigos existentes con temas diferentes',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSugerenciasList() {
    final sugerenciasFiltradas = _getSugerenciasFiltradas();
    
    return Column(
      children: [
        // Filtro actual
        if (_filtroEstado != 'todos')
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.filter_list, color: Colors.amber, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Filtro: ${_filtroEstado.toUpperCase()}',
                  style: GoogleFonts.inter(
                    color: Colors.amber,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filtroEstado = 'todos';
                    });
                  },
                  child: Text(
                    'Limpiar',
                    style: GoogleFonts.inter(
                      color: Colors.amber,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // Lista de sugerencias
        Expanded(
          child: ListView.builder(
            itemCount: sugerenciasFiltradas.length,
            itemBuilder: (context, index) {
              final sugerencia = sugerenciasFiltradas[index];
              return SugerenciaCodigoWidget(
                sugerencia: sugerencia,
                onSugerenciaAprobada: () {
                  _cargarSugerencias(); // Recargar la lista
                },
                onSugerenciaRechazada: () {
                  _cargarSugerencias(); // Recargar la lista
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

