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
  final String? asignadoA;
  final DateTime? fechaPublicacionProgramada;
  final String columnaDestino;
  final int prioridad; // 1 = Baja, 2 = Media, 3 = Alta
  final bool esPublicado;

  const BorradorNota({
    required this.id,
    required this.usuarioId,
    required this.tableroId,
    required this.titulo,
    required this.contenido,
    required this.fechaCreacion,
    this.fechaActualizacion,
    this.colorHex = '0xFF52ABEB',
    this.adjuntos = const [],
    this.asignadoA,
    this.fechaPublicacionProgramada,
    this.columnaDestino = 'Pendiente',
    this.prioridad = 2,
    this.esPublicado = false,
  });

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
      asignadoA: map['asignadoA']?.toString(),
      fechaPublicacionProgramada: map['fechaPublicacionProgramada'] is Timestamp
          ? (map['fechaPublicacionProgramada'] as Timestamp).toDate()
          : DateTime.tryParse(map['fechaPublicacionProgramada']?.toString() ?? ''),
      columnaDestino: map['columnaDestino']?.toString() ?? 'Pendiente',
      prioridad: prio,
      esPublicado: map['esPublicado'] == true,
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
      'asignadoA': asignadoA,
      'fechaPublicacionProgramada': fechaPublicacionProgramada != null
          ? Timestamp.fromDate(fechaPublicacionProgramada!)
          : null,
      'columnaDestino': columnaDestino,
      'prioridad': prioridad,
      'esPublicado': esPublicado,
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
    String? asignadoA,
    DateTime? fechaPublicacionProgramada,
    String? columnaDestino,
    int? prioridad,
    bool? esPublicado,
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
      asignadoA: asignadoA ?? this.asignadoA,
      fechaPublicacionProgramada: fechaPublicacionProgramada ?? this.fechaPublicacionProgramada,
      columnaDestino: columnaDestino ?? this.columnaDestino,
      prioridad: prioridad ?? this.prioridad,
      esPublicado: esPublicado ?? this.esPublicado,
    );
  }
}
