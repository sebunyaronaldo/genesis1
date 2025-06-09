import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/admob_service.dart';
// import 'package:file_picker/file_picker.dart';  // Temporarily commented out
import 'dart:typed_data';
import 'paper_details_screen.dart';
import 'pdf_viewer_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'profile_screen.dart'; // Import ProfileScreen
// import 'settings_screen.dart'; // Import SettingsScreen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _categories = [
    'All',
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'Computer Science',
    'Engineering',
    'Business',
    'Economics',
  ];

  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Changed background to white
      appBar: AppBar(
        backgroundColor: Colors.white, // White AppBar background
        foregroundColor: Colors.black, // Dark text color for title
        elevation: 0, // No shadow
        title: const Text('Past Papers Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.black), // Profile icon
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          // IconButton(
          //   icon: const Icon(Icons.settings, color: Colors.black), // Dark settings icon
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (context) => const SettingsScreen()),
          //     );
          //   },
          // ),
        ],
      ),
      body: Column(
        children: [
          // Category filter
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.white, // White background for the category filter strip
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      _categories[index],
                      style: TextStyle(
                        color: _selectedCategory == _categories[index] ? Colors.white : Colors.black87,
                        fontWeight: _selectedCategory == _categories[index] ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: _selectedCategory == _categories[index],
                    selectedColor: Colors.blue, // Blue background for selected chip
                    backgroundColor: Colors.white, // White background for unselected chip
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: _selectedCategory == _categories[index] ? Colors.blue : Colors.grey.shade300,
                      ),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = _categories[index];
                        });
                      }
                    },
                    // Add checkmark for selected chip
                    avatar: _selectedCategory == _categories[index]
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              },
            ),
          ),
          // Papers list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _selectedCategory == 'All'
                  ? FirebaseFirestore.instance.collection('papers').where('status', isEqualTo: 'approved').snapshots()
                  : FirebaseFirestore.instance
                      .collection('papers')
                      .where('category', isEqualTo: _selectedCategory)
                      .where('status', isEqualTo: 'approved')
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No papers found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0), // Add padding for the list
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final paper = snapshot.data!.docs[index];
                    final data = paper.data() as Map<String, dynamic>;
                    data['id'] = paper.id; // Ensure document ID is included
                    
                    return PaperCard(
                      title: data['title'] ?? 'Untitled',
                      courseCode: data['courseCode'] ?? 'No course code',
                      university: data['university'] ?? 'Unknown university',
                      faculty: data['faculty'] ?? 'Unknown faculty',
                      year: data['year'] ?? 'Unknown year',
                      documentType: data['documentType'] ?? 'Unknown type',
                      thumbnailUrl: data['thumbnailUrl'],
                      description: data['description'],
                      paperData: data,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PdfViewerScreen(
                              paper: data,
                            ),
                          ),
                        );
                      },
                    );
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

class PaperCard extends StatefulWidget {
  final String title;
  final String courseCode;
  final String university;
  final String faculty;
  final String year;
  final String documentType;
  final String? thumbnailUrl;
  final String? description;
  final VoidCallback onTap;
  final Map<String, dynamic> paperData;

  const PaperCard({
    super.key,
    required this.title,
    required this.courseCode,
    required this.university,
    required this.faculty,
    required this.year,
    required this.documentType,
    this.thumbnailUrl,
    this.description,
    required this.onTap,
    required this.paperData,
  });

  @override
  State<PaperCard> createState() => _PaperCardState();
}

class _PaperCardState extends State<PaperCard> {
  @override
  void initState() {
    super.initState();
  }

