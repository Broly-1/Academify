// ignore_for_file: deprecated_member_use

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:academify/firebase_options.dart';
import 'package:academify/services/auth/auth_service.dart';
import 'package:academify/services/auth/auth_exceptions.dart';
import 'package:academify/utils/ui_utils.dart';
import 'package:academify/utils/form_utils.dart';
import 'package:academify/utils/service_utils.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _email;
  late final TextEditingController _password;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isInitialized = false;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    _initializeFirebase();
    super.initState();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      // Handle initialization error
      if (mounted) {
        UIUtils.showErrorDialog(
          context: context,
          title: 'Initialization Error',
          content: 'Failed to initialize app. Please restart.',
        );
      }
    }
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
      backgroundColor: Colors.grey[50],
      body: _isInitialized
          ? SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo/App Title Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: UIUtils.gradientDecoration(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(100),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: UIUtils.primaryGreen.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.school,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      UIUtils.largeVerticalSpacing,

                      const Text('Academify', style: UIUtils.headingStyle),
                      UIUtils.smallVerticalSpacing,
                      Text(
                        'Tuition Management System',
                        style: UIUtils.bodyStyle.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Login Form
                      UIUtils.createCardContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Welcome Back!',
                              style: UIUtils.headingStyle,
                              textAlign: TextAlign.center,
                            ),
                            UIUtils.smallVerticalSpacing,
                            Text(
                              'Sign in to continue',
                              style: UIUtils.bodyStyle.copyWith(
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            UIUtils.largeVerticalSpacing,

                            // Email Field
                            FormUtils.createTextFormField(
                              label: 'Email',
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              hintText: 'Enter your email address',
                              prefixIcon: const Icon(Icons.email_outlined),
                              validator: FormUtils.validateEmail,
                            ),
                            UIUtils.mediumVerticalSpacing,

                            // Password Field
                            FormUtils.createTextFormField(
                              label: 'Password',
                              controller: _password,
                              obscureText: _obscurePassword,
                              hintText: 'Enter your password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              validator: FormUtils.validatePassword,
                            ),
                            UIUtils.largeVerticalSpacing,

                            // Login Button
                            UIUtils.createPrimaryButton(
                              text: _isLoading ? 'Signing in...' : 'Sign In',
                              onPressed: _isLoading ? () {} : _handleLogin,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Footer
                    ],
                  ),
                ),
              ),
            )
          : UIUtils.createLoadingIndicator(message: 'Initializing...'),
    );
  }

  Future<void> _handleLogin() async {
    final email = _email.text.trim();
    final password = _password.text;

    if (email.isEmpty || password.isEmpty) {
      ServiceUtils.handleServiceError(
        error: 'Please fill in all fields',
        context: context,
        customMessage: 'Please fill in all fields',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.firebase().logIn(email: email, password: password);
    } catch (e) {
      String errorMessage;

      // Handle our custom auth exceptions
      if (e is InvalidCredentialAuthException) {
        errorMessage =
            'Invalid email or password. Please check your credentials.';
      } else if (e is InvalidEmailAuthException) {
        errorMessage = 'Please enter a valid email address.';
      } else if (e is GenericAuthException) {
        errorMessage = 'Authentication failed. Please try again.';
      } else if (e is UserNotLoggedInAuthException) {
        errorMessage = 'Please log in to continue.';
      } else {
        // Fallback for any other exceptions
        errorMessage = 'Login failed. Please try again.';
      }

      if (mounted) {
        UIUtils.showErrorDialog(
          context: context,
          title: 'Login Error',
          content: errorMessage,
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
}
