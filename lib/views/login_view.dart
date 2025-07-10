import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tuition_app/firebase_options.dart';
import 'package:tuition_app/services/auth/auth_service.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Center(child: const Text('Login'))),

      body: FutureBuilder(
        future: Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              return Column(
                children: [
                  TextField(
                    controller: _email,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                    ),
                    autocorrect: false,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  TextField(
                    controller: _password,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                    ),
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                  ),
                  TextButton(
                    onPressed: () async {
                      final email = _email.text;
                      final password = _password.text;

                      try {
                        await AuthService.firebase().logIn(
                          email: email,
                          password: password,
                        );

                        // Navigation will be handled automatically by the StreamBuilder in main.dart
                        // Optional: Show success SnackBar
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Welcome, $email!')),
                          );
                        }
                      } catch (e) {
                        String errorMessage;
                        if (e.toString().contains('invalid-credential')) {
                          errorMessage = 'Invalid email or password.';
                        } else {
                          errorMessage = 'Login failed: ${e.toString()}';
                        }

                        if (mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(errorMessage)));
                        }
                      }
                    },
                    child: const Text('Login'),
                  ),
                ],
              );
            default:
              return const Text('loading...');
          }
        },
      ),
    );
  }
}
