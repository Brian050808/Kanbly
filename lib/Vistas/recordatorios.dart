
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../modelo/recordatorio.dart';
import '../servicios/recordatorio_service.dart';
import '../servicios/notificacion_recordatorio_service.dart';


class Recordatorios extends StatefulWidget {
  const Recordatorios({super.key});

  @override
  State<Recordatorios> createState() => _RecordatoriosState();
}

class _RecordatoriosState extends State<Recordatorios> {
  final RecordatorioService _recordatorioService =
  RecordatorioService();

  @override
  void initState() {
    super.initState();
    NotificacionRecordatorioService.inicializar();
  }

  Future<void> _crearRecordatorio() async {
    final tituloController = TextEditingController();
    final descripcionController = TextEditingController();

    DateTime fechaSeleccionada = DateTime.now().add(
      const Duration(hours: 1),
    );

    try {
      final resultado = await showDialog<Recordatorio>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Nuevo recordatorio'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: tituloController,
                        decoration: const InputDecoration(
                          labelText: 'Título',
                          hintText: 'Ej. Entregar proyecto',
                        ),
                      ),
                      TextField(
                        controller: descripcionController,
                        decoration: const InputDecoration(
                          labelText: 'Descripción (opcional)',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_month),
                        title: const Text('Fecha y hora'),
                        subtitle: Text(
                          DateFormat('dd/MM/yyyy HH:mm')
                              .format(fechaSeleccionada),
                        ),
                        onTap: () async {
                          final fecha = await showDatePicker(
                            context: dialogContext,
                            initialDate: fechaSeleccionada,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );

                          if (fecha == null ||
                              !dialogContext.mounted) {
                            return;
                          }

                          final hora = await showTimePicker(
                            context: dialogContext,
                            initialTime: TimeOfDay.fromDateTime(
                              fechaSeleccionada,
                            ),
                          );

                          if (hora == null ||
                              !dialogContext.mounted) {
                            return;
                          }

                          final nuevaFecha = DateTime(
                            fecha.year,
                            fecha.month,
                            fecha.day,
                            hora.hour,
                            hora.minute,
                          );

                          if (!nuevaFecha.isAfter(DateTime.now())) {
                            ScaffoldMessenger.of(dialogContext)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Selecciona una fecha y hora futuras.',
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            fechaSeleccionada = nuevaFecha;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(dialogContext),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final titulo =
                      tituloController.text.trim();

                      if (titulo.isEmpty) {
                        ScaffoldMessenger.of(dialogContext)
                            .showSnackBar(
                          const SnackBar(
                            content: Text('Escribe un título.'),
                          ),
                        );
                        return;
                      }

                      if (!fechaSeleccionada
                          .isAfter(DateTime.now())) {
                        ScaffoldMessenger.of(dialogContext)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Selecciona una fecha y hora futuras.',
                            ),
                          ),
                        );
                        return;
                      }

                      final recordatorio = Recordatorio(
                        id: DateTime.now()
                            .microsecondsSinceEpoch
                            .toString(),
                        titulo: titulo,
                        descripcion:
                        descripcionController.text.trim(),
                        fechaHora: fechaSeleccionada,
                      );

                      Navigator.pop(
                        dialogContext,
                        recordatorio,
                      );
                    },
                    child: const Text('Guardar'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (resultado == null || !mounted) return;

      // Guardar en Firestore.
      await _recordatorioService.guardar(resultado);

      // Programar la notificación local.
      await NotificacionRecordatorioService.programar(
        resultado,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Recordatorio creado correctamente.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo crear el recordatorio: $e',
          ),
        ),
      );
    } finally {
      tituloController.dispose();
      descripcionController.dispose();
    }
  }

  Future<void> _eliminarRecordatorio(
      Recordatorio recordatorio,
      ) async {
    try {
      // Cancelar la notificación del dispositivo.
      await NotificacionRecordatorioService.cancelar(
        recordatorio.id,
      );

      // Eliminar el documento de Firestore.
      await _recordatorioService.eliminar(
        recordatorio.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Recordatorio eliminado correctamente.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al eliminar el recordatorio: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis recordatorios'),
      ),
      body: StreamBuilder<List<Recordatorio>>(
        stream: _recordatorioService.obtenerTodos(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error al cargar los recordatorios. '
                    'Verifica tu conexión y las reglas de Firestore.',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final recordatorios = snapshot.data ?? [];

         /* _recordatorioService.marcarVencidosComoNotificados(
            recordatorios,
          ).catchError((error) {
            debugPrint('Error al actualizar recordatorios: $error');
          });*/

          if (recordatorios.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                  ),
                  SizedBox(height: 12),
                  Text('Todavía no tienes recordatorios'),
                  Text('Pulsa + para crear uno.'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: recordatorios.length,
            itemBuilder: (context, index) {
              final recordatorio = recordatorios[index];

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(
                      Icons.notifications_active,
                    ),
                  ),
                  title: Text(recordatorio.titulo),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (recordatorio.descripcion.isNotEmpty)
                        Text(recordatorio.descripcion),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm')
                            .format(recordatorio.fechaHora),
                      ),
                      if (recordatorio.notificado)
                        const Text(
                          '✓ Notificación enviada',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),

                  trailing: IconButton(
                    tooltip: 'Eliminar recordatorio',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () =>
                        _eliminarRecordatorio(recordatorio),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _crearRecordatorio,
        tooltip: 'Crear recordatorio',
        child: const Icon(Icons.add),
      ),
    );
  }
}
