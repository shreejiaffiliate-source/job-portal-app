import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jobportal/screens/reset_password_screen.dart';
import 'package:provider/provider.dart';

// 🚀 Naye Imports
import '../providers/auth_provider.dart';
import 'login_screen.dart'; // Isse add kiya
import 'home_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final bool isPasswordReset;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.isPasswordReset = false,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool _isLoading = false;
  Timer? _timer;
  int _start = 120;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    setState(() => _start = 120);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        if (mounted) setState(() => timer.cancel());
      } else {
        if (mounted) setState(() => _start--);
      }
    });
  }

  String get _timerText {
    int minutes = _start ~/ 60;
    int seconds = _start % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get _fullOtp => _controllers.map((e) => e.text).join();

  void _handleResend() async {
    if (_start > 0 || _isResending) return;

    setState(() => _isResending = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.resendOtp(widget.email);

    if (mounted) {
      setState(() => _isResending = false);
      if (success) {
        _startTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP Resent Successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to resend OTP.")),
        );
      }
    }
  }

  void _handleVerify() async {
    if (_fullOtp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter all 6 digits")));
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    bool success = await authProvider.verifyOtp(widget.email, _fullOtp);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        if (widget.isPasswordReset) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResetPasswordScreen(
                email: widget.email,
                otp: _fullOtp,
              ),
            ),
          );
        } else {
          // 🚀 Registration flow fix: Direct Home ki jagah Login par bhej rahe hain
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Email Verified! Please Login to continue."),
              backgroundColor: Colors.green,
            ),
          );

          // Saari screens hatakar seedha LoginScreen par jao
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid OTP. Please try again.")));
      }
    }
  }

  // --- UI Widgets remain the same ---
  Widget _buildOtpBox(int index, Color textColor, Color cardColor) {
    return SizedBox(
      width: 45,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: cardColor,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.indigo, width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _focusNodes[index].unfocus();
            }
          } else {
            if (index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.isPasswordReset ? "Reset Password" : "Verify Email",
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: Theme.of(context).iconTheme,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.mark_email_read_outlined, size: 80, color: Colors.indigo),
              const SizedBox(height: 24),
              Text(
                widget.isPasswordReset ? "Security Verification" : "Enter Verification Code",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                  children: [
                    const TextSpan(text: "We have sent a 6-digit code to\n"),
                    TextSpan(
                      text: widget.email,
                      style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) => _buildOtpBox(index, textColor, cardColor)),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleVerify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : Text(
                    widget.isPasswordReset ? "Verify & Proceed" : "Verify & Go to Login",
                    style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _isResending
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Didn't receive code? ", style: TextStyle(color: Colors.grey.shade600)),
                  TextButton(
                    onPressed: _start == 0 ? _handleResend : null,
                    child: Text(
                      _start == 0 ? "Resend Now" : "Resend in $_timerText",
                      style: TextStyle(
                        color: _start == 0 ? Colors.indigo : Colors.grey.shade400,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}