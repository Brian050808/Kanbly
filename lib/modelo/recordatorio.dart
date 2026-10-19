
class Recordatorio {
  final String id;
  final String tableroId;
  final String titulo;
  final String descripcion;
  final DateTime fechaHora;
  final bool notificado;

  const Recordatorio({
    required this.id,
    required this.tableroId,
    required this.titulo,
    required this.descripcion,
    required this.fechaHora,
    this.notificado = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tableroId': tableroId,
      'titulo': titulo,
      'descripcion': descripcion,
      'fechaHora': fechaHora.toIso8601String(),
      'notificado': notificado,
    };
  }

  factory Recordatorio.fromMap(Map<String, dynamic> map) {
    return Recordatorio(
      id: map['id'] as String,
      tableroId: map['tableroId'] as String? ?? '',
      titulo: map['titulo'] as String,
      descripcion: map['descripcion'] as String? ?? '',
      fechaHora: DateTime.parse(map['fechaHora'] as String),
      notificado: map['notificado'] as bool? ?? false,
    );
  }

  Recordatorio copyWith({
    String? tableroId,
    String? titulo,
    String? descripcion,
    DateTime? fechaHora,
    bool? notificado,
  }) {
    return Recordatorio(
      id: id,
      tableroId: tableroId ?? this.tableroId,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      fechaHora: fechaHora ?? this.fechaHora,
      notificado: notificado ?? this.notificado,
    );
  }
}
