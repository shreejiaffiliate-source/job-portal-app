class Job {
  final String id; // Django sends 'id' as int, we convert to String
  final String title;
  final String department;
  final String location;
  final String deadline;
  final String salary;
  final List<String> categories;
  final List<String> requirements;
  final String description;
  final DateTime datePosted;
  final List<String> qualifications;
  final String link;
  final String? jobDescriptionFile;

  Job({
    required this.id,
    required this.title,
    required this.department,
    required this.location,
    required this.deadline,
    required this.salary,
    required this.categories,
    required this.requirements,
    required this.description,
    required this.datePosted,
    required this.qualifications,
    required this.link,
    this.jobDescriptionFile,
  });

  // --- NEW: Factory to convert JSON to Job object ---
  factory Job.fromJson(Map<String, dynamic> json) {
    print("Job Location: ${json['state_name']} | Qual: ${json['qualification_name']}");
    return Job(
      id: json['id'].toString(), // Django ID is int (1, 2), convert to String
      title: json['title'] ?? "No Title",
      department: json['department'] ?? "Unknown Dept",
      location: json['location'] ?? "Unknown Location",
      // Django sends YYYY-MM-DD, we might want to format it, or keep as string
      deadline: json['deadline'] ?? "",
      salary: json['salary'] ?? "Not Disclosed",
      categories: (json['categories'] as List?)?.map((item) => item.toString()).toList() ?? [],
      // Convert JSON List to String List
      requirements: List<String>.from(json['requirements'] ?? []),
      description: json['description'] ?? "",
      // Parse ISO Date string from Django
      datePosted: json['datePosted'] != null
          ? DateTime.parse(json['datePosted'])
          : DateTime.now(),
      qualifications: List<String>.from(json['qualifications'] ?? []),
      link: json['link'] ?? 'https://www.google.com',
      jobDescriptionFile: json['job_description_file'],

    );
  }
}