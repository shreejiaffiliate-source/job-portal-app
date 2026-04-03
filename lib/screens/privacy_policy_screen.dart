import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Future<void> _sendEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'shreejifintech.db@gmail.com',
      query: 'subject=Inquiry about Privacy Policy&body=Hello Shreeji Fintech Team,', // Optional: Subject aur body pehle se likhi aayegi
    );

    try {
      if (!await launchUrl(emailLaunchUri)) {
        throw Exception('Could not launch email client');
      }
    } catch (e) {
      debugPrint("Error launching email: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryTextColor = Colors.grey.shade600;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Privacy Policy", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: Theme.of(context).iconTheme,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader("Privacy Policy", "Last updated: March 25, 2026"),
            const Divider(height: 40),

            _buildParagraph(
              "Job Portal App built by Shreeji Fintech is provided as a free service and is intended for use as is. This page is used to inform users regarding our policies with the collection, use, and disclosure of Personal Information if anyone decides to use our Service.",
            ),
            _buildParagraph(
              "By using our Service (mobile app and website), you agree to the collection and use of information in accordance with this policy. The Personal Information that we collect is used for providing and improving the Service. We do not use or share your information except as described in this Privacy Policy.",
            ),

            _buildSectionTitle("Information Collection and Use"),
            _buildParagraph("For a better experience, while using our Service, we may require you to provide certain personally identifiable information, including but not limited to:"),
            _buildBulletPoint("Name"),
            _buildBulletPoint("Email Address"),
            _buildBulletPoint("Resume / Documents (if uploaded)"),
            _buildBulletPoint("Location (optional)"),

            const SizedBox(height: 10),
            _buildParagraph("This information is used for:"),
            _buildBulletPoint("Providing job-related updates"),
            _buildBulletPoint("Improving user experience"),
            _buildBulletPoint("Managing job applications and listings"),
            _buildBulletPoint("Sending notifications (if enabled)"),

            _buildSectionTitle("Job Data & Content"),
            _buildParagraph("Our app/website provides job listings collected from various public sources. We do not guarantee the accuracy or authenticity of job information. Users are advised to verify details from official sources before applying."),

            _buildSectionTitle("Third-Party Services"),
            _buildParagraph("Our app may use third-party services that may collect information used to identify you. These include:"),
            _buildBulletPoint("Google Play Services"),
            _buildBulletPoint("Firebase Analytics"),
            _buildBulletPoint("AdMob (for ads, if used)"),
            _buildParagraph("These services have their own privacy policies and we recommend reviewing them."),

            _buildSectionTitle("Cookies"),
            _buildParagraph("Our website may use cookies to improve user experience. These cookies help:"),
            _buildBulletPoint("Remember user preferences"),
            _buildBulletPoint("Analyze website traffic"),
            _buildBulletPoint("Improve performance"),
            _buildParagraph("You can choose to accept or refuse cookies through your browser settings."),

            _buildSectionTitle("Service Providers"),
            _buildParagraph("We may employ third-party companies for Hosting services, Analytics, Notifications, and App performance monitoring. These third parties may have access to your information only to perform tasks on our behalf and are obligated not to misuse it."),

            _buildSectionTitle("Security"),
            _buildParagraph("We value your trust in providing your personal information. We use commercially acceptable means to protect your data. However, no method of transmission over the internet is 100% secure, and we cannot guarantee absolute security."),

            _buildSectionTitle("Links to Other Sites"),
            _buildParagraph("Our app/website may contain links to external websites (such as job notifications or PDFs). We are not responsible for the privacy practices or content of those third-party websites."),

            _buildSectionTitle("Children’s Privacy"),
            _buildParagraph("Our Service is not intended for children under the age of 13. We do not knowingly collect personal data from children. If we discover such data, we will delete it immediately."),

            _buildSectionTitle("Changes to This Privacy Policy"),
            _buildParagraph("We may update our Privacy Policy from time to time. Any changes will be posted on this page and will be effective immediately."),

            _buildSectionTitle("Contact Us"),
            _buildParagraph("If you have any questions or suggestions regarding this Privacy Policy, you can contact us:"),
            const SizedBox(height: 10),
            InkWell(
              onTap: _sendEmail, // Click karne par function call hoga
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.email, color: Colors.indigo),
                    SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        "shreejifintech.db@gmail.com",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.green, // 🚀 Thoda blue color taaki link jaisa lage
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 25, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        textAlign: TextAlign.justify,
        style: const TextStyle(fontSize: 15, height: 1.5),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}