import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const EditProfileScreen({super.key, this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isUpdating = false;

  late TextEditingController _nameController;
  late TextEditingController _headlineController;
  late TextEditingController _skillsController;

  String? _selectedQualification;
  String? _selectedLocation;

  // 🎯 FIX 1: String ko hata kar List kar diya
  List<String> _selectedCategories = [];

  List<String> _qualificationsList = [];
  List<String> _locationsList = [];
  List<String> _categoriesList = [];
  bool _isLoadingDropdowns = true;

  File? _newProfileImage;
  String? _newResumePath;
  String? _resumeFileName;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false);
    final data = widget.userData ?? {};

    _nameController = TextEditingController(text: data['name'] ?? user.name);
    _headlineController = TextEditingController(text: data['headline'] ?? user.headline);

    String skillsText = "";
    if (data['skills'] != null) {
      skillsText = data['skills'] is List ? (data['skills'] as List).join(', ') : data['skills'].toString();
    } else {
      skillsText = user.skills;
    }
    _skillsController = TextEditingController(text: skillsText);

    _selectedLocation = data['location'] ?? (user.location.isNotEmpty ? user.location : null);
    _selectedQualification = data['qualification'] ?? (user.qualification.isNotEmpty ? user.qualification : null);

    // 🎯 FIX 2: Pre-fill multiple categories logic
    if (data['categories'] != null) {
      _selectedCategories = List<String>.from(data['categories']);
    } else {
      _selectedCategories = List<String>.from(user.categories);
    }

    _fetchDropdownData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _headlineController.dispose();
    _skillsController.dispose();
    super.dispose();
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
    if (pickedFile != null) setState(() => _newProfileImage = File(pickedFile.path));
  }

  Future<void> _pickResume() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result != null) {
      setState(() {
        _resumeFileName = result.files.single.name;
        _newResumePath = result.files.single.path;
      });
    }
  }

  void _handleUpdate() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategories.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select at least one category")));
        return;
      }

      setState(() => _isUpdating = true);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // 🎯 FIX 3: Passed '_selectedCategories' list to AuthProvider
      final success = await authProvider.updateProfile(
        fullName: _nameController.text.trim(),
        headline: _headlineController.text.trim(),
        location: _selectedLocation ?? "",
        qualification: _selectedQualification ?? "",
        categories: _selectedCategories, // <--- Correct parameter name
        skills: _skillsController.text.trim(),
        profileImage: _newProfileImage,
        resumePath: _newResumePath,
      );

      if (success) {
        await userProvider.fetchUserProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated!"), backgroundColor: Colors.green));
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Update Failed"), backgroundColor: Colors.red));
        }
      }
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final cardColor = Theme.of(context).cardColor;

    final String? existingImageUrl = widget.userData?['profile_image'] ?? user.profileImage;
    final String? existingResumeUrl = widget.userData?['resume_url'] ?? user.resumeUrl;

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.bold))),
      body: _isLoadingDropdowns
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                      radius: 55,
                      backgroundImage: _newProfileImage != null
                          ? FileImage(_newProfileImage!)
                          : (existingImageUrl != null ? NetworkImage(existingImageUrl) : null) as ImageProvider?,
                      child: (_newProfileImage == null && existingImageUrl == null) ? const Icon(Icons.person, size: 55) : null,
                    ),
                    Positioned(bottom: 0, right: 4, child: CircleAvatar(radius: 18, backgroundColor: Colors.indigo, child: IconButton(icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white), onPressed: _pickImage))),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _buildTextField("Full Name", _nameController, Icons.person, textColor),
              _buildTextField("Headline", _headlineController, Icons.work_outline, textColor),
              _buildDropdown("Location", _selectedLocation, _locationsList, Icons.location_on_outlined, (val) => setState(() => _selectedLocation = val)),
              _buildDropdown("Qualification", _selectedQualification, _qualificationsList, Icons.school_outlined, (val) => setState(() => _selectedQualification = val)),

              // 🚀 FIX 4: Multi-Category Selector instead of Dropdown
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text("Preferred Categories", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Wrap(
                spacing: 8,
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

              _buildTextField("Skills (comma separated)", _skillsController, Icons.lightbulb_outline, textColor),
              const SizedBox(height: 20),
              ListTile(
                tileColor: cardColor,
                leading: const Icon(Icons.description, color: Colors.indigo),
                title: const Text("My Resume", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_resumeFileName ?? (existingResumeUrl != null ? "Resume uploaded" : "No resume")),
                trailing: const Icon(Icons.upload_file),
                onTap: _pickResume,
              ),
              const SizedBox(height: 40),
              SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: _isUpdating ? null : _handleUpdate, style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo), child: _isUpdating ? const CircularProgressIndicator(color: Colors.white) : const Text("Save Changes", style: TextStyle(color: Colors.white)))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, Color? textColor) {
    return Padding(padding: const EdgeInsets.only(bottom: 15), child: TextFormField(controller: controller, style: TextStyle(color: textColor), decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (value) => value!.isEmpty ? "Required" : null));
  }

  Widget _buildDropdown(String label, String? value, List<String> items, IconData icon, Function(String?) onChanged) {
    return Padding(padding: const EdgeInsets.only(bottom: 15), child: DropdownButtonFormField<String>(value: items.contains(value) ? value : null, isExpanded: true, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(), onChanged: onChanged, validator: (val) => val == null ? "Required" : null));
  }
}