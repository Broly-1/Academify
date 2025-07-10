import 'package:flutter/material.dart';
import 'package:tuition_app/services/auth/auth_service.dart';
import 'package:tuition_app/services/auth/auth_user.dart';
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
                    return const TeacherView();
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
