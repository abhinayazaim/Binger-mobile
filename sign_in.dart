import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';

class SigninWidget extends StatefulWidget {
  const SigninWidget({super.key});

  @override
  _SigninWidgetState createState() => _SigninWidgetState();
}

class _SigninWidgetState extends State<SigninWidget> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Clear any previous error messages when widget loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<UserProvider>(context, listen: false).clearError();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(245, 196, 24, 1),
        title: const Text(
          'Binger',
          style: TextStyle(fontSize: 32, color: Colors.black),
        ),
        centerTitle: true,
        elevation: 4,
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sign In', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  _buildTextField(
                    controller: _emailController,
                    hint: 'Email',
                    obscureText: false,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(),
                  const SizedBox(height: 16),
                  _buildRememberMeAndForgotPassword(userProvider),
                  if (userProvider.errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          userProvider.errorMessage,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  _buildButton(
                    text: userProvider.isLoading ? 'Signing In...' : 'Sign In',
                    bgColor: Colors.amber,
                    textColor: Colors.black,
                    onTap: userProvider.isLoading
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              try {
                                final success = await userProvider.signIn(
                                  _emailController.text.trim(),
                                  _passwordController.text,
                                );
                                
                                if (success && mounted) {
                                  // Show success message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Sign in successful!'),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  
                                  // Navigate to home page
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/',
                                    (Route<dynamic> route) => false,
                                  );
                                } else if (mounted) {
                                  // Error message will be shown automatically via Consumer
                                  // Just ensure form validation state is reset
                                  _formKey.currentState?.validate();
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Sign in failed: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                  ),
                  const SizedBox(height: 32),
                  _buildDividerWithText('New to Binger?'),
                  const SizedBox(height: 32),
                  _buildButton(
                    text: 'Create Account',
                    bgColor: Colors.black,
                    textColor: Colors.white,
                    onTap: userProvider.isLoading ? null : () {
                      Navigator.pushNamed(context, '/signup');
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool obscureText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        errorMaxLines: 2,
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: 'Password',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        errorMaxLines: 2,
      ),
    );
  }

  Widget _buildRememberMeAndForgotPassword(UserProvider userProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(
              value: _rememberMe,
              onChanged: (value) {
                setState(() {
                  _rememberMe = value!;
                });
              },
            ),
            const Text('Remember Me'),
          ],
        ),
        TextButton(
          onPressed: userProvider.isLoading ? null : () {
            _showForgotPasswordDialog(context, userProvider);
          },
          child: const Text('Forgot password?', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildButton({
    required String text,
    required Color bgColor,
    required Color textColor,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: onTap,
        child: Text(text, style: TextStyle(color: textColor, fontSize: 16)),
      ),
    );
  }

  Widget _buildDividerWithText(String text) {
    return Row(
      children: [
        const Expanded(child: Divider(thickness: 1, color: Colors.amber)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(text, style: const TextStyle(fontSize: 12)),
        ),
        const Expanded(child: Divider(thickness: 1, color: Colors.amber)),
      ],
    );
  }

  void _showForgotPasswordDialog(BuildContext context, UserProvider userProvider) {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Reset Password'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Enter your email address to receive password reset instructions.'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: userProvider.isLoading ? null : () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: userProvider.isLoading ? null : () async {
                    if (formKey.currentState!.validate()) {
                      try {
                        final success = await userProvider.resetPassword(emailController.text.trim());
                        if (mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success 
                                  ? 'Password reset email sent! Check your inbox.'
                                  : userProvider.errorMessage.isNotEmpty 
                                    ? userProvider.errorMessage
                                    : 'Failed to send reset email',
                              ),
                              backgroundColor: success ? Colors.green : Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: userProvider.isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send Reset Email'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      emailController.dispose();
    });
  }
}