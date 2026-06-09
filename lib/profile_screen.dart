
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:abarrotes_app/history_screen.dart';
import 'package:abarrotes_app/user_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String displayName = user?.displayName ?? user?.email ?? 'Usuario';
    final bool isAdmin = Provider.of<UserProvider>(context, listen: false).isAdmin;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA), // Un fondo gris claro
      appBar: AppBar(
        title: const Text(
          'Perfil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.lightBlue,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              children: [
                const SizedBox(height: 40),
                _buildProfileCard(
                  context,
                  icon: Icons.person_outline,
                  title: displayName,
                  subtitle: isAdmin ? 'Administrador' : 'Cliente',
                  onTap: () {},
                ),
                const SizedBox(height: 25),
                if (!isAdmin) // Solo muestra el historial si no es admin
                  _buildProfileCard(
                    context,
                    icon: Icons.receipt_long_outlined,
                    title: 'Pagos y compras',
                    subtitle: 'Historial de transacciones',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HistoryScreen()),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      elevation: 5,
      shadowColor: Colors.black.withOpacity(0.1),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 25.0, horizontal: 20.0),
        leading: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.lightBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Icon(icon, color: Colors.lightBlue, size: 30),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
