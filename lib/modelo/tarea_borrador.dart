import 'tarea.dart';

/// Representa una tarea borradores en memoria generada por el asistente de IA o creada manualmente
/// antes de ser confirmada y persistida en Firestore.
class TareaBorrador {
  final String id;
  final String titulo;
  final String? descripcion;
  final int prioridad; // 1 = baja, 2 = media, 3 = alta
  final DateTime? fechaLimite;
  final String? asignadoUid;
  final String columna;

  const TareaBorrador({
    required this.id,
    required this.titulo,
    this.descripcion,
    this.prioridad = 2,
    this.fechaLimite,
    this.asignadoUid,
    required this.columna,
  });

  /// Convierte prioridad numérica a representación de texto
  String get prioridadTexto {
    switch (prioridad) {
      case 3:
        return 'alta';
      case 1:
        return 'baja';
      case 2:
      default:
        return 'media';
    }
  }

  /// Convierte cadenas o números de prioridad a un entero (1, 2 o 3)
  static int parsePrioridad(dynamic val) {
    if (val == null) return 2;
    if (val is int) {
      if (val >= 1 && val <= 3) return val;
      return 2;
    }
    final str = val.toString().trim().toLowerCase();
    if (str == 'alta' || str == 'high' || str == '3') return 3;
    if (str == 'baja' || str == 'low' || str == '1') return 1;
    if (str == 'media' || str == 'medium' || str == '2') return 2;
    return 2;
  }

  /// Crea un objeto TareaBorrador desde un Map devuelto por el modelo de IA o un JSON
  factory TareaBorrador.fromMap(
    Map<String, dynamic> map, {
    required List<String> columnasDisponibles,
    List<String> miembrosUids = const [],
    required String idLocal,
  }) {
    // Validar título
    final rawTitulo = map['titulo']?.toString().trim();
    final titulo = (rawTitulo != null && rawTitulo.isNotEmpty)
        ? rawTitulo
        : 'Nueva tarea';

    // Validar descripción
    final rawDesc = map['descripcion']?.toString().trim();
    final descripcion = (rawDesc != null && rawDesc.isNotEmpty) ? rawDesc : null;

    // Validar prioridad
    final prioridad = parsePrioridad(map['prioridad']);

    // Validar fecha límite (ISO 8601)
    DateTime? fechaLimite;
    final rawFecha = map['fechaLimite']?.toString().trim();
    if (rawFecha != null && rawFecha.isNotEmpty) {
      fechaLimite = DateTime.tryParse(rawFecha);
    }

    // Validar columna (Ajuste 5: columna inválida -> primera columna disponible)
    String columnaFinal;
    final rawColumna = map['columna']?.toString().trim();
    if (rawColumna != null &&
        columnasDisponibles.any(
            (c) => c.toLowerCase() == rawColumna.toLowerCase())) {
      columnaFinal = columnasDisponibles.firstWhere(
        (c) => c.toLowerCase() == rawColumna.toLowerCase(),
      );
    } else {
      columnaFinal = columnasDisponibles.isNotEmpty
          ? columnasDisponibles.first
          : 'Pendiente';
    }

    // Validar asignadoUid (Ajuste 5: uid inválido -> null)
    String? asignadoFinal;
    final rawUid = map['asignadoUid']?.toString().trim();
    if (rawUid != null && rawUid.isNotEmpty) {
      if (miembrosUids.isEmpty || miembrosUids.contains(rawUid)) {
        asignadoFinal = rawUid;
      } else {
        asignadoFinal = null;
      }
    }

    return TareaBorrador(
      id: idLocal,
      titulo: titulo,
      descripcion: descripcion,
      prioridad: prioridad,
      fechaLimite: fechaLimite,
      asignadoUid: asignadoFinal,
      columna: columnaFinal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'prioridad': prioridad,
      'prioridadTexto': prioridadTexto,
      'fechaLimite': fechaLimite?.toIso8601String(),
      'asignadoUid': asignadoUid,
      'columna': columna,
    };
  }

  TareaBorrador copyWith({
    String? id,
    String? titulo,
    String? descripcion,
    int? prioridad,
    DateTime? fechaLimite,
    String? asignadoUid,
    String? columna,
  }) {
    return TareaBorrador(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      prioridad: prioridad ?? this.prioridad,
      fechaLimite: fechaLimite ?? this.fechaLimite,
      asignadoUid: asignadoUid ?? this.asignadoUid,
      columna: columna ?? this.columna,
    );
  }

  /// Convierte este borrador en un objeto Tarea oficial listo para guardarse en Firestore.
  /// Llena todos los atributos del modelo Tarea actual (creador, fecha de creación, orden, etc.).
  Tarea toTarea({
    required String idTareaDoc,
    required String tableroId,
    required String creadorId,
    int orden = 0,
  }) {
    final estadoEnum = EstadoTareaExtension.fromString(columna);
    final ahora = DateTime.now();

    final List<String> asignadosList = [];
    if (asignadoUid != null && asignadoUid!.trim().isNotEmpty) {
      asignadosList.add(asignadoUid!.trim());
    }

    return Tarea(
      id: idTareaDoc,
      titulo: titulo,
      descripcion: descripcion,
      estado: estadoEnum,
      estadoNombre: columna,
      orden: orden,
      tableroId: tableroId,
      asignadosA: asignadosList,
      fechaCreacion: ahora,
      fechaVencimiento: fechaLimite,
      fechaActualizacion: ahora,
      etiquetas: const [],
      adjuntos: const [],
      comentarios: const [],
      prioridad: prioridad,
      archivada: false,
      creadaPor: creadorId,
      comentario: null,
    );
  }
}
