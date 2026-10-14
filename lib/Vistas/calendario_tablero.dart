import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../modelo/tarea.dart';
import '../controlador/calendario_controller.dart';

class CalendarioTablero extends StatefulWidget {
  final String tableroId;

  const CalendarioTablero({super.key, required this.tableroId});

  @override
  State<CalendarioTablero> createState() => _CalendarioTableroState();
}

class _CalendarioTableroState extends State<CalendarioTablero> {
  final CalendarioController _controller = CalendarioController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textOnSurface = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        title: ShaderMask(
          shaderCallback: (bounds) {
            return const LinearGradient(
              colors: [
                Color(0xFF52ABEB), // Azul
                Color(0xFF63D0A1), // Verde Turquesa
              ],
            ).createShader(bounds);
          },
          child: const Text(
            'Calendario',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),

      body: StreamBuilder<List<Tarea>>(
        stream: _controller.obtenerTareasDelTablero(widget.tableroId),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          _controller.actualizarTareas(snapshot.data ?? []);

          final tareasSeleccionadas = _controller.tareasDelDia(
            _controller.diaSeleccionado,
          );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: TableCalendar<Tarea>(
                  locale: 'es_ES',
                  calendarFormat: CalendarFormat.month,

                  availableCalendarFormats: const {CalendarFormat.month: ''},
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2040, 12, 31),

                  focusedDay: _controller.diaEnfocado,

                  calendarStyle: CalendarStyle(
                    defaultTextStyle: TextStyle(color: textOnSurface),
                    weekendTextStyle: TextStyle(color: textOnSurface),
                    outsideTextStyle: TextStyle(color: Colors.grey.shade600),
                    selectedDecoration: const BoxDecoration(
                      color: Color(0xFF52ABEB),
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: const Color(0xFF52ABEB).withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: Color(0xFF63D0A1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    titleTextStyle: TextStyle(
                      color: textOnSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    leftChevronIcon: Icon(Icons.chevron_left, color: textOnSurface),
                    rightChevronIcon: Icon(Icons.chevron_right, color: textOnSurface),
                  ),

                  selectedDayPredicate: (day) {
                    return isSameDay(_controller.diaSeleccionado, day);
                  },

                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _controller.seleccionarDia(selectedDay, focusedDay);
                    });
                  },

                  eventLoader: (day) {
                    return _controller.tareasDelDia(day);
                  },
                ),
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),

                child: Align(
                  alignment: Alignment.centerLeft,

                  child: Text(
                    'Tareas del día',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: tareasSeleccionadas.isEmpty
                    ? const Center(child: Text('No hay tareas para este día'))
                    : ListView.builder(
                        itemCount: tareasSeleccionadas.length,

                        itemBuilder: (context, index) {
                          final tarea = tareasSeleccionadas[index];

                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border(
                                bottom: BorderSide(
                                  color: _controller.colorPorTiempoRestante(
                                    tarea.fechaVencimiento,
                                    tarea.estado,
                                  ),
                                  width: 4,
                                ),
                              ),
                            ),
                            child: Card(
                              margin: EdgeInsets.zero,
                              elevation: 2,
                              child: ListTile(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text(tarea.titulo),
                                        content: Text(
                                          tarea.descripcion?.isNotEmpty == true
                                              ? tarea.descripcion!
                                              : 'Esta tarea no tiene descripción.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: const Text('Cerrar'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },

                                leading: Icon(
                                  tarea.estado == EstadoTarea.completada
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  color: _controller.colorPorEstado(
                                    tarea.estado,
                                  ),
                                ),

                                title: Text(
                                  tarea.titulo,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                subtitle: Text(
                                  tarea.estado.value,
                                  style: TextStyle(
                                    color: _controller.colorPorEstado(
                                      tarea.estado,
                                    ),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),

                                trailing: Text(
                                  tarea.prioridad == 1
                                      ? 'Baja'
                                      : tarea.prioridad == 2
                                      ? 'Media'
                                      : 'Alta',
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
