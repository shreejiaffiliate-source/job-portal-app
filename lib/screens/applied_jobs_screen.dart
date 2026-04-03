import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/job_provider.dart';
import '../widgets/job_card.dart';

class AppliedJobsScreen extends StatelessWidget {
  const AppliedJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access applied jobs from provider
    final appliedJobs = Provider.of<JobProvider>(context).appliedJobs;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
            'Applied Jobs',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).appBarTheme.titleTextStyle?.color
            )
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: Theme.of(context).iconTheme,
      ),
      body: appliedJobs.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text("You haven't applied to any jobs yet", style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: appliedJobs.length,
        itemBuilder: (ctx, i) => JobCard(job: appliedJobs[i]),
      ),
    );
  }
}