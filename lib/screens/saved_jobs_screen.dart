import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/job_provider.dart';
import '../widgets/job_card.dart';

class SavedJobsScreen extends StatelessWidget {
  const SavedJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final savedJobs = Provider.of<JobProvider>(context).savedJobs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Jobs', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: savedJobs.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text("No saved jobs yet", style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: savedJobs.length,
        itemBuilder: (ctx, i) => JobCard(job: savedJobs[i]),
      ),
    );
  }
}