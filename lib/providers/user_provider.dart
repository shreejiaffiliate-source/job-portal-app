import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart'; // ✅ Import API Service

class UserProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  String _name = "";
  String _headline = "";
  String _location = "";
  String _qualification = ""; // ✅ 'education' ko 'qualification' kar diya
  List<String> _categories = [];     // ✅ Naya Field
  List<String> _skills = [];
  String? _profileImage;      // ✅ URL for NetworkImage
  String? _resumeUrl;         // ✅ URL for Resume
  bool _isLoggedIn = false;

  // --- Getters (EditProfileScreen ke liye ekdum sahi) ---
  String get name => _name;
  String get headline => _headline;
  String get location => _location;
  String get qualification => _qualification;
  List<String> get categories => _categories;
  String get skills => _skills.join(', '); // ✅ Skills ko String bana kar bhejta hai
  String? get profileImage => _profileImage;
  String? get resumeUrl => _resumeUrl;
  bool get isLoggedIn => _isLoggedIn;

  // --- 🎯 Django se Profile Fetch karna (Naya Method) ---
  Future<void> fetchUserProfile() async {
    try {
      // Is method ko apne api_service.dart mein banana padega
      final userData = await _apiService.getUserProfile();

      _name = userData['name'] ?? "";
      _headline = userData['headline'] ?? "";
      _location = userData['location'] ?? "";
      _qualification = userData['qualification'] ?? "";
      var catData = userData['categories'];
      if (catData != null && catData is List) {
        _categories = List<String>.from(catData.map((e) => e.toString()));
      } else {
        _categories = [];
      }

      // Skills handling (agar string hai toh split karo, agar list hai toh direct)
      if (userData['skills'] is String) {
        _skills = (userData['skills'] as String).split(',').map((e) => e.trim()).toList();
      } else {
        _skills = List<String>.from(userData['skills'] ?? []);
      }

      _profileImage = userData['profile_image'];
      _resumeUrl = userData['resume_url'];
      _isLoggedIn = true;

      notifyListeners();
      _saveToPrefs(); // Local backup
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
  }

  // --- Login ke waqt data save karne ke liye ---
  Future<void> saveUser({
    required String name,
    required String headline,
    required String location,
    required String qualification,
    required List<String> categories,
    required List<String> skills,
    String? profileImage,
    String? resumeUrl,
  }) async {
    _name = name;
    _headline = headline;
    _location = location;
    _qualification = qualification;
    _categories = categories;
    _skills = skills;
    _profileImage = profileImage;
    _resumeUrl = resumeUrl;
    _isLoggedIn = true;

    notifyListeners();
    await _saveToPrefs();
  }

  // --- Local Storage (SharedPreferences) Backup ---
  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', _name);
    await prefs.setString('userHeadline', _headline);
    await prefs.setString('userLocation', _location);
    await prefs.setString('userQualification', _qualification);
    await prefs.setStringList('userCategories', _categories);
    await prefs.setStringList('userSkills', _skills);
    if (_profileImage != null) await prefs.setString('userProfileImage', _profileImage!);
    if (_resumeUrl != null) await prefs.setString('userResumeUrl', _resumeUrl!);
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString('userName') ?? "";
    _headline = prefs.getString('userHeadline') ?? "";
    _location = prefs.getString('userLocation') ?? "";
    _qualification = prefs.getString('userQualification') ?? "";
    _categories = prefs.getStringList('userCategories') ?? [];
    _skills = prefs.getStringList('userSkills') ?? [];
    _profileImage = prefs.getString('userProfileImage');
    _resumeUrl = prefs.getString('userResumeUrl');

    _isLoggedIn = _name.isNotEmpty;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _name = "";
    _headline = "";
    _profileImage = null;
    _resumeUrl = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}