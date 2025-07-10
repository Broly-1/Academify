import 'package:flutter/material.dart';
import 'package:tuition_app/services/auth/auth_service.dart';
import 'package:tuition_app/services/auth/auth_user.dart';
import 'package:tuition_app/services/teacher_service.dart';
import 'package:tuition_app/views/login_view.dart';
import 'package:tuition_app/views/owner/dashboard.dart';
import 'package:tuition_app/views/teacher/dashboard.dart';

import 'constants/routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        Owner: (context) => const OwnerView(),
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
      // If there's an error, we'll still let them proceed
      // The error could be because the profile already exists
      print('Error creating teacher profile: $e');
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
