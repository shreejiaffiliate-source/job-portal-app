import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/job_model.dart';

class ApiService {
  static const String baseUrl = "https://www.jobportal.shreejifintech.com/api";
  //static const String baseUrl = "http://192.168.1.10:8000/api";


  // --- 🔑 Helper: Attach Secure Token ---
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    // 🎯 FIX: AuthProvider 'auth_token' use karta hai, isliye wahi key rakhi hai
    final token = prefs.getString('auth_token');

    if (token != null) {
      return {
        "Content-Type": "application/json",
        "Authorization": "Token $token",
      };
    }

    return {"Content-Type": "application/json"};
  }

  // 1. Fetch Jobs
  Future<List<Job>> fetchJobs() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/jobs/'), headers: headers);

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Job.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching jobs: $e");
      return [];
    }
  }

  // 2. Dropdown Data Fetchers (States, Categories, Qualifications)
  Future<List<String>> fetchStates() async => _fetchList('/states/');
  Future<List<String>> fetchCategories() async => _fetchList('/categories/');
  Future<List<String>> fetchQualifications() async => _fetchList('/qualifications/');

  // Private Helper to avoid code repetition
  Future<List<String>> _fetchList(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl$endpoint'), headers: headers);
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map<String>((json) => json['name'].toString()).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching $endpoint: $e");
      return [];
    }
  }

  // --- 👤 GET USER PROFILE (Final & Unified) ---
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final headers = await _getHeaders();

      // Check if user is actually logged in (Token check)
      if (!headers.containsKey('Authorization')) {
        throw Exception("Authentication token not found. Please log in again.");
      }

      // 🎯 Endpoint Fixed: /api/auth/profile/ (As per your urls.py)
      final response = await http.get(
          Uri.parse('$baseUrl/auth/profile/'),
          headers: headers
      );

      if (response.statusCode == 200) {
        // Django ab 'categories' ki List bhejega, UserProvider ise handle kar lega
        return json.decode(response.body);
      } else {
        debugPrint("Profile API Error: ${response.body}");
        throw Exception("Failed to load profile. Status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("API Exception (getUserProfile): $e");
      rethrow;
    }
  }

  // --- 🔒 CHANGE PASSWORD LOGIC ---

  // 1. User ke email par OTP bhejta hai
  // 1. User ke email par OTP bhejta hai
  Future<bool> requestPasswordResetOtp(String email) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/auth/resend-otp/'), // 🚀 Fixed: Added /auth/
        headers: headers,
        body: json.encode({'email': email}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 2. OTP aur Naya Password verify karke update karta hai
  Future<bool> resetPassword(String email, String otp, String newPassword) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password/'), // 🚀 Fixed: Added /auth/
        headers: headers,
        body: json.encode({
          'email': email,
          'otp': otp,
          'new_password': newPassword,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}