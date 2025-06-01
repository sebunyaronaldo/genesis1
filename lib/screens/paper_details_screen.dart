import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class PaperDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> paper;

  const PaperDetailsScreen({super.key, required this.paper});

  @override
  State<PaperDetailsScreen> createState() => _PaperDetailsScreenState();
}

class _PaperDetailsScreenState extends State<PaperDetailsScreen> {
  bool _isLoading = true;
  String? _localPath;

  @override
  void initState() {
    super.initState();
    _downloadAndOpenPDF();
  }

  Future<void> _downloadAndOpenPDF() async {
    try {
      final url = widget.paper['url'] as String;
      final response = await http.get(Uri.parse(url));
      
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.paper['title']}');
      
      await file.writeAsBytes(response.bodyBytes);
      
      if (!mounted) return;
      setState(() {
        _localPath = file.path;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.paper['title'] ?? 'Paper Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _localPath == null
              ? const Center(child: Text('Error loading PDF'))
              : PDFView(
                  filePath: _localPath!,
                  enableSwipe: true,
                  swipeHorizontal: false,
                  autoSpacing: true,
                  pageFling: true,
                  pageSnap: true,
                  fitPolicy: FitPolicy.BOTH,
                  preventLinkNavigation: false,
                ),
    );
  }
} 