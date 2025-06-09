import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:genesis1/screens/pdf_viewer_screen.dart'; // Import PdfViewerScreen

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Favorites'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Text('Please log in to view your favorites.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('favorites')
            .doc(user.uid)
            .collection('papers')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No favorited papers yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final paper = snapshot.data!.docs[index];
              final data = paper.data() as Map<String, dynamic>;
              final String title = data['title'] ?? 'Untitled Paper';
              final String subject = data['subject'] ?? 'Unknown Subject';
              final String year = data['year'] ?? 'Unknown Year';

              return Column(
                children: [
                  ListTile(
                    title: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(
                      '${data['documentType'] ?? 'Unknown Type'} ${data['year'] ?? 'Unknown Year'}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.bookmark_border),
                      color: Colors.blue,
                      onPressed: () async {
                        // Logic to remove from favorites
                        await FirebaseFirestore.instance
                            .collection('favorites')
                            .doc(user.uid)
                            .collection('papers')
                            .doc(data['id'])
                            .delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('"$title" removed from favorites'),
                          ),
                        );
                      },
                    ),
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
                  ),
                  // const Divider(height: 1, indent: 16, endIndent: 16), // Removed Divider
                ],
              );
            },
          );
        },
      ),
    );
  }
} 