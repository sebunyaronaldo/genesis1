import 'package:flutter/material.dart';
import 'pdf_viewer_screen.dart';

class PaperDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> paperData;

  const PaperDetailsScreen({
    super.key,
    required this.paperData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(paperData['title'] ?? 'Paper Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              paperData['title'] ?? 'Untitled',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              paperData['subject'] ?? 'No subject',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (paperData['description'] != null) ...[
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(paperData['description']),
              const SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PdfViewerScreen(
                      paper: paperData,
                    ),
                  ),
                );
              },
              child: const Text('View Paper'),
            ),
          ],
        ),
      ),
    );
  }
} 