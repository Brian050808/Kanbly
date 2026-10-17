
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../modelo/recordatorio.dart';
import 'notificacion_vencimiento_service.dart';

class NotificacionRecordatorioService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> inicializar() async {
    // Inicializa el mismo plugin y la zona horaria
    // que utiliza el servicio de vencimientos.
    await NotificacionVencimientoService.inicializar();
  }

  static Future<void> programar(Recordatorio recordatorio) async {
    await inicializar();

    final ahora = tz.TZDateTime.now(tz.local);
    final fecha = recordatorio.fechaHora;

    // No programar fechas pasadas.
    if (!fecha.isAfter(DateTime.now())) {
      await cancelar(recordatorio.id);
      return;
    }

    final fechaProgramada = tz.TZDateTime.from(
      fecha,
      tz.local,
    );

    await _plugin.zonedSchedule(
      recordatorio.id.hashCode,
      recordatorio.titulo,
      recordatorio.descripcion.isEmpty
          ? 'Tienes un recordatorio pendiente.'
          : recordatorio.descripcion,
      fechaProgramada,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'recordatorios_personalizados',
          'Recordatorios personales',
          channelDescription:
          'Notificaciones de recordatorios creados por el usuario',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode:
      AndroidScheduleMode.inexactAllowWhileIdle,
    );
    final pendientes = await _plugin.pendingNotificationRequests();

    print('Notificaciones pendientes: ${pendientes.length}');
    for (final pendiente in pendientes) {
      print('ID: ${pendiente.id} | Título: ${pendiente.title}');
    }
  }

  static Future<void> cancelar(String recordatorioId) async {
    await _plugin.cancel(recordatorioId.hashCode);
  }
}
