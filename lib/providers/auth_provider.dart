import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthProvider with ChangeNotifier {
  static const String baseUrl = "https://www.jobportal.shreejifintech.com/api/auth";
  //static const String baseUrl = "http://192.168.1.10:8000/api/auth";


  String? _token;
  bool get isLoggedIn => _token != null;
  String? _userName;
  String? _userEmail;

  bool get isAuthenticated => _token != null;
  String? get userName => _userName;
  String? get userEmail => _userEmail;

  // --- Load Token on App Start ---
  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _userName = prefs.getString('user_name');
    _userEmail = prefs.getString('user_email');
    notifyListeners();

    if (_token != null) {
      syncFCMToken();
    }
  }

  // --- 1. Register with Files ---
  Future<bool> registerCandidate({
    required String email,
    required String username,
    required String password,
    required String fullName,
    required String headline,
    required String location,
    required String qualification,
    required List<String> categories,
    required List<String> skills,
    File? profileImage,
    String? resumePath,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/register/'));

      request.fields['email'] = email;
      request.fields['username'] = username;
      request.fields['password'] = password;
      request.fields['fullName'] = fullName;
      request.fields['headline'] = headline;
      request.fields['location'] = location;
      request.fields['qualification'] = qualification;
      request.fields['category'] = categories.join(',');
      request.fields['skills'] = skills.join(',');

      if (profileImage != null) {
        request.files.add(await http.MultipartFile.fromPath('profileImage', profileImage.path));
      }
      if (resumePath != null && resumePath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('resumePath', resumePath));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return true;
      } else {
        debugPrint("Register Error: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Register Exception: $e");
      return false;
    }
  }

  // --- 2. Verify OTP ---
  Future<bool> verifyOtp(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-otp/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "otp": otp}),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Verify OTP Exception: $e");
      return false;
    }
  }

  // --- 3. Resend OTP ---
  Future<bool> resendOtp(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/resend-otp/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Resend OTP Exception: $e");
      return false;
    }
  }

  // --- 🚀 4. UPDATED LOGIN LOGIC (Returns String instead of bool) ---
  Future<String> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Success Logic
        await _saveUserData(data['token'], data['name'], data['email']);
        syncFCMToken();
        return "success";
      } else {
        // Error Logic: Backend se specific error message uthayega
        // Example: {"error": "Invalid password"} or {"error": "User not found"}
        debugPrint("Login Error Body: ${response.body}");
        return data['error'] ?? data['message'] ?? "Login failed";
      }
    } catch (e) {
      debugPrint("Login Exception: $e");
      return "Connection error. Please try again.";
    }
  }

  // --- 5. Google Login ---
  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
          serverClientId: '718006320227-rbl68smelp6p4j86epfcdpjil7445tk4.apps.googleusercontent.com'
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/google-login/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": googleUser.email,
          "fullName": googleUser.displayName ?? "Google User",
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveUserData(data['token'], data['name'], data['email']);
        syncFCMToken();
        return true;
      } else {
        debugPrint("Google Backend Error: ${response.body}");
        await googleSignIn.signOut();
        return false;
      }
    } catch (e) {
      debugPrint("Google Sign In Exception: $e");
      return false;
    }
  }

  // --- Helper: Save Data ---
  Future<void> _saveUserData(String token, String name, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_name', name);
    await prefs.setString('user_email', email);

    _token = token;
    _userName = name;
    _userEmail = email;
    notifyListeners();
  }

  // --- Logout ---
  // Future<void> logout() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.remove('auth_token');
  //   await prefs.remove('user_name');
  //   await prefs.remove('user_email');
  //
  //   final GoogleSignIn googleSignIn = GoogleSignIn();
  //   if (await googleSignIn.isSignedIn()) {
  //     await googleSignIn.signOut();
  //   }
  //
  //   _token = null;
  //   _userName = null;
  //   _userEmail = null;
  //   notifyListeners();
  // }

  // --- 🚀 FULLY FIXED LOGOUT ---
  Future<void> logout() async {
    // 1. Backend API ko batao ki FCM token delete karna hai
    if (_token != null) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/logout/'), // 👈 Naya API endpoint jo humne banaya
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Token $_token"
          },
        );
        if (response.statusCode == 200) {
          debugPrint("✅ Backend se Logout success & Token cleared.");
        }
      } catch (e) {
        debugPrint("Logout API Error: $e");
      }
    }

    // 2. Firebase ke andar se push notification token completely hatana
    try {
      await FirebaseMessaging.instance.deleteToken();
      debugPrint("✅ Firebase Token Deleted from Phone.");
    } catch (e) {
      debugPrint("Error deleting FCM Token: $e");
    }

    // 3. Local data saaf karo
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // 4. Google account se logout
    final GoogleSignIn googleSignIn = GoogleSignIn();
    if (await googleSignIn.isSignedIn()) {
      await googleSignIn.signOut();
    }

    // 5. App ka state clear karo
    _token = null;
    _userName = null;
    _userEmail = null;
    notifyListeners();
  }

  // --- FCM Token Sync ---
  Future<void> syncFCMToken() async {
    if (_token == null) return;

    try {
      String? currentToken = await FirebaseMessaging.instance.getToken();

      if (currentToken == null || currentToken.isEmpty) return;

      final url = Uri.parse('$baseUrl/update-fcm-token/');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $_token',
        },
        body: jsonEncode({'fcm_token': currentToken}),
      );

      if (response.statusCode == 200) {
        debugPrint("✅ Token synced!");
      } else {
        debugPrint("❌ Token Sync Failed: ${response.body}");
      }
    } catch (e) {
      debugPrint("🔥 FCM Token Sync Crash: $e");
    }
  }

  // --- Update Profile ---
  Future<bool> updateProfile({
    required String fullName,
    required String headline,
    required String location,
    required String qualification,
    required List<String> categories,
    required String skills,
    File? profileImage,
    String? resumePath,
  }) async {
    final url = Uri.parse('$baseUrl/update-profile/');

    try {
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Token $_token';

      request.fields['fullName'] = fullName;
      request.fields['headline'] = headline;
      request.fields['location'] = location;
      request.fields['qualification'] = qualification;
      request.fields['category'] = categories.join(',');
      request.fields['skills'] = skills;

      if (profileImage != null) {
        request.files.add(await http.MultipartFile.fromPath('profileImage', profileImage.path));
      }
      if (resumePath != null) {
        request.files.add(await http.MultipartFile.fromPath('resumePath', resumePath));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Update Profile Error: $e");
      return false;
    }
  }

  // --- Reset Password ---
  Future<bool> resetPassword(String email, String otp, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'new_password': newPassword,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Reset Password Exception: $e");
      return false;
    }
  }
}