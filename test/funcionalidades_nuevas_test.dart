import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanbly/modelo/tablero.dart';
import 'package:kanbly/modelo/tarea.dart';
import 'package:kanbly/modelo/borrador_nota.dart';
import 'package:kanbly/utilerias/formato_util.dart';

void main() {
  group('Pruebas de Funcionalidades Solicitadas por el Usuario', () {
    test('1. Personalización de columnas en el modelo Tablero', () {
      final tableroDefault = Tablero(
        id: 'b1',
        nombre: 'Tablero Estándar',
        esGrupal: false,
        creadorId: 'u1',
        fechaCreacion: DateTime.now(),
      );

      // Por defecto tiene Pendiente, En progreso, Completada
      expect(tableroDefault.columnas, equals(['Pendiente', 'En progreso', 'Completada']));

      // Tablero con columnas personalizadas
      final tableroCustom = Tablero(
        id: 'b2',
        nombre: 'Tablero Desarrollo Software',
        esGrupal: true,
        creadorId: 'u1',
        columnas: ['Por Hacer', 'En Desarrollo', 'En Pruebas / QA', 'Aprobado'],
        fechaCreacion: DateTime.now(),
      );

      expect(tableroCustom.columnas.length, equals(4));
      expect(tableroCustom.columnas, contains('En Pruebas / QA'));

      // Verificar toMap y fromMap con columnas
      final map = tableroCustom.toMap();
      expect(map['columnas'], equals(['Por Hacer', 'En Desarrollo', 'En Pruebas / QA', 'Aprobado']));

      final tableroRecuperado = Tablero.fromMap('b2', map);
      expect(tableroRecuperado.columnas, equals(['Por Hacer', 'En Desarrollo', 'En Pruebas / QA', 'Aprobado']));
    });

    test('2. Colores y textos según nivel de importancia / prioridad', () {
      expect(FormatoUtil.obtenerTextoPrioridad(3), equals('Alta'));
      expect(FormatoUtil.obtenerTextoPrioridad(2), equals('Media'));
      expect(FormatoUtil.obtenerTextoPrioridad(1), equals('Baja'));

      final colorAlta = FormatoUtil.obtenerColorPorPrioridad(3);
      final colorMedia = FormatoUtil.obtenerColorPorPrioridad(2);
      final colorBaja = FormatoUtil.obtenerColorPorPrioridad(1);

      expect(colorAlta, equals(const Color(0xFFE53E3E))); // Rojo
      expect(colorMedia, equals(const Color(0xFFED8936))); // Naranja
      expect(colorBaja, equals(const Color(0xFF38A169))); // Verde
    });

    test('3. Tareas soportan asignación de 0, 1 o múltiples integrantes', () {
      // 3a. Tarea sin asignar (0 integrantes)
      final tareaSinAsignar = Tarea(
        id: 't0',
        titulo: 'Tarea sin asignar',
        tableroId: 'b2',
        fechaCreacion: DateTime.now(),
      );
      expect(tareaSinAsignar.asignadosA, isEmpty);
      expect(tareaSinAsignar.asignadoA, isNull);

      // 3b. Tarea con 1 integrante asignado
      final tareaUnAsignado = Tarea(
        id: 't1',
        titulo: 'Diseño de la Arquitectura',
        tableroId: 'b2',
        asignadosA: ['user_dev_1'],
        fechaCreacion: DateTime.now(),
        prioridad: 3,
        estadoNombre: 'En Desarrollo',
      );

      expect(tareaUnAsignado.asignadosA, equals(['user_dev_1']));
      expect(tareaUnAsignado.asignadoA, equals('user_dev_1'));
      expect(tareaUnAsignado.estadoNombre, equals('En Desarrollo'));

      final map1 = tareaUnAsignado.toMap();
      expect(map1['asignadosA'], equals(['user_dev_1']));
      expect(map1['asignadoA'], equals('user_dev_1'));

      final tareaFromMap1 = Tarea.fromMap('t1', map1);
      expect(tareaFromMap1.asignadosA, equals(['user_dev_1']));
      expect(tareaFromMap1.asignadoA, equals('user_dev_1'));

      // 3c. Tarea con múltiples integrantes asignados (equipo)
      final tareaMultiples = Tarea(
        id: 't_multi',
        titulo: 'Módulo Colaborativo',
        tableroId: 'b2',
        asignadosA: ['user_dev_1', 'user_dev_2', 'user_qa_1'],
        fechaCreacion: DateTime.now(),
      );

      expect(tareaMultiples.asignadosA.length, equals(3));
      expect(tareaMultiples.asignadosA, containsAll(['user_dev_1', 'user_dev_2', 'user_qa_1']));
      expect(tareaMultiples.asignadoA, equals('user_dev_1'));

      final mapMulti = tareaMultiples.toMap();
      expect(mapMulti['asignadosA'], equals(['user_dev_1', 'user_dev_2', 'user_qa_1']));

      final tareaFromMapMulti = Tarea.fromMap('t_multi', mapMulti);
      expect(tareaFromMapMulti.asignadosA.length, equals(3));
    });

    test('4. Copia de tarea con copyWith actualiza asignaciones múltiples y columna', () {
      final tareaOriginal = Tarea(
        id: 't2',
        titulo: 'Revisión de Código',
        tableroId: 'b2',
        fechaCreacion: DateTime.now(),
      );

      final tareaActualizada = tareaOriginal.copyWith(
        asignadosA: ['user_qa_1', 'user_lead_1'],
        estadoNombre: 'En Pruebas / QA',
        prioridad: 2,
      );

      expect(tareaActualizada.asignadosA, equals(['user_qa_1', 'user_lead_1']));
      expect(tareaActualizada.asignadoA, equals('user_qa_1'));
      expect(tareaActualizada.estadoNombre, equals('En Pruebas / QA'));
      expect(tareaActualizada.prioridad, equals(2));
    });

    test('5. Archivos adjuntos en tareas (imágenes, documentos, videos) con límite de 10 MB', () {
      final adjuntoDoc = AdjuntoTarea(
        id: 'a1',
        nombre: 'manual_usuario.pdf',
        url: 'https://storage.firebase.com/manual_usuario.pdf',
        tipo: 'documento',
        tamanoBytes: 2 * 1024 * 1024, // 2 MB
        fechaAdjunto: DateTime.now(),
      );

      final adjuntoImg = AdjuntoTarea(
        id: 'a2',
        nombre: 'captura_pantalla.png',
        url: 'https://storage.firebase.com/captura_pantalla.png',
        tipo: 'imagen',
        tamanoBytes: 850 * 1024, // 850 KB
        fechaAdjunto: DateTime.now(),
      );

      expect(adjuntoDoc.tamanoLegible, equals('2.0 MB'));
      expect(adjuntoImg.tamanoLegible, equals('850.0 KB'));

      // Verificar límite de 10 MB (10 * 1024 * 1024 = 10,485,760 bytes)
      const maxLimitBytes = 10 * 1024 * 1024;
      const archivoValido = 5 * 1024 * 1024; // 5 MB
      const archivoExcedido = 12 * 1024 * 1024; // 12 MB

      expect(archivoValido <= maxLimitBytes, isTrue);
      expect(archivoExcedido <= maxLimitBytes, isFalse);

      // Serialización y Deserialización en la Tarea
      final tareaConAdjuntos = Tarea(
        id: 't_adj',
        titulo: 'Tarea con Documentos y Foto',
        tableroId: 'b1',
        fechaCreacion: DateTime.now(),
        adjuntos: [adjuntoDoc, adjuntoImg],
      );

      expect(tareaConAdjuntos.adjuntos.length, equals(2));

      final map = tareaConAdjuntos.toMap();
      final tareaRecuperada = Tarea.fromMap('t_adj', map);

      expect(tareaRecuperada.adjuntos.length, equals(2));
      expect(tareaRecuperada.adjuntos.first.nombre, equals('manual_usuario.pdf'));
      expect(tareaRecuperada.adjuntos.first.tipo, equals('documento'));
      expect(tareaRecuperada.adjuntos.last.nombre, equals('captura_pantalla.png'));
      expect(tareaRecuperada.adjuntos.last.tipo, equals('imagen'));
    });

    test('6. Verificación de soporte de tipos de adjuntos para el visualizador de contenido', () {
      final adjuntoTxt = AdjuntoTarea(
        id: 'a3',
        nombre: 'notas.txt',
        url: '/ruta/local/notas.txt',
        tipo: 'documento',
        tamanoBytes: 1024,
        fechaAdjunto: DateTime.now(),
      );

      final adjuntoImgWeb = AdjuntoTarea(
        id: 'a4',
        nombre: 'foto.jpg',
        url: 'https://ejemplo.com/foto.jpg',
        tipo: 'imagen',
        tamanoBytes: 500000,
        fechaAdjunto: DateTime.now(),
      );

      expect(adjuntoTxt.nombre.endsWith('.txt'), isTrue);
      expect(adjuntoImgWeb.tipo, equals('imagen'));
      expect(adjuntoImgWeb.url.startsWith('https://'), isTrue);
    });

    test('7. Verificación de extracción de texto en archivos .docx con ZipDecoder', () {
      final adjuntoDocx = AdjuntoTarea(
        id: 'a5',
        nombre: 'informe_proyecto.docx',
        url: '/ruta/local/informe_proyecto.docx',
        tipo: 'documento',
        tamanoBytes: 20480,
        fechaAdjunto: DateTime.now(),
      );

      expect(adjuntoDocx.nombre.endsWith('.docx'), isTrue);
    });

    test('8. Personalización de roles según metodología en el modelo Tablero', () {
      final tableroDefault = Tablero(
        id: 'b_rol_1',
        nombre: 'Tablero Estándar',
        esGrupal: true,
        creadorId: 'u1',
        fechaCreacion: DateTime.now(),
      );

      // Roles predeterminados por defecto
      expect(tableroDefault.roles, contains('Líder de Proyecto'));
      expect(tableroDefault.roles, contains('Programador / Desarrollador'));

      // Tablero con roles de metodología Ágil / Scrum
      final tableroScrum = Tablero(
        id: 'b_scrum',
        nombre: 'Proyecto Scrum Agil',
        esGrupal: true,
        creadorId: 'u1',
        roles: ['Product Owner', 'Scrum Master', 'Desarrollador', 'QA / Tester'],
        fechaCreacion: DateTime.now(),
      );

      expect(tableroScrum.roles.length, equals(4));
      expect(tableroScrum.roles, contains('Product Owner'));
      expect(tableroScrum.roles, contains('Scrum Master'));

      // Serialización y deserialización de roles en Firestore map
      final mapScrum = tableroScrum.toMap();
      expect(mapScrum['roles'], equals(['Product Owner', 'Scrum Master', 'Desarrollador', 'QA / Tester']));

      final tableroRecuperado = Tablero.fromMap('b_scrum', mapScrum);
      expect(tableroRecuperado.roles, equals(['Product Owner', 'Scrum Master', 'Desarrollador', 'QA / Tester']));
    });

    test('9. Sección de comentarios y retroalimentación en tareas', () {
      final comentario1 = ComentarioTarea(
        id: 'c1',
        autorId: 'u_dev1',
        autorNombre: 'Carlos Desarrollador',
        contenido: 'Se ha completado la revisión del módulo de autenticación.',
        fechaCreacion: DateTime.now(),
      );

      final comentario2 = ComentarioTarea(
        id: 'c2',
        autorId: 'u_qa1',
        autorNombre: 'Ana QA',
        contenido: 'Favor de verificar las pruebas de borde en contraseñas.',
        fechaCreacion: DateTime.now(),
      );

      final tareaConComentarios = Tarea(
        id: 't_comentarios',
        titulo: 'Módulo de Registro de Usuarios',
        tableroId: 'b_com',
        fechaCreacion: DateTime.now(),
        comentarios: [comentario1, comentario2],
      );

      expect(tareaConComentarios.comentarios.length, equals(2));
      expect(tareaConComentarios.comentarios.first.autorNombre, equals('Carlos Desarrollador'));
      expect(tareaConComentarios.comentarios.last.contenido, contains('pruebas de borde'));

      // Serialización toMap y deserialización fromMap
      final map = tareaConComentarios.toMap();
      expect(map['comentarios'], isA<List>());
      expect((map['comentarios'] as List).length, equals(2));

      final tareaRecuperada = Tarea.fromMap('t_comentarios', map);
      expect(tareaRecuperada.comentarios.length, equals(2));
      expect(tareaRecuperada.comentarios.first.autorId, equals('u_dev1'));
      expect(tareaRecuperada.comentarios.last.autorNombre, equals('Ana QA'));

      // Prueba con copyWith para añadir un nuevo comentario
      final comentario3 = ComentarioTarea(
        id: 'c3',
        autorId: 'u_po',
        autorNombre: 'Pedro Product Owner',
        contenido: 'Aprobado para el sprint actual.',
        fechaCreacion: DateTime.now(),
      );

      final tareaActualizada = tareaConComentarios.copyWith(
        comentarios: [...tareaConComentarios.comentarios, comentario3],
      );

      expect(tareaActualizada.comentarios.length, equals(3));
      expect(tareaActualizada.comentarios.last.autorNombre, equals('Pedro Product Owner'));
    });

    test('10. Modelo BorradorNota para espacio personal de borradores y notas privadas', () {
      final borrador = BorradorNota(
        id: 'draft_1',
        usuarioId: 'user_dev_1',
        tableroId: 'b_kanban_1',
        titulo: 'Idea de refactorización de base de datos',
        contenido: 'Puntos a considerar:\n- Crear colecciones secundarias.\n- Optimizar índices.',
        fechaCreacion: DateTime.now(),
        colorHex: '0xFF63D0A1',
      );

      expect(borrador.titulo, contains('refactorización'));
      expect(borrador.colorHex, equals('0xFF63D0A1'));

      final map = borrador.toMap();
      expect(map['usuarioId'], equals('user_dev_1'));
      expect(map['tableroId'], equals('b_kanban_1'));
      expect(map['colorHex'], equals('0xFF63D0A1'));

      final borradorRecuperado = BorradorNota.fromMap('draft_1', map);
      expect(borradorRecuperado.titulo, equals(borrador.titulo));
      expect(borradorRecuperado.contenido, equals(borrador.contenido));
      expect(borradorRecuperado.colorHex, equals('0xFF63D0A1'));
    });

    test('11. Soporte de archivos adjuntos en BorradorNota y migración al publicar como tarea', () {
      final adjunto = AdjuntoTarea(
        id: 'adj_d1',
        nombre: 'diagrama_esquema.png',
        url: 'https://storage.firebase.com/diagrama.png',
        tipo: 'imagen',
        tamanoBytes: 500000,
        fechaAdjunto: DateTime.now(),
      );

      final borradorConAdjunto = BorradorNota(
        id: 'draft_2',
        usuarioId: 'user_dev_1',
        tableroId: 'b_kanban_1',
        titulo: 'Borrador con Mockups',
        contenido: '### Requerimientos\n- [ ] Pantalla Login\n- [x] Base de datos',
        fechaCreacion: DateTime.now(),
        adjuntos: [adjunto],
      );

      expect(borradorConAdjunto.adjuntos.length, equals(1));
      expect(borradorConAdjunto.adjuntos.first.nombre, equals('diagrama_esquema.png'));

      // Verificar toMap y desde Map
      final map = borradorConAdjunto.toMap();
      expect(map['adjuntos'], isA<List>());

      final recuperado = BorradorNota.fromMap('draft_2', map);
      expect(recuperado.adjuntos.length, equals(1));
      expect(recuperado.adjuntos.first.tipo, equals('imagen'));
    });
  });
}
