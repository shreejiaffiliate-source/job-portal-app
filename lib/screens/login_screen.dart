import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'otp_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isObscured = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  // 🚀 Logic updated to handle specific error strings
  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 🎯 Note: Ab ye result ek String return karega (Success ya Error Message)
    String result = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result == "success") {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
      );
    } else {
      // 🚀 Specific Messages Logic
      String finalMessage = "An error occurred";

      if (result.contains("password")) {
        finalMessage = "Password incorrect";
      } else if (result.contains("user") || result.contains("email")) {
        finalMessage = "Email/Username is incorrect";
      } else if (result.contains("verified")) {
        finalMessage = "Your account is not verified";

        // 💡 Pro-tip: Agar account verified nahi hai toh seedha OTP screen par bhejne ka option:
        /*
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(email: _emailController.text.trim())
        ));
        */
      } else {
        finalMessage = result; // Fallback to original message
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(finalMessage),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _handleGoogleLogin() async {
    setState(() => _isGoogleLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    bool success = await authProvider.signInWithGoogle();

    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Google Sign-In failed or was canceled.")),
      );
    }
  }

  // --- Forgot Password Dialog logic (Unchanged) ---
  void _showForgotPasswordDialog(BuildContext context) {
    final TextEditingController forgotEmailController = TextEditingController();
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final cardColor = Theme.of(context).cardColor;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Reset Password", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  "Enter your email to receive a verification OTP.",
                  style: TextStyle(color: Colors.grey.shade600)
              ),
              const SizedBox(height: 16),
              TextField(
                controller: forgotEmailController,
                style: TextStyle(color: textColor),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "Email Address",
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: const Icon(Icons.email_outlined, color: Colors.indigo),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300)
                  ),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel", style: TextStyle(color: Colors.grey))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                String email = forgotEmailController.text.trim();
                if (email.isEmpty || !email.contains('@')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter a valid email address.")),
                  );
                  return;
                }

                showDialog(
                  context: ctx,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                );

                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                bool sent = await authProvider.resendOtp(email);

                if (!context.mounted) return;
                Navigator.pop(ctx);

                if (sent) {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OtpVerificationScreen(
                        email: email,
                        isPasswordReset: true,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to send OTP. Please check the email and try again.")),
                  );
                }
              },
              child: const Text("Send OTP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;

          final bool shouldExit = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              title: const Text("Exit App", style: TextStyle(fontWeight: FontWeight.bold)),
              content: const Text("Do you really want to exit?"),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("No")),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text("Yes", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ) ?? false;

          if (shouldExit) {
            SystemNavigator.pop();
          }
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: const Icon(Icons.work_outline, size: 60, color: Colors.indigo),
                      ),
                      const SizedBox(height: 16),
                      Text("Government Job Portal",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                Text("Welcome Back", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                Text("Login to your account to continue", style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 32),

                _buildTextField("Username or Email", _emailController, Icons.email_outlined),
                _buildPasswordField(),

                Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                        onPressed: () => _showForgotPasswordDialog(context),
                        child: const Text("Forgot Password?", style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold))
                    )
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Login", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text("OR", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                ),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _isGoogleLoading ? null : _handleGoogleLogin,
                    icon: Image.asset('lib/assets/images/google_logo.png', height: 24, width: 24),
                    label: Text("Continue with Google", style: TextStyle(fontSize: 16, color: textColor)),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?", style: TextStyle(color: textColor)),
                    TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                        },
                        child: const Text("Register", style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold))
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
        )
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(icon, color: Colors.indigo.shade300),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Theme.of(context).cardColor,
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: TextFormField(
        controller: _passwordController,
        obscureText: _isObscured,
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        decoration: InputDecoration(
          labelText: "Password",
          labelStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.lock_outline, color: Colors.indigo.shade300),
          suffixIcon: IconButton(
            icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
            onPressed: () => setState(() => _isObscured = !_isObscured),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Theme.of(context).cardColor,
        ),
      ),
    );
  }
}