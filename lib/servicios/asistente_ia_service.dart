import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';
import '../modelo/tarea_borrador.dart';

/// Interfaz abstracta para el servicio de Asistente con IA.
/// Permite inyectar un doble de prueba (Fake/Mock) en controladores y pruebas unitarias.
abstract class IAsistenteIaService {
  Future<List<TareaBorrador>> procesarDictadoVoz({
    required String textoTranscrito,
    required DateTime fechaActual,
    required List<String> columnas,
    required List<Map<String, String>> miembros, // cada mapa contiene 'uid' y 'nombre'
  });
}

/// Servicio que interactúa con Gemini a través de Firebase AI Logic (`FirebaseAI.googleAI()`).
///
/// NOTA DE CONFIGURACIÓN EN CONSOLA DE FIREBASE:
/// Para que `FirebaseAI.googleAI()` funcione correctamente sin API keys expuestas en el código:
/// 1. Ve a la consola de Firebase (https://console.firebase.google.com/).
/// 2. Selecciona tu proyecto y accede a la sección "Build" -> "AI Logic" (o "Vertex AI / Google AI in Firebase").
/// 3. Habilita la integración de Gemini Developer API.
class AsistenteIaService implements IAsistenteIaService {
  /// Constante de modelo Flash vigente según la documentación de Firebase AI Logic.
  static const String modeloIaPredeterminado = 'gemini-2.0-flash';

  final String nombreModelo;

  AsistenteIaService({this.nombreModelo = modeloIaPredeterminado});

