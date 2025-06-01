import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreInitializer {
  static Future<void> initializeData() async {
    final firestore = FirebaseFirestore.instance;

    // Add sample universities
    final universities = [
      'University of Example',
      'State University',
      'Technical University',
    ];

    for (final university in universities) {
      await firestore.collection('universities').add({
        'name': university,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // Add sample colleges
    final colleges = [
      {'name': 'College of Engineering', 'university': 'University of Example'},
      {'name': 'College of Science', 'university': 'University of Example'},
      {'name': 'College of Arts', 'university': 'State University'},
      {'name': 'College of Business', 'university': 'Technical University'},
    ];

    for (final college in colleges) {
      await firestore.collection('colleges').add({
        'name': college['name'],
        'university': college['university'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
} 