import 'package:table_calendar/table_calendar.dart';
import '../modelo/tarea.dart';
import '../servicios/tarea_service.dart';
import 'package:flutter/material.dart';

class CalendarioController {
  final TareaService _tareaService = TareaService();

  DateTime diaSeleccionado = DateTime.now();
  DateTime diaEnfocado = DateTime.now();

  List<Tarea> tareas = [];

  // Obtener las tareas del tablero
  Stream<List<Tarea>> obtenerTareasDelTablero(String tableroId) {
    return _tareaService.obtenerTareasDelTablero(tableroId);
  }

  // Actualizar las tareas recibidas
  void actualizarTareas(List<Tarea> nuevasTareas) {
    tareas = nuevasTareas;
  }

  // Obtener las tareas de un día específico
  List<Tarea> tareasDelDia(DateTime dia) {
    return tareas.where((tarea) {
      if (tarea.fechaVencimiento == null) {
        return false;
      }

      return isSameDay(tarea.fechaVencimiento, dia);
    }).toList();
  }

  Color colorPorEstado(EstadoTarea estado) {
    switch (estado) {
      case EstadoTarea.pendiente:
        return const Color(0xFF52ABEB); // Azul
      case EstadoTarea.enProgreso:
        return const Color(0xFFF59E0B); // Ámbar / Naranja
      case EstadoTarea.completada:
        return const Color(0xFF63D0A1); // Verde Turquesa
      case EstadoTarea.bloqueada:
        return const Color(0xFFE53E3E); // Rojo
    }
  }

  Color colorPorTiempoRestante(DateTime? fechaVencimiento, EstadoTarea estado) {
    if (estado == EstadoTarea.completada) {
      return const Color(0xFF63D0A1);
    }

    if (fechaVencimiento == null) {
      return Colors.grey;
    }

    final ahora = DateTime.now();
    final inicioHoy = DateTime(ahora.year, ahora.month, ahora.day);
    final inicioVencimiento = DateTime(
      fechaVencimiento.year,
      fechaVencimiento.month,
      fechaVencimiento.day,
    );

    final diferenciaDias = inicioVencimiento.difference(inicioHoy).inDays;

    if (diferenciaDias < 0) {
      return const Color(0xFFE53E3E); // Vencida (Rojo)
    } else if (diferenciaDias == 0) {
      return const Color(0xFFF59E0B); // Vence hoy (Naranja)
    } else if (diferenciaDias <= 2) {
      return const Color(0xFF52ABEB); // Próxima (Azul)
    }
    return const Color(0xFF63D0A1); // Verde
  }

  String textoEstadoTiempo(DateTime? fechaVencimiento, EstadoTarea estado) {
    if (estado == EstadoTarea.completada) return 'Completada';
    if (fechaVencimiento == null) return 'Sin fecha';

    final ahora = DateTime.now();
    final inicioHoy = DateTime(ahora.year, ahora.month, ahora.day);
    final inicioVencimiento = DateTime(
      fechaVencimiento.year,
      fechaVencimiento.month,
      fechaVencimiento.day,
    );

    final diferenciaDias = inicioVencimiento.difference(inicioHoy).inDays;

    if (diferenciaDias < 0) {
      final diasPasados = diferenciaDias.abs();
      return 'Vencida hace $diasPasados ${diasPasados == 1 ? "día" : "días"}';
    } else if (diferenciaDias == 0) {
      return 'Vence hoy';
    } else if (diferenciaDias == 1) {
      return 'Vence mañana';
    } else {
      return 'Vence en $diferenciaDias días';
    }
  }

  // Seleccionar un día del calendario
  void seleccionarDia(DateTime selectedDay, DateTime focusedDay) {
    diaSeleccionado = selectedDay;
    diaEnfocado = focusedDay;
  }
}
