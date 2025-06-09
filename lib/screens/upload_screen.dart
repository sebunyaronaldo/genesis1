import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_selector/file_selector.dart';
import 'dart:typed_data';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _courseCodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedUniversity;
  String? _selectedFaculty;
  String? _selectedYear;
  String? _selectedDocumentType;
  XFile? _selectedPdfFile;
  bool _isUploading = false;

  // Define a list of default thumbnail image asset paths
  final List<String> _defaultThumbnailAssets = [
    'assets/images/default_pdf_thumbnail.png',
    'assets/images/default_thumb1.jpg',
    'assets/images/default_thumb2.jpg',
    'assets/images/default_thumb3.jpg',
    'assets/images/default_thumb4.jpg',
    'assets/images/default_thumb5.jpg',
    'assets/images/default_thumb6.jpg',
    'assets/images/default_thumb7.jpg',
  ];

  final List<String> _universities = ['MUK', 'MUBS'];
  final List<String> _faculties = [
    'College of Computing and Information Sciences',
    'College of Economics',
    'College of Engineering',
    'College of Science',
  ];
  final List<String> _years = [
    for (int y = 2015; y <= DateTime.now().year; y++) y.toString()
  ];
  final List<String> _documentTypes = [
    'Lecture Notes',
    'Finals Past Paper',
    'Course Work',
    'Midterm',
    'Other',
  ];

  Future<void> _pickPdfFile() async {
    final XFile? file = await openFile(
      acceptedTypeGroups: [
        XTypeGroup(
          label: 'PDF',
          extensions: ['pdf'],
        ),
      ],
    );
    if (file != null) {
      setState(() {
        _selectedPdfFile = file;
      });
    }
  }

  Future<void> _uploadPaper() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select files')),
      );
      return;
    }
    setState(() {
      _isUploading = true;
    });
    try {
      // Upload PDF
      final pdfRef = FirebaseStorage.instance
          .ref()
          .child('papers')
          .child('${DateTime.now().millisecondsSinceEpoch}_${_selectedPdfFile!.name}');
      await pdfRef.putData(await _selectedPdfFile!.readAsBytes());
      final pdfUrl = await pdfRef.getDownloadURL();

      // Assign a random default thumbnail
      final randomIndex = DateTime.now().millisecondsSinceEpoch % _defaultThumbnailAssets.length;
      final thumbnailUrl = _defaultThumbnailAssets[randomIndex];

      // Save to Firestore
      await FirebaseFirestore.instance.collection('papers').add({
        'title': _titleController.text.trim(),
        'courseCode': _courseCodeController.text.trim(),
        'university': _selectedUniversity,
        'faculty': _selectedFaculty,
        'year': _selectedYear,
        'documentType': _selectedDocumentType,
        'description': _descriptionController.text.trim(),
        'pdfUrl': pdfUrl,
        'thumbnailUrl': thumbnailUrl, // Assign the default thumbnail here
        'uploadDate': FieldValue.serverTimestamp(),
        'downloads': 0,
        'status': 'pending'.trim(), // Trim whitespace from status
      });
      _formKey.currentState!.reset();
      setState(() {
        _selectedPdfFile = null;
        _selectedUniversity = null;
        _selectedFaculty = null;
        _selectedYear = null;
        _selectedDocumentType = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paper uploaded successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading paper: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _courseCodeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Your Paper')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Paper Name',
                  hintText: 'e.g., Quantum Physics Midterm Exam',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a paper name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _courseCodeController,
                decoration: const InputDecoration(
                  labelText: 'Course Code',
                  hintText: 'e.g., PHY301',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a course code' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedUniversity,
                items: _universities.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (val) => setState(() => _selectedUniversity = val),
                decoration: const InputDecoration(
                  labelText: 'University',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null ? 'Select University' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedFaculty,
                items: _faculties.map((f) => DropdownMenuItem(value: f, child: Text(f, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (val) => setState(() => _selectedFaculty = val),
                decoration: const InputDecoration(
                  labelText: 'Faculty',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null ? 'Select Faculty' : null,
                isExpanded: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedYear,
                items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                onChanged: (val) => setState(() => _selectedYear = val),
                decoration: const InputDecoration(
                  labelText: 'Year',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null ? 'Select Year' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDocumentType,
                items: _documentTypes.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (val) => setState(() => _selectedDocumentType = val),
                decoration: const InputDecoration(
                  labelText: 'Document Type',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null ? 'Select Document Type' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Brief summary of the paper',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (value) => value == null || value.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _pickPdfFile,
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(_selectedPdfFile?.name ?? 'Upload PDF (Max 5MB)'),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadPaper,
                icon: _isUploading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.upload_file),
                label: Text(_isUploading ? 'Uploading...' : 'Upload Paper'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 