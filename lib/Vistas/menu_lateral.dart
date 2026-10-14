import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../controlador/auth_controller.dart';
import 'mis_tableros.dart';
import 'login_view.dart';
import './invitaciones_page.dart';
import './ajustes_page.dart';

class MenuLateral extends StatelessWidget {
  const MenuLateral({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyleTile = TextStyle(
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.w600,
    );

    return Drawer(
      backgroundColor: theme.drawerTheme.backgroundColor ?? theme.cardColor,
      child: Column(
        children: [
          // --- ENCABEZADO CON DEGRADADO OFICIAL DE KANBLY Y PROVEEDOR DE AUTH ---
          Consumer<AuthController>(
            builder: (context, authController, child) {
              final usuario = authController.usuarioActual;
              final String nombreUsuario = authController.userName;
              final String correoUsuario = authController.userEmail.isNotEmpty
                  ? authController.userEmail
                  : (FirebaseAuth.instance.currentUser?.email ?? 'usuario@e.uttecamac.edu.mx');
              final String? fotoUrl = usuario?.fotoPerfil;

              return DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF52ABEB), Color(0xFF63D0A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white,
                        backgroundImage: (fotoUrl != null && fotoUrl.isNotEmpty)
                            ? NetworkImage(fotoUrl) as ImageProvider
                            : null,
                        child: (fotoUrl == null || fotoUrl.isEmpty)
                            ? Text(
                                nombreUsuario.isNotEmpty ? nombreUsuario[0].toUpperCase() : 'K',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF52ABEB),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        nombreUsuario,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        correoUsuario,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xDEFFFFFF),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // --- OPCIÓN 1: MIS TABLEROS ---
          ListTile(
            leading: const Icon(Icons.dashboard_outlined, color: Color(0xFF37B5F4)),
            title: Text('Mis Tableros', style: textStyleTile),
            onTap: () {
              Navigator.pop(context); // Cerramos el menú lateral
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MisTableros()),
                (route) => false,
              );
            },
          ),

          // --- OPCIÓN 2: INVITACIONES ---
          ListTile(
            leading: const Icon(Icons.mail_outline, color: Color(0xFF52ABEB)),
            title: Text('Invitaciones', style: textStyleTile),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InvitacionesPage(),
                ),
              );
            },
          ),

          // --- OPCIÓN 3: AJUSTES Y PERFIL ---
          ListTile(
            leading: const Icon(Icons.tune_rounded, color: Color(0xFF63D0A1)),
            title: Text('Ajustes', style: textStyleTile),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AjustesPage(),
                ),
              );
            },
          ),

          const Divider(indent: 16, endIndent: 16),

          const Spacer(),
          const Divider(indent: 16, endIndent: 16),

          // --- OPCIÓN FINAL: CERRAR SESIÓN ---
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text(
              'Cerrar Sesión',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () => _confirmarCerrarSesion(context),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Cuadro de diálogo para confirmar el cierre de sesión en Firebase y Provider
  void _confirmarCerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text('Se cerrará tu sesión actual en Kanbly.'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              final authController = Provider.of<AuthController>(context, listen: false);

              try {
                await authController.logout();
              } catch (e) {
                await FirebaseAuth.instance.signOut();
              }

              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginView()),
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Salir',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
