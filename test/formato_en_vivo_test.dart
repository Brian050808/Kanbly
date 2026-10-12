import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanbly/modelo/borrador_nota.dart';

void main() {
  group('Pruebas de Descripción y Borradores como Texto Plano y Automatización', () {
    test('1. Las descripciones de tareas se manejan como TextEditingController estándar', () {
      final controller = TextEditingController(text: 'Esta es una descripción en texto plano simple.');

      expect(controller.text, equals('Esta es una descripción en texto plano simple.'));

      controller.text = 'Nueva descripción editada sin ningún formato especial.';
      expect(controller.text, equals('Nueva descripción editada sin ningún formato especial.'));
    });

    test('2. El contenido de notas y borradores es texto plano limpio', () {
      final contenidoController = TextEditingController(text: 'Detalles de la nota personal o borrador.');

      expect(contenidoController.text, equals('Detalles de la nota personal o borrador.'));
    });

    test('3. Modelo BorradorNota soporta asignación de integrante y fecha de publicación programada', () {
      final fechaProgramada = DateTime.now().add(const Duration(hours: 2));

      final borradorAutomatizado = BorradorNota(
        id: 'draft_auto_1',
        usuarioId: 'u_creador',
        tableroId: 'b_kanban_1',
        titulo: 'Revisión de Seguridad del Módulo Auth',
        contenido: 'Verificar tokens JWT y tiempos de expiración.',
        fechaCreacion: DateTime.now(),
        asignadoA: 'u_dev_seguridad',
        fechaPublicacionProgramada: fechaProgramada,
        columnaDestino: 'En progreso',
      );

      expect(borradorAutomatizado.asignadoA, equals('u_dev_seguridad'));
      expect(borradorAutomatizado.fechaPublicacionProgramada, equals(fechaProgramada));
      expect(borradorAutomatizado.columnaDestino, equals('En progreso'));

      // Verificar serialización a Map y reconstrucción desde Map
      final map = borradorAutomatizado.toMap();
      expect(map['asignadoA'], equals('u_dev_seguridad'));
      expect(map['columnaDestino'], equals('En progreso'));

      final recuperado = BorradorNota.fromMap('draft_auto_1', map);
      expect(recuperado.asignadoA, equals('u_dev_seguridad'));
      expect(recuperado.columnaDestino, equals('En progreso'));
      expect(recuperado.fechaPublicacionProgramada, isNotNull);
    });
  });
}
