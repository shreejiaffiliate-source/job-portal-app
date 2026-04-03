import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/job_provider.dart';
import '../models/job_model.dart';
import '../widgets/job_card.dart';

class QualificationJobsScreen extends StatelessWidget {
  final String qualification;
  const QualificationJobsScreen({super.key, required this.qualification});

  @override
  Widget build(BuildContext context) {
    final jobProvider = Provider.of<JobProvider>(context);

    // --- 🚀 UPDATED FILTERING LOGIC (For List) ---
    final List<Job> filteredJobs = jobProvider.jobs.where((job) {
      final searchQual = qualification.toLowerCase().trim();

      // Check karein ki kya Job ki qualifications list mein ye qualification hai?
      return job.qualifications.any((q) {
        final currentQual = q.toLowerCase().trim();
        return currentQual == searchQual || currentQual.contains(searchQual);
      });
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("$qualification Jobs"),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).iconTheme,
        titleTextStyle: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 20,
            fontWeight: FontWeight.bold
        ),
      ),
      body: filteredJobs.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text(
              "No active jobs for $qualification",
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: filteredJobs.length,
        itemBuilder: (ctx, i) => JobCard(job: filteredJobs[i]),
      ),
    );
  }
}