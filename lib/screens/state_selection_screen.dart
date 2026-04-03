import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <--- Import Provider
import '../providers/job_provider.dart'; // <--- Import JobProvider
import 'state_jobs_screen.dart';

class StateSelectionScreen extends StatefulWidget {
  final bool isSelectionMode;
  const StateSelectionScreen({super.key, this.isSelectionMode = false});

  @override
  State<StateSelectionScreen> createState() => _StateSelectionScreenState();
}

class _StateSelectionScreenState extends State<StateSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Note: We don't need initState to load data here anymore,
  // because HomeScreen calls fetchAllData() which loads the states.

  @override
  Widget build(BuildContext context) {
    // 1. Get the list of states from the API (via Provider)
    final jobProvider = Provider.of<JobProvider>(context);
    final allStates = jobProvider.states;

    // 2. Filter Logic: If search is empty, show all; otherwise filter by query
    final filteredStates = _searchController.text.isEmpty
        ? allStates
        : allStates.where((state) =>
        state.toLowerCase().contains(_searchController.text.toLowerCase())
    ).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.isSelectionMode ? "Select Location" : "Search by State"),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).iconTheme,
        titleTextStyle: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 20,
            fontWeight: FontWeight.bold
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              // Just trigger a rebuild when text changes so the filter above runs again
              onChanged: (val) => setState(() {}),
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: "Search State...",
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
          ),

          // List of States
          Expanded(
            child: filteredStates.isEmpty
                ? Center(
              child: Text(
                  "No states found",
                  style: TextStyle(color: Colors.grey.shade500)
              ),
            )
                : ListView.separated(
              itemCount: filteredStates.length,
              separatorBuilder: (ctx, i) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                return ListTile(
                  title: Text(
                      filteredStates[i],
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).textTheme.bodyLarge?.color
                      )
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade600),
                  onTap: () {
                    if (widget.isSelectionMode) {
                      // MODE 1: Return the selected state to Home Screen
                      Navigator.pop(context, filteredStates[i]);
                    } else {
                      // MODE 2: Open the jobs page (Drawer behavior)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StateJobsScreen(stateName: filteredStates[i]),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}