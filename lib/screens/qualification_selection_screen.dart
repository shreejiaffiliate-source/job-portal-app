import 'package:flutter/material.dart';
import '../data/qualifications.dart';
import 'qualification_jobs_screen.dart'; // We create this next

class QualificationSelectionScreen extends StatelessWidget {
  const QualificationSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Select Qualification", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).iconTheme,
      ),
      body: ListView.separated(
        itemCount: qualificationOptions.length,
        separatorBuilder: (ctx, i) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          return ListTile(
            title: Text(
                qualificationOptions[i],
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyLarge?.color
                )
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            onTap: () {
              // Navigate to results page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QualificationJobsScreen(qualification: qualificationOptions[i]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}