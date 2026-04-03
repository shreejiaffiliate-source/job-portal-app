import 'package:flutter/material.dart';
import '../models/job_model.dart';
import '../services/api_service.dart';

class JobProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Job> _jobs = [];
  List<String> _states = [];
  List<String> _categories = [];
  List<String> _qualifications = [];

  List<String> _savedJobIds = [];
  List<String> _appliedJobIds = [];
  bool _isLoading = false;

  List<Job> get jobs => _jobs;
  List<String> get states => _states;
  List<String> get categories => _categories;
  List<String> get qualifications => _qualifications;
  bool get isLoading => _isLoading;

  // <--- FIX 5: appliedJobs & savedJobs getters
  List<Job> get appliedJobs {
    return _jobs.where((job) => _appliedJobIds.contains(job.id)).toList();
  }

  List<Job> get savedJobs {
    return _jobs.where((job) => _savedJobIds.contains(job.id)).toList();
  }

  Future<void> fetchAllData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _apiService.fetchJobs(),
        _apiService.fetchStates(),
        _apiService.fetchCategories(),
        _apiService.fetchQualifications(),
      ]);

      _jobs = results[0] as List<Job>;
      _states = results[1] as List<String>;
      _categories = results[2] as List<String>;
      _qualifications = results[3] as List<String>;

    } catch (e) {
      print("Error fetching data: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  void toggleSave(String jobId) {
    if (_savedJobIds.contains(jobId)) {
      _savedJobIds.remove(jobId);
    } else {
      _savedJobIds.add(jobId);
    }
    notifyListeners();
  }

  bool isJobSaved(String jobId) => _savedJobIds.contains(jobId);

  // <--- FIX 6: applyJob method
  void applyJob(String jobId) {
    if (!_appliedJobIds.contains(jobId)) {
      _appliedJobIds.add(jobId);
      notifyListeners();
    }
  }

  bool isJobApplied(String jobId) => _appliedJobIds.contains(jobId);

  // 🎯 Ye method 'job_detail_screen.dart' ki error solve kar dega
  Future<void> fetchJobs() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Hum sirf jobs fetch kar rahe hain, baaki data nahi
      _jobs = await _apiService.fetchJobs();
    } catch (e) {
      debugPrint("Error fetching jobs: $e");
    }

    _isLoading = false;
    notifyListeners();
  }
}

