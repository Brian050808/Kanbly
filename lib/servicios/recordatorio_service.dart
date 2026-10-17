
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../modelo/recordatorio.dart';

class RecordatorioService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>>
  _coleccionRecordatorios() {
    final usuario = _auth.currentUser;

    if (usuario == null) {
      throw Exception('Debes iniciar sesión para gestionar recordatorios.');
    }

    return _firestore
        .collection('usuarios')
        .doc(usuario.uid)
        .collection('recordatorios');
  }

  Future<void> guardar(Recordatorio recordatorio) async {
    await _coleccionRecordatorios()
        .doc(recordatorio.id)
        .set(recordatorio.toMap());
  }

  Stream<List<Recordatorio>> obtenerTodos() {
    return _coleccionRecordatorios()
        .snapshots()
        .map((snapshot) {
      final recordatorios = snapshot.docs.map((doc) {
        return Recordatorio.fromMap({
          ...doc.data(),
          'id': doc.id,
        });
      }).toList();

      recordatorios.sort(
            (a, b) => a.fechaHora.compareTo(b.fechaHora),
      );

      return recordatorios;
    });
  }

  Future<void> eliminar(String id) async {
    await _coleccionRecordatorios().doc(id).delete();
  }

  Future<void> marcarComoNotificado(String id) async {
    await _coleccionRecordatorios()
        .doc(id)
        .update({'notificado': true});
  }

  Future<void> marcarVencidosComoNotificados(
      List<Recordatorio> recordatorios,
      ) async {
    final ahora = DateTime.now();

    for (final recordatorio in recordatorios) {
      if (!recordatorio.notificado &&
          !recordatorio.fechaHora.isAfter(ahora)) {
        await marcarComoNotificado(recordatorio.id);
      }
    }
  }

}
