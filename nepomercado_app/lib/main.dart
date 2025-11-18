import 'package:flutter/material.dart';
import 'package:nepomercado_app/models/product.dart';
import 'package:nepomercado_app/screens/auth/reset_password_screen.dart';
import 'package:nepomercado_app/screens/auth/verify_code_screen.dart';
import 'package:nepomercado_app/screens/products/edit_product_screen.dart';
import 'package:nepomercado_app/screens/products/search_screen.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/products/liked_products_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthService(),
      child: MaterialApp(
        title: 'Nepomercado',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => LoginScreen(
                onRegisterPressed: () =>
                    Navigator.pushReplacementNamed(context, '/register'),
                      onForgotPassword: () =>
            Navigator.pushNamed(context, '/forgot-password'),
              ),
          '/register': (context) => RegisterScreen(
                onLoginPressed: () =>
                    Navigator.pushReplacementNamed(context, '/login'),
              ),
          '/home': (context) => const HomeScreen(),
          // ✅ NUEVAS RUTAS
          '/liked-products': (context) => const LikedProductsScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/search': (context) => const SearchScreen(),
          'edit-product': (context) {
            final product = ModalRoute.of(context)!.settings.arguments as Product;
            return EditProductScreen(product: product);
          },

        },
        // ✅ MEJORA: Manejar rutas con parámetros
        onGenerateRoute: (settings) {
          // Para rutas que necesitan parámetros como verify-code y reset-password
          if (settings.name == '/verify-code') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => VerifyCodeScreen(phone: args['phone']),
            );
          }
          if (settings.name == '/reset-password') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => ResetPasswordScreen(tempToken: args['tempToken']),
            );
          }
          return null;
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return FutureBuilder<bool>(
          future: authService.isLoggedIn(),
          builder: (context, snapshot) {
            // Mostrar loading solo mientras verifica el login
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Cargando...'),
                    ],
                  ),
                ),
              );
            }

            // ✅ MEJORA: Usuario NO necesita estar logueado para ver productos
            // Siempre mostrar HomeScreen, el login será opcional
            return const HomeScreen();
            
            // ❌ CÓDIGO ANTERIOR (comentado):
            // final isLoggedIn = snapshot.data ?? false;
            // if (isLoggedIn) {
            //   return const HomeScreen();
            // } else {
            //   return LoginScreen(
            //     onRegisterPressed: () =>
            //         Navigator.pushReplacementNamed(context, '/register'),
            //   );
            // }
          },
        );
      },
    );
  }
}