  // Toggle favorite status
  void _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not logged in. Cannot favorite paper.');
      return;
    }

    final favoriteRef = FirebaseFirestore.instance
        .collection('favorites')
        .doc(user.uid)
        .collection('papers')
        .doc(widget.paperData['id']);

    try {
      final doc = await favoriteRef.get();
      if (doc.exists) {
        await favoriteRef.delete();
        print('Paper removed from favorites');
      } else {
        await favoriteRef.set(widget.paperData);
        print('Paper added to favorites');
      }
    } catch (e) {
      print('Error toggling favorite status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser; // Get current user in build method

    return StreamBuilder<DocumentSnapshot>(
      stream: user != null
          ? FirebaseFirestore.instance
              .collection('favorites')
              .doc(user.uid)
              .collection('papers')
              .doc(widget.paperData['id'])
              .snapshots()
          : null, // No stream if user is not logged in
      builder: (context, snapshot) {
        // Default to not favorited if no user or no data
        final bool isFavorited = user != null && snapshot.hasData && snapshot.data!.exists;

    return Card(
          margin: const EdgeInsets.only(bottom: 16.0), // Margin between cards
          elevation: 4.0, // Increased elevation for a more prominent shadow
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)), // More rounded corners
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                // Thumbnail Image
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
                  child: (widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty)
                      ? (widget.thumbnailUrl!.startsWith('assets/images/'))
                          ? Image.asset(
                              widget.thumbnailUrl!,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 180,
                                color: Colors.grey[300],
                                child: const Center(child: Icon(Icons.broken_image)),
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: widget.thumbnailUrl!,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 180,
                                color: Colors.grey[300],
                                child: const Center(child: CircularProgressIndicator()),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 180,
                                color: Colors.grey[300],
                                child: const Center(child: Icon(Icons.broken_image)),
                              ),
                            )
                      : Container(
                          height: 180,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: Center(
                            child: Image.asset(
                              'assets/images/default_pdf_thumbnail.png',
                              fit: BoxFit.cover,
                              height: 100,
                              width: 100,
                            ),
                          ),
                        ),
                ),
                // Paper Details
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                          Expanded(
                            child: Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: 22, // Larger font size for title
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Favorite icon
                          if (user != null) // Only show favorite icon if user is logged in
                            IconButton(
                              icon: Icon(
                                isFavorited ? Icons.bookmark_added : Icons.bookmark_add_outlined,
                                color: isFavorited ? Colors.blue : Colors.grey[700],
                                size: 28,
                              ),
                              onPressed: _toggleFavorite,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.courseCode,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600], // Lighter color for course code
                        ),
                      ),
                      const SizedBox(height: 16),
                      // University, Faculty, Year chips
                      Wrap(
                        spacing: 8.0, // Space between chips
                        runSpacing: 8.0, // Space between rows of chips
                        children: [
                          // University chip
                          _buildInfoChip(Icons.account_balance, widget.university),
                          // Faculty chip
                          _buildInfoChip(Icons.school, widget.faculty),
                          // Year chip
                          _buildInfoChip(Icons.calendar_today, widget.year),
                          // Document Type chip (button-like)
                    Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                              color: Colors.blue, // Solid blue background
                              borderRadius: BorderRadius.circular(20), // More rounded corners
                  ),
                            child: Flexible(
                  child: Text(
                        widget.documentType,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                overflow: TextOverflow.ellipsis, // Add ellipsis for overflow
                                maxLines: 1, // Limit to a single line
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                ),
              ),
            ],
          ),
        ),
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade200, // Light grey background for chips
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]), // Icon color
          const SizedBox(width: 6),
          Flexible( // Use Flexible to prevent overflow
            child: Text(text,
                style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                overflow: TextOverflow.ellipsis, // Add ellipsis for overflow
                maxLines: 1), // Limit to a single line
          ),
        ],
      ),
    );
  }
}

class PaperSearchDelegate extends SearchDelegate {
  // Add state variables for filters and dropdowns
  String _selectedSortOption = 'Relevance'; // Default sort option
  String? _selectedUniversity;
  String? _selectedFaculty;
  String? _selectedYear;
  String? _selectedDocumentType;

  final List<String> _sortOptions = ['Relevance', 'Date', 'Popularity'];
  final List<String> _universities = ['MUK', 'MUBS', 'KYU', 'UMU', 'MAK', 'LU', 'CU', 'Ndejje University', 'KIU', 'Gulu University']; // Example universities
  final List<String> _faculties = [
    'College of Computing and Information Sciences',
    'College of Economics and Management',
    'College of Engineering, Design, Art and Technology',
    'College of Natural Sciences',
    'School of Law',
    'Faculty of Medicine',
    'Faculty of Agriculture',
    'Faculty of Arts and Humanities',
    'Faculty of Education',
    'Faculty of Social Sciences',
  ]; // Example faculties
  final List<String> _years = List<String>.generate(10, (i) => (DateTime.now().year - i).toString()); // Last 10 years
  final List<String> _documentTypes = ['Finals Past Paper', 'Course Work', 'Midterm', 'Lecture Notes', 'Other']; // Example document types

