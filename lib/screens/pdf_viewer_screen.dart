import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/admob_service.dart';

class PdfViewerScreen extends StatefulWidget {
  final Map<String, dynamic> paper;

  const PdfViewerScreen({
    super.key,
    required this.paper,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    try {
      _bannerAd = AdMobService.createBannerAd()
        ..load().then((value) {
          if (mounted) {
            setState(() {
              _isBannerAdReady = true;
            });
            print('Banner ad loaded successfully');
          }
        }).catchError((error) {
          print('Error loading banner ad: $error');
          if (mounted) {
            setState(() {
              _isBannerAdReady = false;
            });
          }
        });
    } catch (e) {
      print('Error creating banner ad: $e');
      if (mounted) {
        setState(() {
          _isBannerAdReady = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _isBannerAdReady = false;
    super.dispose();
  }

  Future<void> _sharePDF(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Download the PDF
      final response = await http.get(Uri.parse(widget.paper['pdfUrl']));
      final bytes = response.bodyBytes;

      // Get temporary directory
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.paper['title']}.pdf');
      await file.writeAsBytes(bytes);

      // Hide loading indicator
      Navigator.pop(context);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Check out this paper: ${widget.paper['title']}',
      );
    } catch (e) {
      // Hide loading indicator if it's showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? pdfUrl = widget.paper['pdfUrl'];

    if (pdfUrl == null || pdfUrl.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.paper['title'] ?? 'PDF Viewer'),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cannot share: PDF URL is missing.'),
                  ),
                );
              },
            ),
          ],
        ),
        body: const Center(
          child: Text('Error: PDF URL is missing for this paper.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.paper['title'] ?? 'PDF Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _sharePDF(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          // PDF Viewer
          SfPdfViewer.network(
            pdfUrl,
            enableDoubleTapZooming: true,
            enableTextSelection: true,
            canShowScrollHead: true,
            canShowScrollStatus: true,
            pageSpacing: 8,
            initialZoomLevel: 1.0,
            maxZoomLevel: 3.0,
            enableDocumentLinkAnnotation: true,
            enableHyperlinkNavigation: true,
            pageLayoutMode: PdfPageLayoutMode.single,
            scrollDirection: PdfScrollDirection.vertical,
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              // Document loaded successfully
            },
            onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
              // Handle document load failure
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to load PDF: ${details.description}'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            onPageChanged: (PdfPageChangedDetails details) {
              // Page changed
            },
            onZoomLevelChanged: (PdfZoomDetails details) {
              // Zoom level changed
            },
            onHyperlinkClicked: (PdfHyperlinkClickedDetails details) {
              // Hyperlink clicked
            },
          ),
          // Sticky Banner Ad at the bottom
          if (_isBannerAdReady && _bannerAd != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: _bannerAd!.size.height.toDouble(),
                color: Colors.white,
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
        ],
      ),
    );
  }
} 