import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/auth/auth_bloc.dart';
import '../../application/auth/auth_event.dart';
import '../../application/auth/auth_state.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/loading_overlay.dart';
import '../../domain/entities/auth_request.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      final registerRequest = RegisterRequest(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        firstName:
            _firstNameController.text.trim().isEmpty
                ? null
                : _firstNameController.text.trim(),
        lastName:
            _lastNameController.text.trim().isEmpty
                ? null
                : _lastNameController.text.trim(),
      );

      context.read<AuthBloc>().add(RegisterRequested(registerRequest));
    }
  }

  bool _validatePassword(String password) {
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'\d').hasMatch(password) &&
        RegExp(r'[@$!%*?&]').hasMatch(password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is AuthAuthenticated) {
            Navigator.pop(context);
          }
        },
        builder: (context, state) {
          return LoadingOverlay(
            isLoading: state is AuthLoading,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      const Icon(
                        Icons.person_add_rounded,
                        size: 60,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Join Us Today',
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your account to get started',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Username Field
                      CustomTextField(
                        controller: _usernameController,
                        label: 'Username',
                        hintText: 'Choose a username',
                        prefixIcon: Icons.person_outline,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter a username';
                          }
                          if (value!.length < 3 || value.length > 30) {
                            return 'Username must be 3-30 characters';
                          }
                          if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                            return 'Username can only contain letters, numbers, and underscores';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email Field
                      CustomTextField(
                        controller: _emailController,
                        label: 'Email',
                        hintText: 'Enter your email',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value!)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Name Fields Row
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _firstNameController,
                              label: 'First Name',
                              hintText: 'Optional',
                              prefixIcon: Icons.badge_outlined,
                              validator: (value) {
                                if (value != null &&
                                    value.isNotEmpty &&
                                    (value.length < 2 || value.length > 50)) {
                                  return 'Must be 2-50 characters';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              controller: _lastNameController,
                              label: 'Last Name',
                              hintText: 'Optional',
                              prefixIcon: Icons.badge_outlined,
                              validator: (value) {
                                if (value != null &&
                                    value.isNotEmpty &&
                                    (value.length < 2 || value.length > 50)) {
                                  return 'Must be 2-50 characters';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      CustomTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hintText: 'Create a password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscurePassword,
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
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter a password';
                          }
                          if (!_validatePassword(value!)) {
                            return 'Password must be at least 8 characters with uppercase, lowercase, number and special character';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password Field
                      CustomTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        hintText: 'Repeat your password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscureConfirmPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Register Button
                      CustomButton(
                        text: 'Create Account',
                        onPressed: _handleRegister,
                        isLoading: state is AuthLoading,
                      ),
                      const SizedBox(height: 24),

                      // Back to Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                color: Colors.blue[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
