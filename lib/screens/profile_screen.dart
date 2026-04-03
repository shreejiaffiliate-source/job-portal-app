import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'notification_screen.dart';
import 'support_screen.dart';
import 'otp_verification_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = ApiService().getUserProfile();
  }

  void _refreshProfile() {
    setState(() {
      _profileFuture = ApiService().getUserProfile();
    });
  }

  // 🚀 NEW: Logout Confirmation Dialog (UI Consistency with MainDrawer)
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        title: Text(
            "Log Out",
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.bold,
            )
        ),
        content: Text(
            "Do you really want to logOut?",
            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("No")
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop(); // Dialog band karein
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();

              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false
                );
              }
            },
            child: const Text(
                "Yes",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _profileFuture,
      builder: (context, snapshot) {
        final userData = snapshot.hasData ? snapshot.data : null;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          endDrawer: SettingsDrawer(
            userData: userData,
            onProfileUpdated: _refreshProfile,
          ),
          appBar: AppBar(
            title: const Text("My Profile", style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              Builder(
                builder: (context) => IconButton(
                  icon: Icon(Icons.settings_outlined, color: Theme.of(context).iconTheme.color),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
            ],
          ),
          body: _buildBody(context, snapshot),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator(color: Colors.indigo));
    }

    if (snapshot.hasError || !snapshot.hasData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            const Text("Failed to load profile data."),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _refreshProfile,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              child: const Text("Retry", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      );
    }

    final data = snapshot.data!;
    final String skillsString = data['skills'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildProfileHeader(context, data),
          const SizedBox(height: 20),
          _buildProfileCompletionCard(data),
          const SizedBox(height: 20),
          _buildMenuSection(context, data, skillsString),
          const SizedBox(height: 30),
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, Map<String, dynamic> data) {
    final String name = data['name'] ?? "Candidate";
    final String headline = (data['headline'] != null && data['headline'].toString().isNotEmpty)
        ? data['headline'] : "Job Seeker";
    final String location = (data['location'] != null && data['location'].toString().isNotEmpty)
        ? data['location'] : "Location not set";
    final String? profileImageUrl = data['profile_image'];

    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: 100, width: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle, color: Theme.of(context).cardColor,
                border: Border.all(color: Colors.indigo, width: 4),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                image: profileImageUrl != null ? DecorationImage(image: NetworkImage(profileImageUrl), fit: BoxFit.cover) : null,
              ),
              child: profileImageUrl == null ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
            ),
            Positioned(
              bottom: 0, right: 0,
              child: GestureDetector(
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileScreen(userData: data)));
                  _refreshProfile();
                },
                child: Container(
                  height: 32, width: 32,
                  decoration: const BoxDecoration(color: Colors.indigo, shape: BoxShape.circle),
                  child: const Icon(Icons.edit, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(headline, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(location, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileCompletionCard(Map<String, dynamic> data) {
    int score = 20;
    if (data['headline']?.isNotEmpty == true) score += 20;
    if (data['profile_image'] != null) score += 20;
    if (data['resume_url'] != null) score += 20;
    if (data['skills']?.isNotEmpty == true) score += 20;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.indigo, Colors.indigo.shade700]),
          borderRadius: BorderRadius.circular(16)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Profile Completed", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text("$score%", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: score / 100,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
            minHeight: 8,
          ),
          const SizedBox(height: 10),
          Text(score < 100 ? "Complete your details to get more jobs!" : "Great job! Your profile is strong.",
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, Map<String, dynamic> data, String skills) {
    final String qualification = data['qualification']?.isNotEmpty == true ? data['qualification'] : "Add qualification";
    final String skillsSubtitle = skills.isNotEmpty ? skills : "Add skills";

    return Column(
      children: [
        _buildMenuItem(context, Icons.description_outlined, "My Resume", "Tap to view resume",
            onTap: () => _openResume(context, data['resume_url'])),
        _buildMenuItem(context, Icons.school_outlined, "Education", qualification),
        _buildMenuItem(context, Icons.lightbulb_outline, "Skills", skillsSubtitle),
      ],
    );
  }

  Future<void> _openResume(BuildContext context, String? urlString) async {
    if (urlString == null || urlString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No Resume Uploaded")));
      return;
    }
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Icon(icon, color: Colors.indigo),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Divider(
          height: 1,
          thickness: 0.8,
          color: Colors.grey.shade300,
          indent: 20,
          endIndent: 20,
        ),
      ],
    );
  }

  // 🚀 Updated Logout Button with Dialog call
  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutDialog(context), // 🎯 Dialog ko call kiya
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text("Log Out", style: TextStyle(color: Colors.red)),
        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
      ),
    );
  }
}

// SettingsDrawer logic remains unchanged as per reference
class SettingsDrawer extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final VoidCallback? onProfileUpdated;

  const SettingsDrawer({super.key, this.userData, this.onProfileUpdated});

  Future<void> _handleChangePassword(BuildContext context) async {
    if (userData == null || userData!['email'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Email not found!")));
      return;
    }

    final String email = userData!['email'];
    Provider.of<AuthProvider>(context, listen: false).resendOtp(email);

    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtpVerificationScreen(
          email: email,
          isPasswordReset: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.indigo),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text("Settings", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text(userData?['email'] ?? "", style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text("Edit Profile"),
            onTap: () {
              Navigator.pop(context);
              if (userData != null) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(userData: userData!)));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text("Change Password"),
            onTap: () => _handleChangePassword(context),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text("Dark Mode"),
            value: isDark,
            onChanged: (v) => themeProvider.toggleTheme(v),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text("Help & Support"),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen())),
          ),
        ],
      ),
    );
  }
}