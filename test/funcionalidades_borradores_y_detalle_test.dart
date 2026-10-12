import 'package:flutter_test/flutter_test.dart';
import 'package:kanbly/modelo/borrador_nota.dart';
import 'package:kanbly/modelo/tarea.dart';

void main() {
  group('Pruebas de Borradores y Automatización de Tareas', () {
    test('Creación y conversión a Map de BorradorNota con asignación, prioridad y fecha programada', () {
      final fechaProgramada = DateTime(2026, 11, 1, 10, 30);
      final borrador = BorradorNota(
        id: 'draft_123',
        usuarioId: 'user_abc',
        tableroId: 'tablero_xyz',
        titulo: 'Tarea Automática de Redes',
        contenido: 'Publicar contenido promocional',
        fechaCreacion: DateTime.now(),
        asignadoA: 'integrante_juan',
        fechaPublicacionProgramada: fechaProgramada,
        columnaDestino: 'En progreso',
        prioridad: 3, // Alta
        esPublicado: false,
      );

      expect(borrador.titulo, equals('Tarea Automática de Redes'));
      expect(borrador.asignadoA, equals('integrante_juan'));
      expect(borrador.fechaPublicacionProgramada, equals(fechaProgramada));
      expect(borrador.columnaDestino, equals('En progreso'));
      expect(borrador.prioridad, equals(3));

      final map = borrador.toMap();
      expect(map['usuarioId'], equals('user_abc'));
      expect(map['tableroId'], equals('tablero_xyz'));
      expect(map['asignadoA'], equals('integrante_juan'));
      expect(map['columnaDestino'], equals('En progreso'));
      expect(map['prioridad'], equals(3));
    });

    test('BorradorNota.fromMap procesa adecuadamente asignadoA, prioridad y columnaDestino', () {
      final mapData = {
        'usuarioId': 'user_1',
        'tableroId': 'tab_1',
        'titulo': 'Preparar Presentación',
        'contenido': 'Diapositivas del proyecto',
        'fechaCreacion': '2026-10-15T12:00:00.000',
        'asignadoA': 'user_2',
        'columnaDestino': 'Pendiente',
        'prioridad': 1, // Baja
        'esPublicado': false,
      };

      final borrador = BorradorNota.fromMap('draft_999', mapData);
      expect(borrador.id, equals('draft_999'));
      expect(borrador.asignadoA, equals('user_2'));
      expect(borrador.columnaDestino, equals('Pendiente'));
      expect(borrador.prioridad, equals(1));
      expect(borrador.esPublicado, isFalse);
    });

    test('BorradorNota.copyWith mantiene la inmutabilidad y actualiza asignación y prioridad', () {
      final borradorOriginal = BorradorNota(
        id: 'draft_1',
        usuarioId: 'user_1',
        tableroId: 'tab_1',
        titulo: 'Nota rápida',
        contenido: 'Texto',
        fechaCreacion: DateTime.now(),
        prioridad: 2,
      );

      final borradorActualizado = borradorOriginal.copyWith(
        asignadoA: 'nuevo_integrante',
        columnaDestino: 'Completada',
        prioridad: 3,
      );

      expect(borradorOriginal.asignadoA, isNull);
      expect(borradorOriginal.prioridad, equals(2));
      expect(borradorActualizado.asignadoA, equals('nuevo_integrante'));
      expect(borradorActualizado.columnaDestino, equals('Completada'));
      expect(borradorActualizado.prioridad, equals(3));
      expect(borradorActualizado.titulo, equals('Nota rápida'));
    });

    test('Simulación de conversión de BorradorNota a Tarea preservando prioridad', () {
      final borrador = BorradorNota(
        id: 'draft_auto',
        usuarioId: 'creador_1',
        tableroId: 'tablero_1',
        titulo: 'Revisar Inventario',
        contenido: 'Verificar stock de insumos',
        fechaCreacion: DateTime.now(),
        asignadoA: 'responsable_stock',
        columnaDestino: 'Por Hacer',
        prioridad: 3, // Alta
      );

      final enumEstado = EstadoTareaExtension.fromString(borrador.columnaDestino);

      final nuevaTarea = Tarea(
        id: 'tarea_nueva_123',
        titulo: borrador.titulo,
        descripcion: borrador.contenido,
        estado: enumEstado,
        estadoNombre: borrador.columnaDestino,
        orden: 0,
        tableroId: borrador.tableroId,
        asignadoA: borrador.asignadoA,
        fechaCreacion: DateTime.now(),
        prioridad: borrador.prioridad,
        adjuntos: borrador.adjuntos,
        archivada: false,
        creadaPor: borrador.usuarioId,
      );

      expect(nuevaTarea.titulo, equals('Revisar Inventario'));
      expect(nuevaTarea.asignadoA, equals('responsable_stock'));
      expect(nuevaTarea.estadoNombre, equals('Por Hacer'));
      expect(nuevaTarea.prioridad, equals(3));
      expect(nuevaTarea.creadaPor, equals('creador_1'));
    });
  });
}
