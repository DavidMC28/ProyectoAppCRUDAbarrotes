
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'food_screen.dart';
import 'shop_screen.dart';
import 'user_provider.dart';
import 'cart_screen.dart';
import 'history_screen.dart';
import 'package:abarrotes_app/profile_screen.dart';
import 'package:abarrotes_app/reports_screen.dart'; // Importa la nueva pantalla de reportes

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => CartProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primarySeedColor = Colors.blue;

    return MaterialApp(
      title: 'Abarrotes App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primarySeedColor,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: primarySeedColor,
          foregroundColor: Colors.white,
          titleTextStyle: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: primarySeedColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.lightBlue, // Color de fondo celeste
          selectedItemColor: Colors.white, // Color de los íconos seleccionados
          unselectedItemColor: Colors.white70, // Color de los íconos no seleccionados
        ),
      ),
      themeMode: ThemeMode.light,
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          if (!snapshot.data!.isAnonymous) {
            Provider.of<UserProvider>(context, listen: false).login(false);
          }
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _authenticate(Future<void> Function() authMethod) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      await authMethod();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Ocurrió un error')),
        );
      }
    } catch (e) {
        if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Un error inesperado ocurrió: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isLogin ? 'Bienvenido' : 'Crear Cuenta',
                      style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: CircularProgressIndicator(),
                      )
                    else ...[
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                           final authAction = _isLogin
                              ? () => FirebaseAuth.instance.signInWithEmailAndPassword(
                                    email: _emailController.text.trim(),
                                    password: _passwordController.text.trim(),
                                  )
                              : () => FirebaseAuth.instance.createUserWithEmailAndPassword(
                                    email: _emailController.text.trim(),
                                    password: _passwordController.text.trim(),
                                  );
                          _authenticate(authAction);
                        },
                        child: Text(_isLogin ? 'Iniciar Sesión' : 'Crear Cuenta'),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _isLogin = !_isLogin),
                        child: Text(_isLogin ? '¿No tienes cuenta? Regístrate' : '¿Ya tienes cuenta? Inicia sesión'),
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.admin_panel_settings),
                        label: const Text('Iniciar como Administrador'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800),
                        onPressed: () {
                          _authenticate(() async {
                            await FirebaseAuth.instance.signInAnonymously();
                            userProvider.login(true); // Es admin
                          });
                        },
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Lista de widgets para el admin
  static const List<Widget> _adminWidgetOptions = <Widget>[
    HomeContent(),
    ProfileScreen(),
  ];

  // Lista de widgets para el cliente
  static const List<Widget> _clientWidgetOptions = <Widget>[
    HomeContent(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = Provider.of<UserProvider>(context).isAdmin;

    final List<Widget> widgetOptions = isAdmin ? _adminWidgetOptions : _clientWidgetOptions;

    final List<BottomNavigationBarItem> navBarItems = isAdmin
        ? const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
          ]
        : const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.history), label: 'Historial'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
          ];

    // Asegurarse de que el índice seleccionado no esté fuera de los límites
    if (_selectedIndex >= widgetOptions.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Abarrotes App (Admin)' : 'Abarrotes App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: navBarItems,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdmin = Provider.of<UserProvider>(context, listen: false).isAdmin;
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: _buildGridItems(context, isAdmin),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGridItems(BuildContext context, bool isAdmin) {
    if (isAdmin) {
      // Tarjetas para el admin
      return [
        _buildGridItem(
          context,
          icon: Icons.analytics,
          label: 'Reportes',
          color: Colors.purple,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReportsScreen()), // Navega a la pantalla de reportes
            );
          },
        ),
        _buildGridItem(
          context,
          icon: Icons.restaurant,
          label: 'Comida',
          color: Colors.orange,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FoodScreen()),
            );
          },
        ),
        _buildGridItem(
          context,
          icon: Icons.shopping_basket,
          label: 'Shop',
          color: Colors.yellow.shade700,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ShopScreen()),
            );
          },
        ),
      ];
    } else {
      // Tarjetas para el cliente
      return [
        _buildGridItem(
          context,
          icon: Icons.shopping_cart,
          label: 'Carrito',
          color: Colors.red,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartScreen()),
            );
          },
        ),
        _buildGridItem(
          context,
          icon: Icons.restaurant,
          label: 'Comida',
          color: Colors.orange,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FoodScreen()),
            );
          },
        ),
        _buildGridItem(
          context,
          icon: Icons.delivery_dining,
          label: 'Entrega',
          color: Colors.grey,
          onTap: () {},
        ),
        _buildGridItem(
          context,
          icon: Icons.shopping_basket,
          label: 'Shop',
          color: Colors.yellow.shade700,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ShopScreen()),
            );
          },
        ),
      ];
    }
  }


   Widget _buildGridItem(BuildContext context,
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        elevation: 5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 40.0, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Buscar...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
        filled: true,
      ),
    );
  }
}

class PlaceholderWidget extends StatelessWidget {
  final String text;
  const PlaceholderWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(text),
    );
  }
}
