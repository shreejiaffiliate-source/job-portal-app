import 'dart:io'; // 🚀 Added
import 'package:dio/dio.dart'; // 🚀 Added
import 'package:flutter/material.dart';
import 'package:jobportal/screens/pdf_viewer_screen.dart';
import 'package:path_provider/path_provider.dart'; // 🚀 Added
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/job_model.dart';
import '../providers/job_provider.dart';
import '../widgets/job_card.dart';
import 'package:permission_handler/permission_handler.dart';

class JobDetailScreen extends StatefulWidget {
  final Job? job;
  final String jobId;

  const JobDetailScreen({super.key, this.job, required this.jobId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _isInit = true;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _checkAndFetchJob();
    }
    _isInit = false;
  }

  // 🚀 ASLI DOWNLOAD LOGIC (Ab ye error nahi dega)
  Future<void> _downloadPDF(String url, String fileName) async {
    try {
      // 1. Permission request
      if (Platform.isAndroid) {
        await Permission.storage.request();
      }

      // 2. Path selection (Downloads folder)
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      // Agar directory nahi hai toh banao
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      String savePath = "${directory.path}/$fileName.pdf";

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Downloading PDF..."), duration: Duration(seconds: 2)),
      );

      // 3. Dio se Download
      await Dio().download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            debugPrint("${(received / total * 100).toStringAsFixed(0)}%");
          }
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("PDF Downloaded to Downloads folder!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Download error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Download failed. Check internet/permissions."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPDFOptions(BuildContext context, String pdfUrl, String jobTitle) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Notification Options", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // 👁️ VIEW OPTION
              ListTile(
                leading: const Icon(Icons.remove_red_eye, color: Colors.indigo),
                title: const Text("View Notification"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => PDFViewerScreen(pdfUrl: pdfUrl, title: jobTitle),
                  ));
                },
              ),

              // 📥 DOWNLOAD OPTION
              ListTile(
                leading: const Icon(Icons.download, color: Colors.orange),
                title: const Text("Download PDF"),
                onTap: () {
                  Navigator.pop(context);
                  _downloadPDF(pdfUrl, "Job_Notification_${jobTitle.replaceAll(' ', '_')}");
                },
              ),

              // // 📤 SHARE OPTION
              // ListTile(
              //   leading: const Icon(Icons.share, color: Colors.green),
              //   title: const Text("Share PDF Link"),
              //   onTap: () {
              //     Navigator.pop(context);
              //     Share.share("Check out the official notification for $jobTitle: $pdfUrl");
              //   },
              // ),

              // 📤 SHARE OPTION (Updated)
              ListTile(
                leading: const Icon(Icons.share, color: Colors.green),
                title: const Text("Share Official Notification"),
                onTap: () {
                  Navigator.pop(context);

                  // 🚀 PDF ke link ki jagah Job Portal ki Website ka link bhejo
                  // Job Model mein aapke paas 'id' ya 'link' hota hai.
                  // Yahan main website ka format bana raha hoon:
                  String webUrl = "https://www.jobportal.shreejifintech.com/job/${widget.jobId}/";

                  Share.share(
                      "Check out the official notification for $jobTitle.\n\n"
                          "View full details and download PDF here:\n$webUrl"
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }


  Future<void> _checkAndFetchJob() async {
    final provider = Provider.of<JobProvider>(context, listen: false);
    bool jobExists = provider.jobs.any((j) => j.id.toString() == widget.jobId);

    if (!jobExists && widget.job == null) {
      setState(() => _isLoading = true);
      try {
        await provider.fetchJobs();
      } catch (e) {
        debugPrint("Error fetching jobs: $e");
      }
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openLink(String urlString) async {
    if (urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Link error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<JobProvider>(context);

    final Job? displayedJob = widget.job ??
        provider.jobs.cast<Job?>().firstWhere(
              (j) => j?.id.toString() == widget.jobId,
          orElse: () => null,
        );

    if (_isLoading || (displayedJob == null && provider.jobs.isEmpty)) {
      return Scaffold(
        appBar: AppBar(title: const Text("Job Details")),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.indigo),
        ),
      );
    }

    if (displayedJob == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Not Found")),
        body: const Center(child: Text("Sorry, this job is no longer available.")),
      );
    }

    final similarJobs = provider.jobs.where((j) {
      bool sharesCategory = j.categories.any((cat) => displayedJob.categories.contains(cat));
      return sharesCategory && j.id != displayedJob.id;
    }).toList();

    final isSaved = provider.isJobSaved(displayedJob.id);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(displayedJob.department, style: const TextStyle(fontSize: 16)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.grey),
            onPressed: () {
              final String shareMessage =
                  "🔥 New Job Opening: ${displayedJob.title}\n"
                  "📍 Location: ${displayedJob.location}\n"
                  "Check details: https://www.jobportal.shreejifintech.com/job/${displayedJob.id}/";
              Share.share(shareMessage);
            },
          ),
          IconButton(
            icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: isSaved ? Colors.indigo : Colors.grey),
            onPressed: () => provider.toggleSave(displayedJob.id),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    height: 80, width: 80,
                    decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20)
                    ),
                    child: Icon(
                      _getCategoryIcon(displayedJob.categories.isNotEmpty ? displayedJob.categories.first : ""),
                      size: 40,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(displayedJob.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(displayedJob.location, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 30),

            Row(
              children: [
                Expanded(child: _buildInfoCard(context, "Salary", displayedJob.salary, Icons.currency_rupee, valueColor: Colors.green)),
                const SizedBox(width: 15),
                Expanded(child: _buildInfoCard(context, "Deadline", displayedJob.deadline, Icons.calendar_today, valueColor: Colors.red)),
              ],
            ),
            const SizedBox(height: 30),

            const Text("Job Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(displayedJob.description, style: TextStyle(color: Colors.grey.shade600, height: 1.6)),
            const SizedBox(height: 30),

            if (displayedJob.requirements.isNotEmpty) ...[
              const Text("Requirements", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...displayedJob.requirements.map((req) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: Colors.indigo),
                    const SizedBox(width: 10),
                    Expanded(child: Text(req))
                  ],
                ),
              )),
              const SizedBox(height: 30),
            ],

            if (displayedJob.jobDescriptionFile != null && displayedJob.jobDescriptionFile!.isNotEmpty) ...[
              const Text("Official Notification", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _showPDFOptions(context, displayedJob.jobDescriptionFile!, displayedJob.title),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.picture_as_pdf, color: Colors.red, size: 30),
                      SizedBox(width: 15),
                      Expanded(
                        child: Text("Official Notification PDF", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Icon(Icons.more_vert, color: Colors.grey, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],

            const Divider(),
            const SizedBox(height: 20),

            if (similarJobs.isNotEmpty) ...[
              const Text(
                  "Similar Jobs",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 250,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: similarJobs.length,
                  separatorBuilder: (ctx, i) => const SizedBox(width: 15),
                  itemBuilder: (ctx, i) {
                    return Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: 320,
                        child: JobCard(job: similarJobs[i]),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: ElevatedButton(
          onPressed: () => _openLink(displayedJob.link),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text("Apply Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, String value, IconData icon, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.indigo, size: 18),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: valueColor ?? Theme.of(context).textTheme.bodyLarge?.color
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'PSU': return Icons.business;
      case 'Government': return Icons.account_balance;
      case 'Law': return Icons.balance;
      case 'Management': return Icons.groups;
      case 'Forest': return Icons.nature_people;
      case 'Accounts / Finance': return Icons.payments;
      case 'Education': return Icons.school;
      case 'Field Operations / Enforcement': return Icons.security;
      case 'Administration': return Icons.assignment_ind;
      case 'Medical': return Icons.medical_services;
      case 'Electrical': return Icons.electric_bolt;
      case 'Mechanical': return Icons.build;
      case 'Science & Technology': return Icons.science;
      case 'Railway': return Icons.train;
      case 'Engineering': return Icons.engineering;
      case 'Sports & Fitness': return Icons.fitness_center;
      case 'IT & Software': return Icons.laptop_chromebook;
      case 'Police': return Icons.local_police;
      case 'Banking': return Icons.savings;
      case 'Defense': return Icons.shield;
      default: return Icons.work;
    }
  }
}