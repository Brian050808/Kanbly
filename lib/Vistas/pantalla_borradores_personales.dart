import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelo/tablero.dart';
import '../modelo/tarea.dart';
import '../modelo/borrador_nota.dart';
import '../modelo/usuario.dart';
import '../servicios/firestore_service.dart';
import '../servicios/storage_service.dart';
import '../utilerias/formato_util.dart';
import 'pantalla_visualizador_adjunto.dart';

class PantallaBorradoresPersonales extends StatefulWidget {
  final Tablero tablero;

  const PantallaBorradoresPersonales({
    super.key,
    required this.tablero,
  });

  @override
  State<PantallaBorradoresPersonales> createState() => _PantallaBorradoresPersonalesState();
}

class _PantallaBorradoresPersonalesState extends State<PantallaBorradoresPersonales> {
  final FirestoreService _firestoreService = FirestoreService();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  List<Usuario> _miembrosEquipo = [];
  bool _cargandoMiembros = false;

  static const int _maxTamanoBytes = 10 * 1024 * 1024; // 10 MB

  static const List<Map<String, dynamic>> _coloresEtiqueta = [
    {'nombre': 'Azul Kanbly', 'hex': '0xFF52ABEB', 'color': Color(0xFF52ABEB)},
    {'nombre': 'Verde Turquesa', 'hex': '0xFF63D0A1', 'color': Color(0xFF63D0A1)},
    {'nombre': 'Naranja', 'hex': '0xFFED8936', 'color': Color(0xFFED8936)},
    {'nombre': 'Púrpura', 'hex': '0xFF9F7AEA', 'color': Color(0xFF9F7AEA)},
    {'nombre': 'Coral', 'hex': '0xFFF56565', 'color': Color(0xFFF56565)},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.tablero.esGrupal) {
      _cargarMiembrosTablero();
    }
  }

  Future<void> _cargarMiembrosTablero() async {
    setState(() => _cargandoMiembros = true);
    List<Usuario> lista = [];
    for (String id in widget.tablero.miembrosIds) {
      final u = await _firestoreService.obtenerUsuarioPorId(id);
      if (u != null) {
        lista.add(u);
      }
    }
    if (mounted) {
      setState(() {
        _miembrosEquipo = lista;
        _cargandoMiembros = false;
      });
    }
  }

  /// Verifica borradores con fecha de publicación automatizada cumplida y los publica
  void _verificarBorradoresProgramados(List<BorradorNota> borradores) async {
    final ahora = DateTime.now();
    for (final b in borradores) {
      if (!b.esPublicado &&
          b.fechaPublicacionProgramada != null &&
          b.fechaPublicacionProgramada!.isBefore(ahora)) {
        try {
          await _firestoreService.convertirBorradorATarea(
            borrador: b,
            columnaDestino: b.columnaDestino.isNotEmpty ? b.columnaDestino : 'Pendiente',
            prioridad: b.prioridad,
          );
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color textoPrincipal = Color(0xFF1E293B);
    const Color azulCielo = Color(0xFF52ABEB);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textoPrincipal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Borradores y Notas',
          style: GoogleFonts.inter(
            color: textoPrincipal,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: azulCielo, size: 28),
            tooltip: 'Crear Borrador',
            onPressed: () => _abrirFormularioBorrador(),
          ),
        ],
      ),
      body: Column(
        children: [
          // BANNER INFORMATIVO DEL ESPACIO PERSONAL
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF52ABEB), Color(0xFF63D0A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF52ABEB).withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_clock_outlined, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Espacio Personal: ${widget.tablero.nombre}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Asigna integrantes, prioridad y programa fechas de publicación automática.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // LISTA DE BORRADORES EN TIEMPO REAL DESDE FIRESTORE
          Expanded(
            child: StreamBuilder<List<BorradorNota>>(
              stream: _firestoreService.escucharBorradoresNota(_currentUid, widget.tablero.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: azulCielo));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error al cargar borradores: ${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                final borradores = snapshot.data ?? [];

                if (borradores.isNotEmpty) {
                  _verificarBorradoresProgramados(borradores);
                }

                if (borradores.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_note_rounded, size: 72, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'No tienes borradores en este tablero',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textoPrincipal,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Usa el botón "+" para anotar ideas rápidas, asignar integrantes, definir prioridad o programar tareas.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: azulCielo,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            icon: const Icon(Icons.add_rounded, color: Colors.white),
                            label: const Text('Crear mi primer borrador', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            onPressed: () => _abrirFormularioBorrador(),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: borradores.length,
                  itemBuilder: (context, index) {
                    final borrador = borradores[index];
                    return _tarjetaBorrador(borrador);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF63D0A1),
        icon: const Icon(Icons.note_add_rounded, color: Colors.white),
        label: const Text('Nuevo Borrador', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _abrirFormularioBorrador(),
      ),
    );
  }

  Widget _tarjetaBorrador(BorradorNota borrador) {
    const Color textoPrincipal = Color(0xFF1E293B);
    const Color azulCielo = Color(0xFF52ABEB);
    final colorVal = int.tryParse(borrador.colorHex) ?? 0xFF52ABEB;
    final colorEtiqueta = Color(colorVal);

    final colorPrioridad = FormatoUtil.obtenerColorPorPrioridad(borrador.prioridad);

    Usuario? usuarioAsignado;
    if (borrador.asignadoA != null) {
      final idx = _miembrosEquipo.indexWhere((m) => m.id == borrador.asignadoA);
      if (idx != -1) usuarioAsignado = _miembrosEquipo[idx];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorEtiqueta.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ENCABEZADO DE LA TARJETA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorEtiqueta.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: colorEtiqueta, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    borrador.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: textoPrincipal,
                    ),
                  ),
                ),
                Text(
                  FormatoUtil.formatearFechaHora(borrador.fechaCreacion),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // BADGES COMPACTOS: PRIORIDAD, ASIGNADO Y PUBLICACIÓN PROGRAMADA
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                // BADGE PRIORIDAD
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorPrioridad.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colorPrioridad.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flag_rounded, size: 12, color: colorPrioridad),
                      const SizedBox(width: 4),
                      Text(
                        FormatoUtil.obtenerTextoPrioridad(borrador.prioridad),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorPrioridad),
                      ),
                    ],
                  ),
                ),

                // BADGE ASIGNADO
                if (usuarioAsignado != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: azulCielo.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: azulCielo.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_rounded, size: 12, color: azulCielo),
                        const SizedBox(width: 4),
                        Text(
                          'Asignado: ${usuarioAsignado.nombreCompleto}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: azulCielo),
                        ),
                      ],
                    ),
                  ),

                // BADGE PROGRAMADO
                if (borrador.fechaPublicacionProgramada != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.purple.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.alarm_rounded, size: 12, color: Colors.purple),
                        const SizedBox(width: 4),
                        Text(
                          'Programado: ${FormatoUtil.formatearFechaHora(borrador.fechaPublicacionProgramada!)}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // CUERPO RENDERIZADO DEL CONTENIDO DE LA NOTA
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              borrador.contenido.isNotEmpty ? borrador.contenido : 'Sin notas detalladas.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: borrador.contenido.isNotEmpty ? textoPrincipal : Colors.grey.shade500,
                fontStyle: borrador.contenido.isNotEmpty ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),

          // ARCHIVOS ADJUNTOS EN EL BORRADOR SI EXISTEN
          if (borrador.adjuntos.isNotEmpty) ...[
            const Divider(height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.attach_file_rounded, size: 14, color: Color(0xFF52ABEB)),
                      const SizedBox(width: 4),
                      Text(
                        'Archivos Adjuntos (${borrador.adjuntos.length}):',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textoPrincipal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: borrador.adjuntos.map((adj) {
                      return GestureDetector(
                        onTap: () => PantallaVisualizadorAdjunto.abrir(context, adj),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _obtenerIconoTipoAdjunto(adj.tipo, adj.nombre),
                              const SizedBox(width: 6),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 140),
                                child: Text(
                                  adj.nombre,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textoPrincipal),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 1, thickness: 1),

          // BARRA DE ACCIONES: EDITAR, ELIMINAR Y PUBLICAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF52ABEB)),
                      tooltip: 'Editar borrador',
                      onPressed: () => _abrirFormularioBorrador(borrador: borrador),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                      tooltip: 'Eliminar borrador',
                      onPressed: () => _confirmarEliminacion(borrador),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF63D0A1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.rocket_launch_rounded, size: 16, color: Colors.white),
                  label: const Text(
                    'Publicar Tarea',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  onPressed: () => _mostrarModalPublicarTarea(borrador),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // DIÁLOGO / MODAL REDISEÑADO Y MODERNO PARA CREAR O EDITAR UN BORRADOR
  void _abrirFormularioBorrador({BorradorNota? borrador}) {
    final esEdicion = borrador != null;
    final tituloController = TextEditingController(text: borrador?.titulo ?? '');
    final contenidoController = TextEditingController(text: borrador?.contenido ?? '');
    String colorHexSeleccionado = borrador?.colorHex ?? '0xFF52ABEB';
    String? asignadoA = borrador?.asignadoA;
    DateTime? fechaProgramada = borrador?.fechaPublicacionProgramada;
    String columnaDestino = borrador?.columnaDestino ?? (widget.tablero.columnas.isNotEmpty ? widget.tablero.columnas.first : 'Pendiente');
    int prioridadSeleccionada = borrador?.prioridad ?? 2;

    List<AdjuntoTarea> adjuntosTemporales = List.from(borrador?.adjuntos ?? []);
    bool guardandoBorrador = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final columnasDisponibles = widget.tablero.columnas.isNotEmpty
                ? widget.tablero.columnas
                : const ['Pendiente', 'En progreso', 'Completada'];

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                left: 20, right: 20, top: 18,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ENCABEZADO
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          esEdicion ? 'Editar Borrador' : 'Nuevo Borrador / Nota',
                          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // CAMPO: TÍTULO
                    TextFormField(
                      controller: tituloController,
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                      decoration: InputDecoration(
                        labelText: 'Título del Borrador *',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // CAMPO CONTENIDO
                    TextFormField(
                      controller: contenidoController,
                      minLines: 3,
                      maxLines: 5,
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1E293B), height: 1.4),
                      decoration: InputDecoration(
                        labelText: 'Contenido y Detalles (Opcional)',
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // INTEGRANTE ASIGNADO EN TABLEROS DE EQUIPO
                    if (widget.tablero.esGrupal) ...[
                      Text('Asignar Integrante:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                      const SizedBox(height: 6),
                      _cargandoMiembros
                          ? const LinearProgressIndicator()
                          : DropdownButtonFormField<String?>(
                              initialValue: asignadoA,
                              isExpanded: true,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('Sin asignar', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ),
                                ..._miembrosEquipo.map((m) => DropdownMenuItem<String?>(
                                      value: m.id,
                                      child: Text(m.nombreCompleto, style: const TextStyle(fontSize: 12)),
                                    )),
                              ],
                              onChanged: (val) => setModalState(() => asignadoA = val),
                            ),
                      const SizedBox(height: 14),
                    ],

                    // PRIORIDAD DEL BORRADOR
                    Text('Prioridad:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _botonPrioridadForm(1, 'Baja', const Color(0xFF38A169), prioridadSeleccionada, (v) => setModalState(() => prioridadSeleccionada = v)),
                        _botonPrioridadForm(2, 'Media', const Color(0xFFED8936), prioridadSeleccionada, (v) => setModalState(() => prioridadSeleccionada = v)),
                        _botonPrioridadForm(3, 'Alta', const Color(0xFFE53E3E), prioridadSeleccionada, (v) => setModalState(() => prioridadSeleccionada = v)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // PROGRAMAR FECHA Y HORA DE PUBLICACIÓN AUTOMÁTICA
                    Text('Publicación Automatizada:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.alarm_add_rounded, size: 16, color: Color(0xFF52ABEB)),
                            label: Text(
                              fechaProgramada == null
                                  ? 'Programar Fecha y Hora'
                                  : 'Programado: ${FormatoUtil.formatearFechaHora(fechaProgramada!)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            onPressed: () async {
                              final fecha = await showDatePicker(
                                context: context,
                                initialDate: fechaProgramada ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2030),
                              );
                              if (fecha != null && context.mounted) {
                                final hora = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(fechaProgramada ?? DateTime.now()),
                                );
                                if (hora != null) {
                                  setModalState(() {
                                    fechaProgramada = DateTime(
                                      fecha.year, fecha.month, fecha.day,
                                      hora.hour, hora.minute,
                                    );
                                  });
                                }
                              }
                            },
                          ),
                        ),
                        if (fechaProgramada != null)
                          IconButton(
                            icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 20),
                            onPressed: () => setModalState(() => fechaProgramada = null),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // COLUMNA DESTINO
                    Text('Columna Destino al Publicar:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: columnasDisponibles.map((col) {
                          final seleccionada = columnaDestino == col;
                          return GestureDetector(
                            onTap: () => setModalState(() => columnaDestino = col),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: seleccionada ? const Color(0xFF52ABEB) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: seleccionada ? const Color(0xFF52ABEB) : Colors.grey.shade300),
                              ),
                              child: Text(
                                col,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: seleccionada ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ARCHIVOS ADJUNTOS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Archivos Adjuntos (${adjuntosTemporales.length}):',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                        ),
                        TextButton.icon(
                          onPressed: () => _mostrarMenuAdjuntarEnModal(setModalState, adjuntosTemporales),
                          icon: const Icon(Icons.attach_file_rounded, size: 16, color: Color(0xFF52ABEB)),
                          label: const Text('Adjuntar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF52ABEB))),
                        ),
                      ],
                    ),
                    if (adjuntosTemporales.isNotEmpty)
                      Column(
                        children: adjuntosTemporales.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final adj = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                _obtenerIconoTipoAdjunto(adj.tipo, adj.nombre),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    adj.nombre,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 16, color: Colors.redAccent),
                                  onPressed: () => setModalState(() => adjuntosTemporales.removeAt(idx)),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 14),

                    // SELECTOR DE COLOR ETIQUETA
                    Text('Color de la Nota:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                    const SizedBox(height: 8),
                    Row(
                      children: _coloresEtiqueta.map((c) {
                        final hex = c['hex'] as String;
                        final color = c['color'] as Color;
                        final activo = colorHexSeleccionado == hex;
                        return GestureDetector(
                          onTap: () => setModalState(() => colorHexSeleccionado = hex),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: activo ? Colors.black : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            child: activo ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // BOTÓN GUARDAR
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF52ABEB),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        icon: guardandoBorrador
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.save_rounded, color: Colors.white, size: 18),
                        label: Text(
                          guardandoBorrador ? 'Guardando...' : (esEdicion ? 'Guardar Cambios' : 'Crear Borrador'),
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        onPressed: guardandoBorrador
                            ? null
                            : () async {
                                final titulo = tituloController.text.trim();
                                if (titulo.isEmpty) return;

                                setModalState(() => guardandoBorrador = true);

                                try {
                                  final storageService = StorageService();
                                  List<AdjuntoTarea> adjuntosSubidos = [];

                                  final borradorIdFinal = esEdicion
                                      ? borrador.id
                                      : FirebaseFirestore.instance.collection('borradores_notas').doc().id;

                                  for (final adj in adjuntosTemporales) {
                                    if (adj.url.isNotEmpty && !adj.url.startsWith('http')) {
                                      final urlRemota = await storageService.subirAdjuntoTarea(
                                        filePath: adj.url,
                                        nombreArchivo: adj.nombre,
                                        tareaId: 'draft_$borradorIdFinal',
                                      );
                                      adjuntosSubidos.add(AdjuntoTarea(
                                        id: adj.id,
                                        nombre: adj.nombre,
                                        url: urlRemota,
                                        tipo: adj.tipo,
                                        tamanoBytes: adj.tamanoBytes,
                                        fechaAdjunto: adj.fechaAdjunto,
                                      ));
                                    } else {
                                      adjuntosSubidos.add(adj);
                                    }
                                  }

                                  if (esEdicion) {
                                    final borradorActualizado = borrador.copyWith(
                                      titulo: titulo,
                                      contenido: contenidoController.text.trim(),
                                      colorHex: colorHexSeleccionado,
                                      adjuntos: adjuntosSubidos,
                                      fechaActualizacion: DateTime.now(),
                                      asignadoA: asignadoA,
                                      fechaPublicacionProgramada: fechaProgramada,
                                      columnaDestino: columnaDestino,
                                      prioridad: prioridadSeleccionada,
                                    );
                                    await _firestoreService.actualizarBorradorNota(borradorActualizado);
                                  } else {
                                    final nuevoBorrador = BorradorNota(
                                      id: borradorIdFinal,
                                      usuarioId: _currentUid,
                                      tableroId: widget.tablero.id,
                                      titulo: titulo,
                                      contenido: contenidoController.text.trim(),
                                      fechaCreacion: DateTime.now(),
                                      colorHex: colorHexSeleccionado,
                                      adjuntos: adjuntosSubidos,
                                      asignadoA: asignadoA,
                                      fechaPublicacionProgramada: fechaProgramada,
                                      columnaDestino: columnaDestino,
                                      prioridad: prioridadSeleccionada,
                                    );
                                    await _firestoreService.crearBorradorNota(nuevoBorrador);
                                  }

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                } catch (e) {
                                  setModalState(() => guardandoBorrador = false);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error al guardar borrador: $e')),
                                    );
                                  }
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _botonPrioridadForm(int valor, String texto, Color color, int seleccionada, Function(int) onTap) {
    final activo = seleccionada == valor;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(valor),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: activo ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color, width: activo ? 1.8 : 1),
          ),
          alignment: Alignment.center,
          child: Text(
            texto,
            style: TextStyle(
              color: activo ? Colors.white : const Color(0xFF1E293B),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  // ADJUNTAR ARCHIVO DENTRO DEL MODAL
  void _mostrarMenuAdjuntarEnModal(StateSetter setModalState, List<AdjuntoTarea> listaAdjuntos) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Adjuntar Archivo al Borrador (Máx. 10MB)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFEBF8FF), child: Icon(Icons.image_rounded, color: Color(0xFF52ABEB))),
                  title: const Text('Imagen'),
                  onTap: () {
                    Navigator.pop(context);
                    _seleccionarArchivoParaBorrador(FileType.image, 'imagen', setModalState, listaAdjuntos);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFFFF5F5), child: Icon(Icons.videocam_rounded, color: Colors.redAccent)),
                  title: const Text('Video'),
                  onTap: () {
                    Navigator.pop(context);
                    _seleccionarArchivoParaBorrador(FileType.video, 'video', setModalState, listaAdjuntos);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFF0FDF4), child: Icon(Icons.description_rounded, color: Color(0xFF63D0A1))),
                  title: const Text('Documento / PDF'),
                  onTap: () {
                    Navigator.pop(context);
                    _seleccionarArchivoParaBorrador(FileType.custom, 'documento', setModalState, listaAdjuntos, extensiones: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx', 'pptx', 'ppt']);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _seleccionarArchivoParaBorrador(
    FileType fileType,
    String tipoEtiqueta,
    StateSetter setModalState,
    List<AdjuntoTarea> listaAdjuntos, {
    List<String>? extensiones,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: fileType,
        allowedExtensions: extensiones,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        for (final file in result.files) {
          final tamano = file.size;

          if (tamano > _maxTamanoBytes) {
            final tamanoMB = (tamano / (1024 * 1024)).toStringAsFixed(1);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('El archivo "${file.name}" excede el límite permitido de 10 MB ($tamanoMB MB)'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
            continue;
          }

          String tipoReal = tipoEtiqueta;
          final ext = file.extension?.toLowerCase() ?? '';
          if (['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext)) {
            tipoReal = 'imagen';
          } else if (['mp4', 'mov', 'avi', 'mkv'].contains(ext)) {
            tipoReal = 'video';
          }

          final adjunto = AdjuntoTarea(
            id: FirebaseFirestore.instance.collection('adjuntos').doc().id,
            nombre: file.name,
            url: file.path ?? file.name,
            tipo: tipoReal,
            tamanoBytes: tamano,
            fechaAdjunto: DateTime.now(),
          );

          setModalState(() {
            listaAdjuntos.add(adjunto);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar archivo: $e')),
        );
      }
    }
  }

  Widget _obtenerIconoTipoAdjunto(String tipo, [String? nombre]) {
    final nameLower = (nombre ?? '').toLowerCase();
    final tipoLower = tipo.toLowerCase();

    if (nameLower.endsWith('.pdf')) {
      return const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFD32F2F), size: 18);
    } else if (tipoLower == 'imagen' || ['.jpg', '.jpeg', '.png', '.webp'].any((ext) => nameLower.endsWith(ext))) {
      return const Icon(Icons.image_rounded, color: Color(0xFF52ABEB), size: 18);
    } else if (tipoLower == 'video' || ['.mp4', '.mov', '.avi'].any((ext) => nameLower.endsWith(ext))) {
      return const Icon(Icons.videocam_rounded, color: Colors.redAccent, size: 18);
    }
    return const Icon(Icons.description_rounded, color: Color(0xFF63D0A1), size: 18);
  }

  // MODAL PARA ELEGIR LA COLUMNA DESTINO Y CONVERTIR EL BORRADOR A TAREA OFICIAL
  void _mostrarModalPublicarTarea(BorradorNota borrador) {
    final columnas = widget.tablero.columnas.isNotEmpty
        ? widget.tablero.columnas
        : const ['Pendiente', 'En progreso', 'Completada'];

    String columnaSeleccionada = borrador.columnaDestino.isNotEmpty && columnas.contains(borrador.columnaDestino)
        ? borrador.columnaDestino
        : columnas.first;
    int prioridadSeleccionada = borrador.prioridad;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🚀 Publicar Borrador como Tarea',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Se creará la tarea "${borrador.titulo}" de forma oficial en el tablero, incluyendo sus ${borrador.adjuntos.length} archivos adjuntos.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),

                  // DROPDOWN COLUMNA DESTINO
                  DropdownButtonFormField<String>(
                    initialValue: columnaSeleccionada,
                    decoration: InputDecoration(
                      labelText: 'Columna Destino',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    items: columnas.map((col) {
                      return DropdownMenuItem(value: col, child: Text(col));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => columnaSeleccionada = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // PRIORIDAD DE LA TAREA
                  const Text('Prioridad Inicial:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _botonPrioridadModal(1, 'Baja', const Color(0xFF38A169), prioridadSeleccionada, (v) => setModalState(() => prioridadSeleccionada = v)),
                      _botonPrioridadModal(2, 'Media', const Color(0xFFED8936), prioridadSeleccionada, (v) => setModalState(() => prioridadSeleccionada = v)),
                      _botonPrioridadModal(3, 'Alta', const Color(0xFFE53E3E), prioridadSeleccionada, (v) => setModalState(() => prioridadSeleccionada = v)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // BOTÓN PUBLICAR
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF63D0A1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                      label: const Text('Publicar Tarea Ahora', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        final nav = Navigator.of(context);
                        final sca = ScaffoldMessenger.of(context);
                        nav.pop();
                        try {
                          await _firestoreService.convertirBorradorATarea(
                            borrador: borrador,
                            columnaDestino: columnaSeleccionada,
                            prioridad: prioridadSeleccionada,
                          );

                          sca.showSnackBar(
                            SnackBar(
                              content: Text('¡Borrador publicado con éxito en "$columnaSeleccionada"!'),
                              backgroundColor: const Color(0xFF63D0A1),
                            ),
                          );
                        } catch (e) {
                          sca.showSnackBar(
                            SnackBar(content: Text('Error al publicar tarea: $e'), backgroundColor: Colors.redAccent),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _botonPrioridadModal(int valor, String texto, Color color, int seleccionada, Function(int) onTap) {
    final activo = seleccionada == valor;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(valor),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: activo ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: activo ? 2 : 1),
          ),
          alignment: Alignment.center,
          child: Text(
            texto,
            style: TextStyle(
              color: activo ? Colors.white : const Color(0xFF1E293B),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  void _confirmarEliminacion(BorradorNota borrador) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Borrador'),
        content: Text('¿Deseas eliminar el borrador "${borrador.titulo}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _firestoreService.eliminarBorradorNota(borrador.id);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
