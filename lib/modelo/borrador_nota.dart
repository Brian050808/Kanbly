import 'package:cloud_firestore/cloud_firestore.dart';
import 'tarea.dart';

/// Representa una nota personal o borrador previo de tarea de un integrante en un tablero
class BorradorNota {
  final String id;
  final String usuarioId;
  final String tableroId;
  final String titulo;
  final String contenido;
  final DateTime fechaCreacion;
  final DateTime? fechaActualizacion;
  final String colorHex;
  final List<AdjuntoTarea> adjuntos;

  // Campos para automatización, asignación y metadatos equivalentes a Tarea
  final List<String> asignadosA;
  final DateTime? fechaPublicacionProgramada;
  final String columnaDestino;
  final int prioridad; // 1 = Baja, 2 = Media, 3 = Alta
  final bool esPublicado;

  // Campos para vinculación de notas personales a tareas
  final String? tareaId;
  final String? tareaTitulo;
  final bool esNotaPersonal;

  /// Retorna el primer integrante asignado para compatibilidad
  String? get asignadoA => asignadosA.isNotEmpty ? asignadosA.first : null;

  BorradorNota({
    required this.id,
    required this.usuarioId,
    required this.tableroId,
    required this.titulo,
    required this.contenido,
    required this.fechaCreacion,
    this.fechaActualizacion,
    this.colorHex = '0xFF52ABEB',
    this.adjuntos = const [],
    List<String>? asignadosA,
    String? asignadoA,
    this.fechaPublicacionProgramada,
    this.columnaDestino = 'Pendiente',
    this.prioridad = 2,
    this.esPublicado = false,
    this.tareaId,
    this.tareaTitulo,
    this.esNotaPersonal = true,
  }) : asignadosA = asignadosA ?? (asignadoA != null ? [asignadoA] : const []);

  factory BorradorNota.fromMap(String id, Map<String, dynamic> map) {
    List<AdjuntoTarea> adjuntosList = [];
    if (map['adjuntos'] != null && map['adjuntos'] is List) {
      for (final item in (map['adjuntos'] as List)) {
        if (item is Map) {
          adjuntosList.add(AdjuntoTarea.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }

    int prio = 2;
    if (map['prioridad'] != null) {
      prio = int.tryParse(map['prioridad'].toString()) ?? 2;
    }

    List<String> asignadosList = [];
    if (map['asignadosA'] != null && map['asignadosA'] is List) {
      asignadosList = List<String>.from(map['asignadosA']);
    } else if (map['asignadoA'] != null && map['asignadoA'].toString().trim().isNotEmpty) {
      asignadosList = [map['asignadoA'].toString()];
    }

    return BorradorNota(
      id: id,
      usuarioId: map['usuarioId']?.toString() ?? '',
      tableroId: map['tableroId']?.toString() ?? '',
      titulo: map['titulo']?.toString() ?? 'Borrador sin título',
      contenido: map['contenido']?.toString() ?? '',
      fechaCreacion: map['fechaCreacion'] is Timestamp
          ? (map['fechaCreacion'] as Timestamp).toDate()
          : DateTime.tryParse(map['fechaCreacion']?.toString() ?? '') ?? DateTime.now(),
      fechaActualizacion: map['fechaActualizacion'] is Timestamp
          ? (map['fechaActualizacion'] as Timestamp).toDate()
          : DateTime.tryParse(map['fechaActualizacion']?.toString() ?? ''),
      colorHex: map['colorHex']?.toString() ?? '0xFF52ABEB',
      adjuntos: adjuntosList,
      asignadosA: asignadosList,
      fechaPublicacionProgramada: map['fechaPublicacionProgramada'] is Timestamp
          ? (map['fechaPublicacionProgramada'] as Timestamp).toDate()
          : DateTime.tryParse(map['fechaPublicacionProgramada']?.toString() ?? ''),
      columnaDestino: map['columnaDestino']?.toString() ?? 'Pendiente',
      prioridad: prio,
      esPublicado: map['esPublicado'] == true,
      tareaId: map['tareaId']?.toString(),
      tareaTitulo: map['tareaTitulo']?.toString(),
      esNotaPersonal: map['esNotaPersonal'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'usuarioId': usuarioId,
      'tableroId': tableroId,
      'titulo': titulo,
      'contenido': contenido,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'fechaActualizacion': fechaActualizacion != null
          ? Timestamp.fromDate(fechaActualizacion!)
          : null,
      'colorHex': colorHex,
      'adjuntos': adjuntos.map((a) => a.toMap()).toList(),
      'asignadosA': asignadosA,
      'asignadoA': asignadoA,
      'fechaPublicacionProgramada': fechaPublicacionProgramada != null
          ? Timestamp.fromDate(fechaPublicacionProgramada!)
          : null,
      'columnaDestino': columnaDestino,
      'prioridad': prioridad,
      'esPublicado': esPublicado,
      'tareaId': tareaId,
      'tareaTitulo': tareaTitulo,
      'esNotaPersonal': esNotaPersonal,
    };
  }

  BorradorNota copyWith({
    String? id,
    String? usuarioId,
    String? tableroId,
    String? titulo,
    String? contenido,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    String? colorHex,
    List<AdjuntoTarea>? adjuntos,
    List<String>? asignadosA,
    String? asignadoA,
    DateTime? fechaPublicacionProgramada,
    String? columnaDestino,
    int? prioridad,
    bool? esPublicado,
    String? tareaId,
    bool clearTareaId = false,
    String? tareaTitulo,
    bool? esNotaPersonal,
  }) {
    return BorradorNota(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      tableroId: tableroId ?? this.tableroId,
      titulo: titulo ?? this.titulo,
      contenido: contenido ?? this.contenido,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      colorHex: colorHex ?? this.colorHex,
      adjuntos: adjuntos ?? this.adjuntos,
      asignadosA: asignadosA ?? (asignadoA != null ? [asignadoA] : this.asignadosA),
      fechaPublicacionProgramada: fechaPublicacionProgramada ?? this.fechaPublicacionProgramada,
      columnaDestino: columnaDestino ?? this.columnaDestino,
      prioridad: prioridad ?? this.prioridad,
      esPublicado: esPublicado ?? this.esPublicado,
      tareaId: clearTareaId ? null : (tareaId ?? this.tareaId),
      tareaTitulo: clearTareaId ? null : (tareaTitulo ?? this.tareaTitulo),
      esNotaPersonal: esNotaPersonal ?? this.esNotaPersonal,
    );
  }
}
