import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ModerationScreen extends StatelessWidget {
  const ModerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel - Paper Moderation'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('papers').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No papers to moderate.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final paper = snapshot.data!.docs[index];
              final data = paper.data() as Map<String, dynamic>;
              final paperId = paper.id;

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'] ?? 'Untitled Paper',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Course Code: ${data['courseCode'] ?? 'N/A'}'),
                      Text('University: ${data['university'] ?? 'N/A'}'),
                      Text('Faculty: ${data['faculty'] ?? 'N/A'}'),
                      Text('Year: ${data['year'] ?? 'N/A'}'),
                      Text('Document Type: ${data['documentType'] ?? 'N/A'}'),
                      Text('Status: ${data['status'] ?? 'N/A'}'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('papers')
                                  .doc(paperId)
                                  .update({'status': 'approved'});
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Paper Approved!')));
                            },
                            child: const Text('Approve'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('papers')
                                  .doc(paperId)
                                  .update({'status': 'rejected'});
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Paper Rejected!')));
                            },
                            child: const Text('Reject'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 