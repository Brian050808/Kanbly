import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controlador/auth_controller.dart';
import '../utilerias/validators.dart';

const Color _azulCielo = Color(0xFF52ABEB);
const Color _verdeTurquesa = Color(0xFF63D0A1);
const Color _blanco = Color(0xFFFCFDFD);
const Color _grisOscuro = Color(0xFF1E293B);

class EditarPerfilView extends StatefulWidget {
  const EditarPerfilView({super.key});

  @override
  State<EditarPerfilView> createState() => _EditarPerfilViewState();
}

class _EditarPerfilViewState extends State<EditarPerfilView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;

  @override
  void initState() {
    super.initState();
    final authController = Provider.of<AuthController>(context, listen: false);
    _nombreController = TextEditingController(text: authController.userName);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authController = Provider.of<AuthController>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final exito = await authController.actualizarNombre(_nombreController.text);

    if (!mounted) return;

    if (exito) {
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Tus datos se actualizaron correctamente'), backgroundColor: Colors.green),
      );
    } else {
      final mensaje = authController.errorMessage ?? 'No se pudo actualizar tu información';
      authController.clearError();
      messenger.showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    return Scaffold(
      backgroundColor: _blanco,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          title: const Text('Editar Perfil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [_azulCielo, _verdeTurquesa], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
          ),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: authController.isLoading ? null : () => Navigator.pop(context),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Nombre Completo',
                  style: TextStyle(color: _grisOscuro, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nombreController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline, color: _azulCielo),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _verdeTurquesa.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _verdeTurquesa.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _verdeTurquesa, width: 2),
                    ),
                    filled: true,
                    fillColor: _blanco,
                  ),
                  validator: Validators.validateName,
                  enabled: !authController.isLoading,
                ),
                const SizedBox(height: 8),
                Text(
                  'El correo institucional no se puede modificar porque está ligado a tu cuenta de acceso.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: authController.isLoading ? null : _guardarCambios,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _verdeTurquesa,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: authController.isLoading
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : const Text(
                      'Actualizar',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}