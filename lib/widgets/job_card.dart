import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/job_model.dart';
import '../providers/job_provider.dart';
import '../screens/job_detail_screen.dart';

class JobCard extends StatelessWidget {
  final Job job;
  const JobCard({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<JobProvider>(context);
    final isSaved = provider.isJobSaved(job.id);
    final isApplied = provider.isJobApplied(job.id);

    final titleColor = Theme.of(context).textTheme.bodyLarge?.color;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => JobDetailScreen(job: job, jobId: job.id.toString(),)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 🚀 Dynamic Icon Box (Now with more categories!)
                Container(
                  height: 40, width: 40,
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_getCategoryIcon(job.categories.isNotEmpty ? job.categories.first : ""), color: Colors.indigo),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: titleColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        job.department,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: isSaved ? Colors.indigo : Colors.grey,
                  ),
                  onPressed: () {
                    provider.toggleSave(job.id);
                  },
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildChip(Icons.location_on_outlined, job.location),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  // 🚀 Deadline Red Color
                  child: _buildChip(Icons.access_time, job.deadline, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    job.salary,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  isApplied ? "Applied" : "View Details",
                  style: TextStyle(
                    color: isApplied ? Colors.green : Colors.indigo,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String text, {Color color = Colors.grey}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: color == Colors.red ? FontWeight.w600 : FontWeight.normal
            ),
            softWrap: true,
          ),
        ),
      ],
    );
  }

  // 🚀 Updated Category Mapping based on your list
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'PSU':
        return Icons.business;
      case 'Government':
        return Icons.account_balance;
      case 'Law':
        return Icons.balance;
      case 'Management':
        return Icons.groups;
      case 'Forest':
        return Icons.nature_people;
      case 'Accounts / Finance':
        return Icons.payments;
      case 'Education':
        return Icons.school;
      case 'Field Operations / Enforcement':
        return Icons.security;
      case 'Administration':
        return Icons.assignment_ind;
      case 'Medical':
        return Icons.medical_services;
      case 'Electrical':
        return Icons.electric_bolt;
      case 'Mechanical':
        return Icons.build;
      case 'Science & Technology':
        return Icons.science;
      case 'Railway':
        return Icons.train;
      case 'Engineering':
        return Icons.engineering;
      case 'Sports & Fitness':
        return Icons.fitness_center;
      case 'IT & Software':
        return Icons.laptop_chromebook;
      case 'Police':
        return Icons.local_police;
      case 'Banking':
        return Icons.savings;
      case 'Defense':
        return Icons.shield;
      default:
        return Icons.work; // Fallback icon
    }
  }
}