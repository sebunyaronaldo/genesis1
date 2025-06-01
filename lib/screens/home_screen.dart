import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../services/auth_service.dart';
import 'auth/login_screen.dart';
import 'paper_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedUniversity = 'All';
  String _selectedCollege = 'All';
  String _selectedYear = 'All';
  String _selectedType = 'All';
  List<String> _universities = ['All'];
  List<String> _colleges = ['All'];

  @override
  void initState() {
    super.initState();
    _loadUniversitiesAndColleges();
  }

  Future<void> _loadUniversitiesAndColleges() async {
    try {
      final universitiesSnapshot = await FirebaseFirestore.instance
          .collection('universities')
          .get();
      
      final collegesSnapshot = await FirebaseFirestore.instance
          .collection('colleges')
          .get();

      setState(() {
        _universities = ['All', ...universitiesSnapshot.docs.map((doc) => doc['name'] as String)];
        _colleges = ['All', ...collegesSnapshot.docs.map((doc) => doc['name'] as String)];
      });
    } catch (e) {
      debugPrint('Error loading universities and colleges: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Papers Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthService>(context, listen: false).signOut();
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedUniversity,
                    decoration: const InputDecoration(
                      labelText: 'University',
                      border: OutlineInputBorder(),
                    ),
                    items: _universities.map((university) {
                      return DropdownMenuItem(
                        value: university,
                        child: Text(university),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedUniversity = value!);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCollege,
                    decoration: const InputDecoration(
                      labelText: 'College',
                      border: OutlineInputBorder(),
                    ),
                    items: _colleges.map((college) {
                      return DropdownMenuItem(
                        value: college,
                        child: Text(college),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCollege = value!);
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Years')),
                      DropdownMenuItem(value: '2023', child: Text('2023')),
                      DropdownMenuItem(value: '2022', child: Text('2022')),
                      DropdownMenuItem(value: '2021', child: Text('2021')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedYear = value!);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Types')),
                      DropdownMenuItem(value: 'Exam', child: Text('Exam')),
                      DropdownMenuItem(value: 'Assignment', child: Text('Assignment')),
                      DropdownMenuItem(value: 'Quiz', child: Text('Quiz')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedType = value!);
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('papers')
                  .where('university', isEqualTo: _selectedUniversity == 'All' ? null : _selectedUniversity)
                  .where('college', isEqualTo: _selectedCollege == 'All' ? null : _selectedCollege)
                  .where('year', isEqualTo: _selectedYear == 'All' ? null : _selectedYear)
                  .where('type', isEqualTo: _selectedType == 'All' ? null : _selectedType)
                  .orderBy('uploadedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final papers = snapshot.data?.docs ?? [];

                if (papers.isEmpty) {
                  return const Center(child: Text('No papers found'));
                }

                return ListView.builder(
                  itemCount: papers.length,
                  itemBuilder: (context, index) {
                    final paper = papers[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(paper['title'] ?? ''),
                      subtitle: Text(
                        '${paper['university']} - ${paper['college']} - ${paper['year']}',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PaperDetailsScreen(paper: paper),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadPaper,
        child: const Icon(Icons.upload),
      ),
    );
  }

  Future<void> _uploadPaper() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null) return;

      final file = result.files.first;
      final fileName = file.name;
      final bytes = await file.readStream!.toList();
      final fileBytes = Uint8List.fromList(bytes.expand((x) => x).toList());

      // Upload file to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('papers')
          .child('${DateTime.now().millisecondsSinceEpoch}_$fileName');

      await storageRef.putData(fileBytes);

      // Get download URL
      final downloadUrl = await storageRef.getDownloadURL();

      // Save paper details to Firestore
      await FirebaseFirestore.instance.collection('papers').add({
        'title': fileName,
        'url': downloadUrl,
        'uploadedBy': Provider.of<AuthService>(context, listen: false).user?.uid,
        'uploadedAt': FieldValue.serverTimestamp(),
        'university': _selectedUniversity == 'All' ? 'Unknown' : _selectedUniversity,
        'college': _selectedCollege == 'All' ? 'Unknown' : _selectedCollege,
        'year': _selectedYear == 'All' ? 'Unknown' : _selectedYear,
        'type': _selectedType == 'All' ? 'Unknown' : _selectedType,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paper uploaded successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading paper: $e')),
      );
    }
  }
} 