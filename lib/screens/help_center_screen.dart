import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  int _selectedCategoryIndex = 0;

  // 🎯 Job Portal Categories
  final List<String> _categories = ['All', 'Account', 'Jobs', 'Applications'];

  // 🎯 Job Portal FAQs
  final List<Map<String, String>> _allFaqs = [
    {'category': 'Account', 'q': 'How do I update my profile?', 'a': 'Go to Profile -> Edit Profile. Make sure to fill in your latest skills and resume.'},
    {'category': 'Account', 'q': 'I forgot my password, what do I do?', 'a': 'On the login screen, click "Forgot Password" to reset it via your registered email.'},
    {'category': 'Jobs', 'q': 'How do I search for jobs?', 'a': 'Use the search bar on the Home screen or filter jobs by category and location.'},
    {'category': 'Jobs', 'q': 'Can I save a job to apply later?', 'a': 'Yes, click the bookmark icon on any job card to save it to your Saved Jobs list.'},
    {'category': 'Applications', 'q': 'How do I apply for a job?', 'a': 'Open the job details and click the "Apply Now" button at the bottom of the screen.'},
    {'category': 'Applications', 'q': 'How will I know if my application is selected?', 'a': 'You will receive a notification in the app and an email from the employer.'},
  ];

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _openWhatsApp() async {
    String phoneNumber = "919601591839";
    String message = "Hello Support, I need help.";
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    List<Map<String, String>> displayedFaqs = _allFaqs.where((faq) {
      bool matchesCategory = _selectedCategoryIndex == 0 || faq['category'] == _categories[_selectedCategoryIndex];
      bool matchesSearch = faq['q']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          faq['a']!.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  height: 220,
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 50),
                  decoration: const BoxDecoration(
                    color: Colors.indigo,
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),
                      const SizedBox(height: 12),
                      const Text("Help Center", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                      const Text("How can we help you today?", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
                Positioned(
                  bottom: -25, left: 20, right: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor, borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1), blurRadius: 15, offset: const Offset(0, 8))],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: 15),
                      cursorColor: Colors.indigo,
                      decoration: InputDecoration(
                        hintText: "Search issues...",
                        hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
                        prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                        suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: Icon(Icons.clear, color: isDark ? Colors.white70 : Colors.grey), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ""); }) : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 55),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  bool isSelected = _selectedCategoryIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategoryIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.indigo : cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? Colors.indigo : (isDark ? Colors.white10 : Colors.grey.shade300)),
                      ),
                      child: Center(
                        child: Text(
                          _categories[index],
                          style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey.shade700), fontWeight: isSelected ? FontWeight.bold : FontWeight.w500),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_selectedCategoryIndex == 0 ? "Popular Questions" : "${_categories[_selectedCategoryIndex]} FAQs", style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (displayedFaqs.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("No FAQs found", style: TextStyle(color: Colors.grey))))
                  else
                    ...displayedFaqs.map((faq) => _buildModernFaqTile(faq['q']!, faq['a']!, isDark, cardColor, textColor)).toList(),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300)),
                child: Column(
                  children: [
                    Text("Still need help?", style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text("Our support team is available for you", style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: _contactButton(iconWidget: const Icon(FontAwesomeIcons.whatsapp, size: 18), label: "WhatsApp", color: Colors.green, onTap: () => _openWhatsApp())),
                        const SizedBox(width: 12),
                        Expanded(child: _contactButton(iconWidget: const Icon(Icons.phone_in_talk_rounded, size: 18), label: "Call Us", color: Colors.indigo, onTap: () => _launchURL("tel:+919054648658"))),
                      ],
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

  Widget _buildModernFaqTile(String question, String answer, bool isDark, Color cardColor, Color? textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300)),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent, unselectedWidgetColor: Colors.grey),
        child: ExpansionTile(
          iconColor: Colors.indigo,
          collapsedIconColor: Colors.grey,
          title: Text(question, style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 15)),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Text(answer, style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.4)),
            )
          ],
        ),
      ),
    );
  }

  Widget _contactButton({required Widget iconWidget, required String label, required Color color, required VoidCallback onTap}) {
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: SizedBox(width: 18, height: 18, child: iconWidget),
        label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, elevation: 0, minimumSize: const Size(0, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
    );
  }
}