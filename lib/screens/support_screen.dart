import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'help_center_screen.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  // Logic: Functional URL launching
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Error launching URL: $e");
    }
  }

  // Logic: WhatsApp redirect
  Future<void> _openWhatsApp() async {
    String phoneNumber = "919601591839"; // Apna number daalein
    String message = "Hello Support, I need help with my Job Portal account.";
    final Uri whatsappAppUrl = Uri.parse("whatsapp://send?phone=$phoneNumber&text=${Uri.encodeComponent(message)}");
    final Uri whatsappWebUrl = Uri.parse("https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");

    try {
      if (await canLaunchUrl(whatsappAppUrl)) {
        await launchUrl(whatsappAppUrl);
      } else {
        await launchUrl(whatsappWebUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("WhatsApp error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.indigo,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () {
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text("Support Center", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
              background: Container(
                decoration: const BoxDecoration(color: Colors.indigo),
                child: Stack(
                  children: [
                    Positioned(
                      top: 40, right: -20,
                      child: CircleAvatar(radius: 80, backgroundColor: Colors.white.withValues(alpha: 0.05)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Instant Help", style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildQuickAction(
                        context,
                        title: "WhatsApp",
                        icon: FontAwesomeIcons.whatsapp,
                        color: Colors.green,
                        onTap: _openWhatsApp,
                      ),
                      const SizedBox(width: 15),
                      _buildQuickAction(
                        context,
                        title: "Call Us",
                        icon: Icons.phone_in_talk_rounded,
                        color: Colors.indigo,
                        onTap: () => _launchURL("tel:+919054648658"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text("Self Service Options", style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 16),
                  _buildModernTile(
                    context,
                    title: "Help Center / FAQs",
                    desc: "Get quick answer of your common queries",
                    icon: Icons.auto_stories_outlined,
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpCenterScreen()));
                    },
                  ),
                  const SizedBox(height: 40),
                  const Center(
                    child: Text("App Version 1.0.0 • Job Portal", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
            boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTile(BuildContext context, {required String title, required String desc, required IconData icon, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.indigo.shade50, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.indigo),
        ),
        title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        subtitle: Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}