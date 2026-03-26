import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/transaction_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/marketplace_screen.dart';
import 'screens/energy_prediction_screen.dart';
import 'screens/energy_forecasting_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SustainX EnergyPass',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/auth': (_) => const AuthScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/transactions': (_) => const TransactionScreen(),
        '/leaderboard': (_) => const LeaderboardScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/marketplace': (_) => const MarketplaceScreen(),
        '/prediction': (_) => const EnergyPredictionScreen(),
        '/forecasting': (_) => const EnergyForecastingScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final token = await ApiService.getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/auth');
    } else {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
