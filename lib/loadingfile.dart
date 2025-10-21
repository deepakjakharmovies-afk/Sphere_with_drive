import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app/auth_service.dart';
import 'package:app/loginpage.dart';
import 'package:app/mainscreen.dart';
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        // If AuthService provides a loading/checking flag, use it to show a loading screen:
        // if (authService.isChecking) {
        //   return const BouncingBallLoadingScreen();
        // }

        if (authService.isAuthenticated) {
          return const HomeScreen();
        }
        
        // Otherwise, show the login screen
        return const LoginScreen();
      },
    );
  }
}

class BouncingBallLoadingScreen extends StatefulWidget {
  const BouncingBallLoadingScreen({super.key});

  @override
  State<BouncingBallLoadingScreen> createState() =>
      _BouncingBallLoadingScreenState();
}

class _BouncingBallLoadingScreenState extends State<BouncingBallLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _ballAnimation;
  late Animation<double> _logoAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _ballAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.bounceOut),
      ),
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToNextScreen();
      }
    });
  }

  Future<void> _navigateToNextScreen() async {
    // await Future.delayed(const Duration(milliseconds: 500));

    // final authService = Provider.of<AuthService>(context, listen: false);
    // final nextScreen =
    //     authService.isAuthenticated ? const HomeScreen() : const LoginScreen();
    final nextScreen = const AuthWrapper(); 
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    const ballSize = 60.0;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final topPosition = screenHeight * 0.5 +
              (screenHeight * 0.5) * _ballAnimation.value -
              ballSize / 2;

          return Stack(
            children: [
              Positioned(
                left: MediaQuery.of(context).size.width / 2 - ballSize / 2,
                top: topPosition,
                child: Opacity(
                  opacity: 1.0 - _logoAnimation.value,
                  child: Container(
                    width: ballSize,
                    height: ballSize,
                    decoration: const BoxDecoration(
                      color: Colors.indigo,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Center(
                child: Opacity(
                  opacity: _logoAnimation.value,
                  child: ClipOval(child: Image.asset('assets/images/logo.png', width: 200)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
