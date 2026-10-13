import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../controlador/auth_controller.dart';
import '../modelo/invitacion.dart';
import '../modelo/tablero.dart';
import '../modelo/tarea.dart';
import '../servicios/firestore_service.dart';
import 'editar_perfil_view.dart';
import 'login_view.dart';

// ✅ COLORES OFICIALES DE KANBLY (mismos de login/registro)
const Color _azulCielo = Color(0xFF52ABEB);
const Color _verdeTurquesa = Color(0xFF63D0A1);
const Color _verdeAgua = Color(0xFF63B09C);
const Color _blanco = Color(0xFFFCFDFD);
const Color _grisOscuro = Color(0xFF1E293B);

class PerfilUsuarioView extends StatefulWidget {
  const PerfilUsuarioView({super.key});

  @override
  State<PerfilUsuarioView> createState() => _PerfilUsuarioViewState();
}

class _PerfilUsuarioViewState extends State<PerfilUsuarioView> {
  final FirestoreService _firestoreService = FirestoreService();

  List<Tablero> _tableros = [];
  List<Tarea> _tareas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final tableros = await _firestoreService.obtenerTablerosDeUsuario(uid);
      final tareas = await _firestoreService.obtenerTareasCreadasPorUsuario(uid);

      if (!mounted) return;
      setState(() {
        _tableros = tableros;
        _tareas = tareas;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar tu actividad: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final usuario = authController.usuarioActual;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: _blanco,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          title: const Text(
            'Mi Perfil',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_azulCielo, _verdeTurquesa],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: usuario == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _cargarDatos,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _tarjetaDatosPersonales(usuario.nombreCompleto, usuario.email, usuario.rol, usuario.fechaRegistro),
              const SizedBox(height: 24),
              _tituloSeccion('Mis Tableros'),
              const SizedBox(height: 10),
              _cargando ? _cargandoMini() : _seccionTableros(uid),
              const SizedBox(height: 24),
              _tituloSeccion('Progreso de Tareas'),
              const SizedBox(height: 10),
              _cargando ? _cargandoMini() : _seccionProgreso(),
              const SizedBox(height: 24),
              _tituloSeccion('Notificaciones'),
              const SizedBox(height: 10),
              _seccionNotificaciones(uid),
              const SizedBox(height: 32),
              _botonEliminarCuenta(authController),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- TARJETA SUPERIOR: DATOS PERSONALES (editable) ----------
  Widget _tarjetaDatosPersonales(String nombre, String email, String rol, DateTime fechaRegistro) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_azulCielo, _verdeTurquesa],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 36,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: _azulCielo, size: 40),
          ),
          const SizedBox(height: 12),
          Text(
            nombre,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xDEFFFFFF), fontSize: 13),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              _etiquetaBlanca(rol[0].toUpperCase() + rol.substring(1)),
              _etiquetaBlanca('Desde ${DateFormat('dd/MM/yyyy').format(fechaRegistro)}'),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditarPerfilView()),
                );
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _grisOscuro,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Editar datos personales', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _etiquetaBlanca(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(texto, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _tituloSeccion(String titulo) {
    return Text(
      titulo,
      style: const TextStyle(color: _grisOscuro, fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _cargandoMini() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 12),
    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
  );

  // ---------- SECCIÓN: TABLEROS (solo informativo, sin editar/eliminar) ----------
  Widget _seccionTableros(String uid) {
    if (_tableros.isEmpty) {
      return _tarjetaVacia('Aún no participas en ningún tablero.');
    }
    return Column(
      children: _tableros.map((t) {
        final esCreador = t.creadorId == uid;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(
                t.esGrupal ? Icons.groups_rounded : Icons.person_outline_rounded,
                color: t.esGrupal ? _azulCielo : _verdeTurquesa,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.nombre, style: const TextStyle(fontWeight: FontWeight.bold, color: _grisOscuro)),
                    const SizedBox(height: 2),
                    Text(
                      '${t.esGrupal ? "Equipo" : "Individual"} · ${esCreador ? "Creador" : "Miembro"}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ---------- SECCIÓN: PROGRESO DE TAREAS (solo informativo) ----------
  Widget _seccionProgreso() {
    if (_tareas.isEmpty) {
      return _tarjetaVacia('Todavía no has creado ninguna tarea.');
    }
    final completadas = _tareas.where((t) => t.estado == EstadoTarea.completada).length;
    final enProgreso = _tareas.where((t) => t.estado == EstadoTarea.enProgreso).length;
    final pendientes = _tareas.where((t) => t.estado == EstadoTarea.pendiente).length;

    return Row(
      children: [
        _estadistica('Creadas', _tareas.length, _grisOscuro),
        const SizedBox(width: 8),
        _estadistica('Pendientes', pendientes, _grisOscuro),
        const SizedBox(width: 8),
        _estadistica('En progreso', enProgreso, _verdeAgua),
        const SizedBox(width: 8),
        _estadistica('Hechas', completadas, _verdeTurquesa),
      ],
    );
  }

  Widget _estadistica(String etiqueta, int valor, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text('$valor', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(etiqueta, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  // ---------- SECCIÓN: NOTIFICACIONES (invitaciones pendientes en tiempo real) ----------
  Widget _seccionNotificaciones(String uid) {
    return StreamBuilder<List<Invitacion>>(
      stream: _firestoreService.obtenerMisInvitaciones(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _cargandoMini();
        }
        final invitaciones = snapshot.data ?? [];
        if (invitaciones.isEmpty) {
          return _tarjetaVacia('No tienes notificaciones pendientes.');
        }
        return Column(
          children: invitaciones.map((inv) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _azulCielo.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _azulCielo.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mail_outline, color: _azulCielo, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Invitación pendiente al tablero "${inv.tableroNombre}"',
                      style: const TextStyle(fontSize: 13, color: _grisOscuro),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _tarjetaVacia(String mensaje) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
      child: Text(mensaje, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
    );
  }

  // ---------- ZONA DE PELIGRO: ELIMINAR CUENTA ----------
  Widget _botonEliminarCuenta(AuthController authController) {
    return OutlinedButton.icon(
      onPressed: () => _confirmarEliminarCuenta(authController),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.redAccent,
        side: const BorderSide(color: Colors.redAccent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      icon: const Icon(Icons.delete_forever_outlined),
      label: const Text('Eliminar mi cuenta', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  void _confirmarEliminarCuenta(AuthController authController) {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool eliminando = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('¿Eliminar tu cuenta?', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Esta acción es permanente: se borrarán tus datos y no podrás recuperar tu cuenta. '
                      'Confirma tu contraseña para continuar.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: eliminando ? null : () => Navigator.pop(dialogContext),
              child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: eliminando
                  ? null
                  : () async {
                if (!(formKey.currentState?.validate() ?? false)) return;
                setDialogState(() => eliminando = true);

                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                final exito = await authController.eliminarCuenta(passwordController.text);

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext); // cierra el diálogo

                if (exito) {
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginView()),
                        (route) => false,
                  );
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Tu cuenta fue eliminada correctamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  final mensaje = authController.errorMessage ?? 'No se pudo eliminar la cuenta';
                  authController.clearError();
                  messenger.showSnackBar(
                    SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: eliminando
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Text('Eliminar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}