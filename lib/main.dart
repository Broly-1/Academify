// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tuition_app/services/auth/auth_service.dart';
import 'package:tuition_app/services/auth/auth_user.dart';
import 'package:tuition_app/services/teacher_service.dart';
import 'package:tuition_app/views/login_view.dart';
import 'package:tuition_app/views/owner/dashboard.dart';
import 'package:tuition_app/views/teacher/dashboard.dart';

import 'constants/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 216, 35, 35),
        ),
      ),
      home: const HomePage(),
      routes: {
        loginRoute: (context) => const LoginView(),
        owner: (context) => const OwnerView(),
      },
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Method to ensure teacher profile exists when non-owner users log in
  Future<void> _ensureTeacherProfile(AuthUser user) async {
    try {
      final email = user.email ?? '';
      if (email.isNotEmpty) {
        // Extract display name from email (part before @)
        final displayName = email.split('@').first;
        await TeacherService.createOrUpdateTeacherProfile(email, displayName);
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to create or update teacher profile: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AuthService.firebase().initialize(),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.done:
            return StreamBuilder<AuthUser?>(
              stream: AuthService.firebase().authStateChanges(),
              builder: (context, authSnapshot) {
                if (authSnapshot.hasData && authSnapshot.data != null) {
                  final user = authSnapshot.data!;
                  if (user.email == 'hassangaming111@gmail.com') {
                    return const OwnerView();
                  } else {
                    // Automatically create teacher profile for non-owner users
                    return FutureBuilder(
                      future: _ensureTeacherProfile(user),
                      builder: (context, teacherSnapshot) {
                        if (teacherSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Scaffold(
                            body: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text('Setting up your profile...'),
                                ],
                              ),
                            ),
                          );
                        }
                        return const TeacherView();
                      },
                    );
                  }
                } else {
                  return const LoginView();
                }
              },
            );
          default:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
        }
      },
    );
  }
}
