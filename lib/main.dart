// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Add this import
import 'package:academify/services/auth/auth_service.dart';
import 'package:academify/services/auth/auth_user.dart';
import 'package:academify/services/teacher_service.dart';
import 'package:academify/views/login_view.dart';
import 'package:academify/views/owner/dashboard.dart';
import 'package:academify/views/teacher/dashboard.dart';
import 'constants/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Update this line
  );
  runApp(
    MaterialApp(
      title: 'Academify Tuition Center', // Updated app title
      debugShowCheckedModeBanner: false,
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
        // Check if teacher profile already exists
        final existingTeacher = await TeacherService.getTeacherByEmail(email);

        // Only create profile if it doesn't exist (don't update existing names)
        if (existingTeacher == null) {
          // Extract display name from email (part before @) as fallback only
          final displayName = email.split('@').first;
          await TeacherService.createOrUpdateTeacherProfile(email, displayName);
        }
        // If teacher exists, don't update their name - preserve what was set during creation
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to ensure teacher profile: $e'),
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
                  if (user.email == 'hassangaming111@gmail.com' ||
                      user.email == 'testing@gmail.com') {
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