  @override
  String get searchFieldLabel => 'Search papers...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: TextStyle(color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12.0)),
          borderSide: BorderSide.none,
        ),
      ),
      textTheme: theme.textTheme.copyWith(
        titleLarge: const TextStyle(color: Colors.black), // For the search query text
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // This will be updated later to incorporate filters
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter Chips for Relevance, Date, Popularity
              Wrap(
                spacing: 8.0,
                children: _sortOptions.map((option) {
                  return ChoiceChip(
                    label: Text(option),
                    selected: _selectedSortOption == option,
                    onSelected: (selected) {
                      if (selected) {
                          setState(() {
                          _selectedSortOption = option;
                        });
                      }
                    },
                          );
                        }).toList(),
              ),
              const SizedBox(height: 24.0),
              // Filter Section
              Text(
                'Filter',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16.0),

              // University Dropdown
              _buildDropdown(
                context,
                'University',
                _universities,
                _selectedUniversity,
                (value) {
                          setState(() {
                    _selectedUniversity = value;
                          });
                        },
                'Select University',
              ),
              const SizedBox(height: 16.0),

              // Faculty Dropdown
              _buildDropdown(
                context,
                'Faculty',
                _faculties,
                _selectedFaculty,
                (value) {
                          setState(() {
                    _selectedFaculty = value;
                          });
                        },
                'Select Faculty',
              ),
              const SizedBox(height: 16.0),

              // Year Dropdown
              _buildDropdown(
                context,
                'Year',
                _years,
                _selectedYear,
                (value) {
                          setState(() {
                    _selectedYear = value;
                          });
                        },
                'Select Year',
              ),
              const SizedBox(height: 16.0),

              // Document Type Dropdown
              _buildDropdown(
                context,
                'Document Type',
                _documentTypes,
                _selectedDocumentType,
                (value) {
                                setState(() {
                    _selectedDocumentType = value;
                  });
                },
                'Select Document Type',
              ),
              const SizedBox(height: 24.0),

              // Display search results for suggestions, initially empty or showing popular searches
              _buildSearchResults(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDropdown(
    BuildContext context,
    String label,
    List<String> options,
    String? selectedValue,
    ValueChanged<String?> onChanged,
    String hintText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8.0),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              hint: Text(hintText),
              value: selectedValue,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              items: options.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: onChanged,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty &&
        _selectedUniversity == null &&
        _selectedFaculty == null &&
        _selectedYear == null &&
        _selectedDocumentType == null) {
      return const Center(
        child: Text('Start typing or apply filters to search papers'),
      );
    }

    return StreamBuilder<QuerySnapshot>(
                  stream: _buildFilteredSearchStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No papers found for your search.'));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final paper = snapshot.data!.docs[index];
            final data = paper.data() as Map<String, dynamic>;
            data['id'] = paper.id; // Ensure document ID is included
            return PaperCard(
              title: data['title'] ?? 'Untitled',
              courseCode: data['courseCode'] ?? 'No course code',
              university: data['university'] ?? 'Unknown university',
              faculty: data['faculty'] ?? 'Unknown faculty',
              year: data['year'] ?? 'Unknown year',
              documentType: data['documentType'] ?? 'Unknown type',
              thumbnailUrl: data['thumbnailUrl'],
              description: data['description'],
              paperData: data,
                onTap: () {
                Navigator.push(
                  context,
                    MaterialPageRoute(
                    builder: (context) => PdfViewerScreen(
                      paper: data,
                    ),
              ),
            );
          },
                    );
                  },
        );
      },
    );
  }

  // Helper method to build the Firestore query based on filters and search query
  Stream<QuerySnapshot> _buildFilteredSearchStream() {
    Query queryRef = FirebaseFirestore.instance.collection('papers');

    // Always filter by 'approved' status for moderation
    queryRef = queryRef.where('status', isEqualTo: 'approved');

    // Apply keyword search on title (case-insensitive and partial match)
    if (query.isNotEmpty) {
      queryRef = queryRef
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: query + 'z');
    }

    // Apply filters
    if (_selectedUniversity != null) {
      queryRef = queryRef.where('university', isEqualTo: _selectedUniversity);
    }
    if (_selectedFaculty != null) {
      queryRef = queryRef.where('faculty', isEqualTo: _selectedFaculty);
    }
    if (_selectedYear != null) {
      queryRef = queryRef.where('year', isEqualTo: _selectedYear);
    }
    if (_selectedDocumentType != null) {
      queryRef = queryRef.where('documentType', isEqualTo: _selectedDocumentType);
    }

    // Apply sorting
    switch (_selectedSortOption) {
      case 'Date':
        queryRef = queryRef.orderBy('uploadedAt', descending: true); // Assuming a timestamp field 'uploadedAt'
        break;
      case 'Popularity':
        queryRef = queryRef.orderBy('views', descending: true); // Assuming a 'views' or 'downloads' field
        break;
      case 'Relevance':
      default:
        // For relevance, basic search on title is applied above.
        // More advanced relevance would require a dedicated search solution (e.g., Algolia, ElasticSearch).
        // If no specific order is set, Firestore defaults to ordering by document ID (ascending).
        queryRef = queryRef.orderBy('title'); // Order by title for consistency if no other sort is selected.
        break;
    }

    // Note: Firestore has limitations on combining 'where' clauses with different fields
    // and 'orderBy' clauses on fields not in the where clause, unless an index is created.
    // Ensure composite indexes are created in your Firestore console if you encounter issues.

    return queryRef.snapshots();
  }
} 