  @override
  Future<List<TareaBorrador>> procesarDictadoVoz({
    required String textoTranscrito,
    required DateTime fechaActual,
    required List<String> columnas,
    required List<Map<String, String>> miembros,
  }) async {
    final textoLimpio = textoTranscrito.trim();
    if (textoLimpio.isEmpty) {
      return [];
    }

    final columnasLote = columnas.isNotEmpty
        ? columnas
        : const ['Pendiente', 'En progreso', 'Completada'];

    final List<String> uidsMiembros = miembros
        .map((m) => m['uid']?.trim() ?? '')
        .where((uid) => uid.isNotEmpty)
        .toList();

    // 1. Calcular offset de zona horaria de la fecha actual (ISO 8601 con offset)
    final offset = fechaActual.timeZoneOffset;
    final horas = offset.inHours.abs().toString().padLeft(2, '0');
    final minutos = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final signo = offset.isNegative ? '-' : '+';
    final isoOffsetStr =
        '${fechaActual.toIso8601String().split('.').first}$signo$horas:$minutos';

    // 2. Construir responseSchema dinámico con enums para columnas, prioridad y uids
    final Schema schemaTareas = Schema.object(
      properties: {
        'tareas': Schema.array(
          items: Schema.object(
            properties: {
              'titulo': Schema.string(
                description: 'Título claro y conciso de la tarea dictada.',
              ),
              'descripcion': Schema.string(
                description:
                    'Descripción o detalle adicional mencionado para la tarea, o null si no hay.',
                nullable: true,
              ),
              'prioridad': Schema.enumString(
                enumValues: const ['alta', 'media', 'baja'],
                description:
                    'Prioridad indicada ("alta", "media", "baja") o null si no se especifica.',
                nullable: true,
              ),
              'fechaLimite': Schema.string(
                description:
                    'Fecha y hora límite calculada en formato ISO 8601 con offset de zona horaria o null si no hay.',
                nullable: true,
              ),
              'columna': Schema.enumString(
                enumValues: columnasLote,
                description:
                    'Nombre exacto de una de las columnas del tablero recibidas.',
                nullable: true,
              ),
              'asignadoUid': uidsMiembros.isNotEmpty
                  ? Schema.enumString(
                      enumValues: uidsMiembros,
                      description:
                          'UID del integrante al que se asigna la tarea o null si no se especifica.',
                      nullable: true,
                    )
                  : Schema.string(
                      description:
                          'UID del integrante al que se asigna la tarea o null.',
                      nullable: true,
                    ),
            },
            optionalProperties: const [
              'descripcion',
              'prioridad',
              'fechaLimite',
              'columna',
              'asignadoUid',
            ],
          ),
        ),
      },
    );

    // 3. Prompt del sistema en español con restricciones estrictas
    final String promptSistema = '''
Eres un asistente de IA experto en estructurar tareas para tableros Kanban.
Tu objetivo es analizar la transcripción de dictado por voz del usuario y extraer las tareas mencionadas.

Contexto proporcionado:
- Fecha y hora actual del usuario con offset de zona horaria: $isoOffsetStr
- Columnas permitidas en el tablero: ${columnasLote.join(', ')}
- Integrantes disponibles (UID y Nombre): ${miembros.map((m) => '${m['uid']}: ${m['nombre']}').join(', ')}

Reglas de extracción estrictas:
1. "titulo": Extrae el título principal de la tarea. Es un campo obligatorio.
2. "descripcion": Detalle explicativo de la tarea si fue dictado. Si no se menciona, debe ser null.
3. "prioridad": Selecciona una de las opciones ["alta", "media", "baja"] si el usuario la menciona o la sugiere claramente. Si no queda clara o no la menciona, asigna null.
4. "fechaLimite": Si el usuario indica un plazo o fecha (ej. "para mañana a las 3pm", "el viernes"), calcula la fecha/hora absoluta en formato ISO 8601 incluyendo el offset de zona horaria ($signo$horas:$minutos). Si no menciona fecha, asigna null.
5. "columna": Selecciona la columna más adecuada dentro de las columnas permitidas. Si no especifica columna, asigna la primera columna de la lista ("${columnasLote.first}").
6. "asignadoUid": Si el usuario menciona el nombre de un integrante de la lista, asigna su UID exacto. Si no coincide con ningún integrante o no se especifica, asigna null.
7. REGLA FUNDAMENTAL DE FIDELIDAD: NO dividas una sola tarea en múltiples tareas. Tampoco inventes tareas que no hayan sido mencionadas explícitamente en el dictado. Si algo no está claro, asigna null al campo correspondiente.
''';

    try {
      // 4. Instanciar el modelo con FirebaseAI.googleAI() (Ajuste 2)
      final generativeModel = FirebaseAI.googleAI().generativeModel(
        model: nombreModelo,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: schemaTareas,
        ),
        systemInstruction: Content.system(promptSistema),
      );

      final promptUsuario = 'Texto dictado por el usuario: "$textoLimpio"';
      final response = await generativeModel.generateContent([
        Content.text(promptUsuario),
      ]);

      final String? responseText = response.text;
      if (responseText == null || responseText.trim().isEmpty) {
        throw Exception('El modelo de IA devolvió una respuesta vacía.');
      }

      // 5. Parsear respuesta JSON devuelta por Gemini
      final dynamic parsedJson = jsonDecode(responseText);
      List<dynamic> listaTareasJson = [];

      if (parsedJson is Map<String, dynamic>) {
        if (parsedJson.containsKey('tareas') && parsedJson['tareas'] is List) {
          listaTareasJson = parsedJson['tareas'] as List<dynamic>;
        }
      } else if (parsedJson is List) {
        listaTareasJson = parsedJson;
      }

      final List<TareaBorrador> borradores = [];
      int contadorId = 1;

      for (final item in listaTareasJson) {
        if (item is Map<String, dynamic>) {
          final idLocal = 'borrador_${DateTime.now().millisecondsSinceEpoch}_$contadorId';
          contadorId++;

          final borrador = TareaBorrador.fromMap(
            item,
            columnasDisponibles: columnasLote,
            miembrosUids: uidsMiembros,
            idLocal: idLocal,
          );
          borradores.add(borrador);
        }
      }

      return borradores;
    } catch (e) {
      throw Exception('Error al procesar el dictado con IA: $e');
    }
  }
}
