import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/job_provider.dart';
import '../providers/user_provider.dart'; // 🚀 Added UserProvider
import '../screens/notification_screen.dart';
import '../screens/privacy_policy_screen.dart';

class MainDrawer extends StatelessWidget {
  final Function(String) onFilterSelected;

  const MainDrawer({super.key, required this.onFilterSelected});

  Future<String?> _showSelectionDialog(BuildContext context, String title, List<String> items) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          backgroundColor: const Color(0xFF546E7A),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Flexible(
                child: SizedBox(
                  height: 400,
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: items.length,
                    separatorBuilder: (ctx, i) => const Divider(color: Colors.white24, height: 1),
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () {
                          Navigator.pop(context, items[index]);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                          child: Text(
                            items[index],
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).cardColor;
    final iconColor = Theme.of(context).iconTheme.color;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;

    // 🚀 Access User Data
    final userProvider = Provider.of<UserProvider>(context);
    final String displayName = userProvider.name.isNotEmpty ? userProvider.name : "Candidate";

    // Assume your UserProvider has a profileImage field (Update field name if different)
    // For now using a placeholder logic as per your request
    final String? profilePic = userProvider.profileImage;

    return Drawer(
      backgroundColor: backgroundColor,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.indigo,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- PROFILE IMAGE OR BRIEFCASE ICON ---
                  Container(
                    height: 70, width: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(35),
                      child: (profilePic != null && profilePic.isNotEmpty)
                          ? Image.network(
                        profilePic,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.work, size: 35, color: Colors.indigo),
                      )
                          : const Icon(Icons.work, size: 35, color: Colors.indigo),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Dynamic User Name
                  Text(
                      displayName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)
                  ),
                  const Text(
                      "Find your dream career",
                      style: TextStyle(fontSize: 13, color: Colors.white70)
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(Icons.map, "Search by State", iconColor, textColor, () async {
                  Navigator.pop(context);
                  final jobProvider = Provider.of<JobProvider>(context, listen: false);
                  final List<String> stateNames = List.from(jobProvider.states);
                  final selected = await _showSelectionDialog(context, "Select State", stateNames);
                  if (selected != null) onFilterSelected(selected);
                }),

                _buildDrawerItem(Icons.school, "Search by Qualification", iconColor, textColor, () async {
                  Navigator.pop(context);
                  final jobProvider = Provider.of<JobProvider>(context, listen: false);
                  final List<String> qualNames = jobProvider.qualifications;
                  final selected = await _showSelectionDialog(context, "Select Qualification", qualNames);
                  if (selected != null) onFilterSelected(selected);
                }),

                _buildDrawerItem(Icons.category, "Search by Category", iconColor, textColor, () async {
                  Navigator.pop(context);
                  final jobProvider = Provider.of<JobProvider>(context, listen: false);
                  final List<String> catNames = jobProvider.categories;
                  final selected = await _showSelectionDialog(context, "Select Category", catNames);
                  if (selected != null) onFilterSelected(selected);
                }),

                const Divider(),
                _buildDrawerItem(Icons.notifications, "Notifications", iconColor, textColor, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen()));
                }),

                _buildDrawerItem(Icons.share, "Share App", iconColor, textColor, () {
                  Navigator.pop(context);
                  Share.share('Check out this amazing GovJob Portal app!');
                }),

                _buildDrawerItem(Icons.privacy_tip_outlined, "Privacy Policy", iconColor, textColor, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()));
                }),

                _buildDrawerItem(Icons.info_outline, "Disclaimer", iconColor, textColor, () {
                  Navigator.pop(context);
                  _showDisclaimerDialog(context);
                }),

                const Divider(),
                _buildDrawerItem(Icons.exit_to_app, "Exit", Colors.red, Colors.red, () {
                  _showExitDialog(context);
                }),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Version 1.0.0", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text("Exit App", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: Text("Do you want to exit?", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("No")),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              SystemNavigator.pop();
            },
            child: const Text("Yes", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDisclaimerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Disclaimer", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const SingleChildScrollView(
          child: Text(
            "Disclaimer: - All job information on this app is collected from public sources like official websites, newspapers, and online portals. We do not represent any government entity and are not affiliated with any government organization. This app is only for informational purposes. Users are advised to verify details from official sources before applying.",
            textAlign: TextAlign.justify,
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("I Understand", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, Color? iconColor, Color? textColor, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.grey.shade700),
      title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor)),
      onTap: onTap,
    );
  }
}