import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/job_provider.dart';
import '../models/job_model.dart';
import '../widgets/job_card.dart';

class StateJobsScreen extends StatelessWidget {
  final String stateName;
  const StateJobsScreen({super.key, required this.stateName});

  @override
  Widget build(BuildContext context) {
    final jobProvider = Provider.of<JobProvider>(context);

    // --- ROBUST FILTERING LOGIC ---
    final List<Job> stateJobs = jobProvider.jobs.where((job) {
      // 1. Convert everything to Lowercase & Remove extra spaces
      final jobLocation = job.location.toLowerCase().trim();
      final filterState = stateName.toLowerCase().trim();

      // 2. Debug Print: Check your console to see what is failing!
      // print("Checking: '$jobLocation' vs '$filterState'");

      // 3. Logic: Does the job location CONTAIN the state name?
      // e.g. "mumbai, maharashtra" contains "maharashtra" -> TRUE
      return jobLocation.contains(filterState);
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("$stateName Jobs"),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).iconTheme,
        titleTextStyle: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 20,
            fontWeight: FontWeight.bold
        ),
      ),
      body: stateJobs.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text(
              "No active jobs in $stateName",
              style: TextStyle(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 5),
            // Helpful text for debugging
            Text(
              "(Check exact spelling in Admin Panel)",
              style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: stateJobs.length,
        itemBuilder: (ctx, i) => JobCard(job: stateJobs[i]),
      ),
    );
  }
}