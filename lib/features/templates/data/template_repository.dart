import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_startup_app/features/templates/domain/template_item.dart';

class TemplateRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<TemplateItem>> getStandardTemplateItems() async {
    final snapshot = await _firestore
        .collection('templates')
        .doc('ceyiz_standart')
        .collection('items')
        .orderBy('order')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return TemplateItem(
        name: data['name'] as String,
        categoryName: data['category'] as String,
      );
    }).toList();
  }
}
