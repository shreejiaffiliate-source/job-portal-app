import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/job_model.dart';
import '../providers/job_provider.dart';
import '../widgets/job_card.dart';
import '../widgets/main_drawer.dart';
import 'saved_jobs_screen.dart';
import 'profile_screen.dart';
import '../providers/user_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  String _selectedCategory = "Latest";
  int _selectedIndex = 0;

  late PageController _pageController;
  late ScrollController _categoryScrollController;
  int _currentCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _categoryScrollController = ScrollController();

    Future.microtask(() =>
        Provider.of<JobProvider>(context, listen: false).fetchAllData()
    );
    // Future.microtask(() =>
    //     Provider.of<UserProvider>(context, listen: false).loadUser()
    // );

    //for app drawer data fatch
    Future.microtask(() {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.fetchUserProfile(); // Ye API call karega aur saara data (photo ke sath) set kar dega
    });

  }

  @override
  void dispose() {
    _pageController.dispose();
    _categoryScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // 🚀 REFRESH LOGIC
  Future<void> _refreshData() async {
    await Provider.of<JobProvider>(context, listen: false).fetchAllData();
    if (mounted) {
      await Provider.of<UserProvider>(context, listen: false).loadUser();
    }
  }

  // 🎯 Helper logic to get the dynamic count for the current view
  int _getFilteredCount(JobProvider jobProvider) {
    List<Job> filteredJobs = List.from(jobProvider.jobs);

    // 1. Category Filter
    if (_selectedCategory != "Latest") {
      filteredJobs = filteredJobs.where((job) => job.categories.contains(_selectedCategory)).toList();
    }

    // 2. Search Filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      filteredJobs = filteredJobs.where((job) {
        bool catMatch = job.categories.any((c) => c.toLowerCase().contains(query));
        bool qualMatch = job.qualifications.any((q) => q.toLowerCase().contains(query));
        return job.title.toLowerCase().contains(query) ||
            job.location.toLowerCase().contains(query) ||
            catMatch || qualMatch;
      }).toList();
    }

    return filteredJobs.length;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _scrollToCategory(int index) {
    double offset = index * 100.0;
    if (_categoryScrollController.hasClients) {
      _categoryScrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildTightIcon(IconData icon, VoidCallback onTap, Color? color) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, size: 22, color: color),
      ),
    );
  }

  Future<void> _launchExternalURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint("Error launching URL: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobProvider = Provider.of<JobProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final String displayName = userProvider.name.isNotEmpty ? userProvider.name : "Candidate";

    final Widget currentScreen;
    switch (_selectedIndex) {
      case 1: currentScreen = const SavedJobsScreen(); break;
      case 2: currentScreen = const ProfileScreen(); break;
      default: currentScreen = _buildHomeContent();
    }

    return PopScope(
        canPop: false, // System back button block kiya
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;

          // 🎯 1. Agar Drawer khula hai toh band karo
          if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
            _scaffoldKey.currentState?.closeDrawer();
            return;
          }

          // 🎯 2. Agar Profile Screen ka SettingsDrawer (EndDrawer) khula hai toh use band karo
          if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
            _scaffoldKey.currentState?.closeEndDrawer();
            return;
          }

          // 🎯 3. Agar Home tab par ho, tab Exit pooncho
          final bool shouldExit = await _showExitDialog(context);
          if (shouldExit) {
            SystemNavigator.pop();
          }
        },
        child: Scaffold(
          key: _scaffoldKey, // 👈 Key zaroori hai drawer control ke liye
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: MainDrawer(
        onFilterSelected: (selectedValue) {
          final jobProvider = Provider.of<JobProvider>(context, listen: false);
          final allCategories = ["Latest", ...jobProvider.categories];

          int catIndex = allCategories.indexOf(selectedValue);

          if (catIndex != -1) {
            setState(() {
              _selectedCategory = selectedValue;
              _currentCategoryIndex = catIndex;
              _searchQuery = "";
              _searchController.clear();
              _selectedIndex = 0;
            });
            _pageController.jumpToPage(catIndex);
            _scrollToCategory(catIndex);
          } else {
            setState(() {
              _searchController.text = selectedValue;
              _searchQuery = selectedValue;
              _selectedIndex = 0;
              _selectedCategory = "Latest";
              _currentCategoryIndex = 0;
            });
            _pageController.jumpToPage(0);
          }
        },
      ),
      appBar: _selectedIndex == 0
          ? AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).iconTheme,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hello, $displayName", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text(
              "Find your Dream Job",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTightIcon(FontAwesomeIcons.whatsapp, () => _launchExternalURL("https://chat.whatsapp.com/IlcQfuFpKZV3Odf5jhoNB7"), textColor),
              _buildTightIcon(Icons.language, () => _launchExternalURL("https://www.jobportal.shreejifintech.com/"), textColor),
              _buildTightIcon(Icons.share, () => Share.share('Check out this amazing GovJob Portal app!'), textColor),
            ],
          ),
          const SizedBox(width: 5),
        ],
      )
          : null,
      body: SafeArea(child: currentScreen),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark_border), label: 'Saved'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
        )
    );

  }

  Future<bool> _showExitDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        title: Text("Exit App", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(ctx).textTheme.bodyLarge?.color)),
        content: Text("Do you really want to exit?", style: TextStyle(color: Theme.of(ctx).textTheme.bodyMedium?.color)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("No")),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Yes", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;
  }

  Widget _buildHomeContent() {
    final jobProvider = Provider.of<JobProvider>(context);
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final categories = ["Latest", ...jobProvider.categories];
    int currentJobCount = _getFilteredCount(jobProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        _buildCategories(jobProvider, categories),
        const SizedBox(height: 15),
        _buildSearchBar(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _searchQuery.isNotEmpty ? "Search Results" : "$_selectedCategory Openings",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "$currentJobCount Jobs Found",
                        style: const TextStyle(fontSize: 12, color: Colors.indigo, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Swipe for more",
                    style: TextStyle(fontSize: 10, color: Colors.indigo.shade300, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Categories",
                    style: TextStyle(fontSize: 10, color: Colors.indigo.shade300, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: categories.length,
            onPageChanged: (index) {
              setState(() {
                _currentCategoryIndex = index;
                _selectedCategory = categories[index];
              });
              _scrollToCategory(index);
            },
            itemBuilder: (ctx, catIndex) {
              String currentCat = categories[catIndex];
              List<Job> pageJobs = List.from(jobProvider.jobs);

              if (currentCat != "Latest") {
                pageJobs = pageJobs.where((job) => job.categories.contains(currentCat)).toList();
              }

              if (_searchQuery.isNotEmpty) {
                final query = _searchQuery.toLowerCase().trim();
                pageJobs = pageJobs.where((job) {
                  bool catMatch = job.categories.any((c) => c.toLowerCase().contains(query));
                  bool qualMatch = job.qualifications.any((q) => q.toLowerCase().contains(query));
                  return job.title.toLowerCase().contains(query) ||
                      job.location.toLowerCase().contains(query) ||
                      catMatch || qualMatch;
                }).toList();
              }

              pageJobs.sort((a, b) {
                int idA = int.tryParse(a.id.toString()) ?? 0;
                int idB = int.tryParse(b.id.toString()) ?? 0;
                return idB.compareTo(idA);
              });

              return RefreshIndicator(
                onRefresh: _refreshData,
                color: Colors.white,
                backgroundColor: Colors.indigo,
                child: jobProvider.isLoading && pageJobs.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
                    : pageJobs.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: pageJobs.length,
                  itemBuilder: (ctx, i) => JobCard(job: pageJobs[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategories(JobProvider provider, List<String> categories) {
    return SizedBox(
      height: 45,
      child: ListView.separated(
        controller: _categoryScrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) {
          final category = categories[i];
          final isSelected = i == _currentCategoryIndex;

          return GestureDetector(
            onTap: () {
              setState(() {
                _currentCategoryIndex = i;
                _selectedCategory = category;
              });
              _pageController.animateToPage(
                i,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.indigo : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(25),
                border: isSelected ? null : Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        decoration: InputDecoration(
          hintText: "Search by Job, Category, or State...",
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.indigo),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ""); })
              : null,
          filled: true,
          fillColor: Theme.of(context).cardColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.indigo, width: 1.5)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text("No jobs match your selection", style: TextStyle(color: Colors.grey.shade500), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = "";
                  _selectedCategory = "Latest";
                  _currentCategoryIndex = 0;
                });
                _pageController.jumpToPage(0);
              },
              child: const Text("Clear All Filters"),
            )
          ],
        ),
      ],
    );
  }
}