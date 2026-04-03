import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isObscured = true;

  final _nameController = TextEditingController();
  final _headlineController = TextEditingController();
  final _skillsController = TextEditingController();

  String? _selectedQualification;
  String? _selectedLocation;

  // 🎯 FIX: String to List for multiple selection
  List<String> _selectedCategories = [];

  List<String> _qualificationsList = [];
  List<String> _locationsList = [];
  List<String> _categoriesList = [];
  bool _isLoadingDropdowns = true;

  // 🚀 NEW: Loading State for Button
  bool _isRegistering = false;

  File? _profileImage;
  String? _resumeFileName;
  String? _pickedResumePath;
  bool _resumeUploaded = false;

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  Future<void> _fetchDropdownData() async {
    try {
      final apiService = ApiService();
      final quals = await apiService.fetchQualifications();
      final locs = await apiService.fetchStates();
      final cats = await apiService.fetchCategories();

      if (mounted) {
        setState(() {
          _qualificationsList = quals;
          _locationsList = locs;
          _categoriesList = cats;
          _isLoadingDropdowns = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDropdowns = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _profileImage = File(pickedFile.path));
  }

  Future<void> _pickResume() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result != null) {
      setState(() {
        _resumeFileName = result.files.single.name;
        _pickedResumePath = result.files.single.path;
        _resumeUploaded = true;
      });
    }
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategories.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select at least one category")));
        return;
      }

      // 🚀 START LOADING
      setState(() => _isRegistering = true);

      try {
        List<String> skillsList = _skillsController.text.split(',')
            .map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        final success = await authProvider.registerCandidate(
          email: _emailController.text.trim(),
          username: _usernameController.text.trim(),
          password: _passwordController.text.trim(),
          fullName: _nameController.text.trim(),
          headline: _headlineController.text.trim(),
          location: _selectedLocation ?? "",
          qualification: _selectedQualification ?? "",
          categories: _selectedCategories,
          skills: skillsList,
          profileImage: _profileImage,
          resumePath: _pickedResumePath,
        );

        if (success) {
          if (mounted) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => OtpVerificationScreen(email: _emailController.text.trim())));
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User with this email or username already exists")));
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
        }
      } finally {
        // 🚀 STOP LOADING (Hamesha execute hoga chahe error aaye ya success)
        if (mounted) setState(() => _isRegistering = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account", style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.indigo.withOpacity(0.1),
                      backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                      child: _profileImage == null ? const Icon(Icons.person, size: 50) : null,
                    ),
                    Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 18, backgroundColor: Colors.indigo, child: IconButton(icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white), onPressed: _pickImage))),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _buildTextField("Full Name", _nameController, Icons.person),
              _buildTextField("Username", _usernameController, Icons.alternate_email),
              _buildTextField("Email", _emailController, Icons.email, isEmail: true),
              _buildPasswordField(),
              _buildTextField("Headline", _headlineController, Icons.work),

              _buildDropdown("Location", _selectedLocation, _locationsList, Icons.location_on, (val) => setState(() => _selectedLocation = val)),
              _buildDropdown("Qualification", _selectedQualification, _qualificationsList, Icons.school, (val) => setState(() => _selectedQualification = val)),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text("Select Categories of Interest", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              _isLoadingDropdowns
                  ? const LinearProgressIndicator()
                  : Wrap(
                spacing: 8.0,
                children: _categoriesList.map((cat) {
                  final isSelected = _selectedCategories.contains(cat);
                  return FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        selected ? _selectedCategories.add(cat) : _selectedCategories.remove(cat);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 15),

              _buildTextField("Skills (comma separated)", _skillsController, Icons.lightbulb),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _pickResume,
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Icon(_resumeUploaded ? Icons.check_circle : Icons.upload_file, color: _resumeUploaded ? Colors.green : Colors.indigo),
                      const SizedBox(width: 10),
                      Text(_resumeUploaded ? "Resume Uploaded" : "Upload Resume"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // 🚀 UPDATED BUTTON WITH LOADING LOGIC
              SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    // Agar registering ho rahi hai toh button disable (null) kar do double clicks bachane ke liye
                      onPressed: _isRegistering ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                      child: _isRegistering
                          ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                          : const Text("Register & Send OTP", style: TextStyle(color: Colors.white))
                  )
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Baaki helper methods same rahenge ---
  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isEmail = false}) {
    return Padding(padding: const EdgeInsets.only(bottom: 15), child: TextFormField(controller: controller, keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (value) => value!.isEmpty ? "Required" : null));
  }

  Widget _buildPasswordField() {
    return Padding(padding: const EdgeInsets.only(bottom: 15), child: TextFormField(controller: _passwordController, obscureText: _isObscured, decoration: InputDecoration(labelText: "Password", prefixIcon: const Icon(Icons.lock), suffixIcon: IconButton(icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _isObscured = !_isObscured)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (value) => value!.length < 6 ? "Short" : null));
  }

  Widget _buildDropdown(String label, String? value, List<String> items, IconData icon, Function(String?) onChanged) {
    return Padding(padding: const EdgeInsets.only(bottom: 15), child: DropdownButtonFormField<String>(value: items.contains(value) ? value : null, isExpanded: true, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(), onChanged: onChanged, validator: (val) => val == null ? "Required" : null));
  }
}