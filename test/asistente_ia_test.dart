import 'package:flutter_test/flutter_test.dart';
import 'package:kanbly/modelo/tarea_borrador.dart';
import 'package:kanbly/modelo/tarea.dart';
import 'package:kanbly/servicios/asistente_ia_service.dart';
import 'package:kanbly/controlador/asistente_ia_controller.dart';

/// Fake de IAsistenteIaService para pruebas aisladas del controlador (Ajuste 12)
class FakeAsistenteIaService implements IAsistenteIaService {
  final List<TareaBorrador> borradoresAProcesar;
  bool throwError;

  FakeAsistenteIaService({
    this.borradoresAProcesar = const [],
    this.throwError = false,
  });

  @override
  Future<List<TareaBorrador>> procesarDictadoVoz({
    required String textoTranscrito,
    required DateTime fechaActual,
    required List<String> columnas,
    required List<Map<String, String>> miembros,
  }) async {
    if (throwError) {
      throw Exception('Error simulado en servicio Fake de IA');
    }
    return borradoresAProcesar;
  }
}

void main() {
  group('Pruebas Unitarias del Modelo TareaBorrador', () {
    test('Parsea campos válidos desde un Map', () {
      final map = {
        'titulo': 'Diseñar prototipo Figma',
        'descripcion': 'Crear las pantallas del asistente',
        'prioridad': 'alta',
        'fechaLimite': '2026-10-25T15:00:00Z',
        'columna': 'En progreso',
        'asignadoUid': 'user_123',
      };

      final borrador = TareaBorrador.fromMap(
        map,
        columnasDisponibles: ['Pendiente', 'En progreso', 'Completada'],
        miembrosUids: ['user_123', 'user_456'],
        idLocal: 'id_test_1',
      );

      expect(borrador.id, equals('id_test_1'));
      expect(borrador.titulo, equals('Diseñar prototipo Figma'));
      expect(borrador.descripcion, equals('Crear las pantallas del asistente'));
      expect(borrador.prioridad, equals(3)); // 3 = alta
      expect(borrador.prioridadTexto, equals('alta'));
      expect(borrador.columna, equals('En progreso'));
      expect(borrador.asignadoUid, equals('user_123'));
      expect(borrador.fechaLimite, isNotNull);
    });

    test('Sustituye columna inválida por la primera columna disponible (Ajuste 5)', () {
      final map = {
        'titulo': 'Tarea de prueba',
        'columna': 'ColumnaInexistente',
      };

      final borrador = TareaBorrador.fromMap(
        map,
        columnasDisponibles: ['Por Hacer', 'Haciendo', 'Hecho'],
        miembrosUids: [],
        idLocal: 'id_test_2',
      );

      expect(borrador.columna, equals('Por Hacer'));
    });

    test('Sustituye asignadoUid inválido por null (Ajuste 5)', () {
      final map = {
        'titulo': 'Tarea de prueba',
        'columna': 'Pendiente',
        'asignadoUid': 'uid_inexistente',
      };

      final borrador = TareaBorrador.fromMap(
        map,
        columnasDisponibles: ['Pendiente', 'Completada'],
        miembrosUids: ['user_valido_1', 'user_valido_2'],
        idLocal: 'id_test_3',
      );

      expect(borrador.asignadoUid, isNull);
    });

    test('copyWith permite establecer en null fechaLimite, asignadoUid y descripcion', () {
      final borradorOriginal = TareaBorrador(
        id: 'id_1',
        titulo: 'Título original',
        descripcion: 'Descripción existente',
        prioridad: 2,
        fechaLimite: DateTime(2026, 10, 25, 15, 0),
        asignadoUid: 'user_123',
        columna: 'Pendiente',
      );

      final borradorLimpio = borradorOriginal.copyWith(
        fechaLimite: null,
        limpiarFecha: true,
        asignadoUid: null,
        limpiarAsignado: true,
        descripcion: null,
        limpiarDescripcion: true,
      );

      expect(borradorLimpio.id, equals('id_1'));
      expect(borradorLimpio.titulo, equals('Título original'));
      expect(borradorLimpio.fechaLimite, isNull);
      expect(borradorLimpio.asignadoUid, isNull);
      expect(borradorLimpio.descripcion, isNull);
    });

    test('fromMap convierte fechaLimite a hora local con toLocal() cuando incluye offset -06:00', () {
      const dateStrWithOffset = '2026-10-18T15:00:00-06:00';
      final expectedLocal = DateTime.parse(dateStrWithOffset).toLocal();

      final map = {
        'titulo': 'Tarea con offset de zona horaria',
        'fechaLimite': dateStrWithOffset,
        'columna': 'Pendiente',
      };

      final borrador = TareaBorrador.fromMap(
        map,
        columnasDisponibles: ['Pendiente'],
        idLocal: 'id_offset_test',
      );

      expect(borrador.fechaLimite, isNotNull);
      expect(borrador.fechaLimite!.isUtc, isFalse);
      expect(borrador.fechaLimite, equals(expectedLocal));
    });

    test('toTarea llena exhaustivamente todos los campos del modelo Tarea (Ajuste 10)', () {
      final borrador = TareaBorrador(
        id: 'borrador_1',
        titulo: 'Revisar PRs',
        descripcion: 'Revisión de código de la rama main',
        prioridad: 3,
        fechaLimite: DateTime(2026, 10, 20, 18, 0),
        asignadoUid: 'dev_user_1',
        columna: 'En progreso',
      );

      final tarea = borrador.toTarea(
        idTareaDoc: 'tarea_doc_1',
        tableroId: 'tablero_123',
        creadorId: 'creador_456',
        orden: 1,
      );

      expect(tarea.id, equals('tarea_doc_1'));
      expect(tarea.titulo, equals('Revisar PRs'));
      expect(tarea.descripcion, equals('Revisión de código de la rama main'));
      expect(tarea.estado, equals(EstadoTarea.enProgreso));
      expect(tarea.estadoNombre, equals('En progreso'));
      expect(tarea.tableroId, equals('tablero_123'));
      expect(tarea.creadaPor, equals('creador_456'));
      expect(tarea.orden, equals(1));
      expect(tarea.prioridad, equals(3));
      expect(tarea.asignadosA, contains('dev_user_1'));
      expect(tarea.archivada, isFalse);
      expect(tarea.fechaCreacion, isNotNull);
      expect(tarea.fechaVencimiento, equals(DateTime(2026, 10, 20, 18, 0)));
    });
  });

  group('Pruebas Unitarias de AsistenteIaController con Fake Service', () {
    test('Procesa transcripción y llena borradores usando FakeAsistenteIaService', () async {
      final fakeBorradores = [
        const TareaBorrador(
          id: 'fake_1',
          titulo: 'Comprar licencias',
          columna: 'Pendiente',
        ),
      ];

      final fakeService = FakeAsistenteIaService(borradoresAProcesar: fakeBorradores);
      final controller = AsistenteIaController(iaService: fakeService);

      controller.setTranscription('Comprar licencias de software');

      final ok = await controller.procesarTranscripcionConIa(
        fechaActual: DateTime.now(),
        columnas: ['Pendiente', 'Completada'],
        miembros: [],
      );

      expect(ok, isTrue);
      expect(controller.borradores.length, equals(1));
      expect(controller.borradores.first.titulo, equals('Comprar licencias'));
      expect(controller.isLoading, isFalse);
    });

    test('Agrega, actualiza y elimina borradores manualmente', () {
      final controller = AsistenteIaController();

      // Agregar manual
      controller.agregarBorradorManual('Pendiente');
      expect(controller.borradores.length, equals(1));
      expect(controller.borradores.first.titulo, equals('Nueva tarea'));

      // Actualizar borrador
      final borradorEditado = controller.borradores.first.copyWith(
        titulo: 'Título Modificado',
        prioridad: 3,
      );
      controller.actualizarBorrador(0, borradorEditado);
      expect(controller.borradores.first.titulo, equals('Título Modificado'));
      expect(controller.borradores.first.prioridad, equals(3));

      // Eliminar borrador
      controller.eliminarBorrador(0);
      expect(controller.borradores, isEmpty);
    });

    test('Maneja errores devueltos por el servicio de IA', () async {
      final fakeService = FakeAsistenteIaService(throwError: true);
      final controller = AsistenteIaController(iaService: fakeService);

      controller.setTranscription('Dictado que fallará');

      final ok = await controller.procesarTranscripcionConIa(
        fechaActual: DateTime.now(),
        columnas: ['Pendiente'],
        miembros: [],
      );

      expect(ok, isFalse);
      expect(controller.errorMessage, contains('Error simulado en servicio Fake de IA'));
      expect(controller.isLoading, isFalse);
    });
  });
}
