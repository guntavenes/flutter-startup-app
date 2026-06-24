import 'package:cloud_firestore/cloud_firestore.dart';

class BrandRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<String>> getBrandsByCategory(String categoryName) async {
    final snapshot = await _firestore
        .collection('brands')
        .where('categoryName', isEqualTo: categoryName)
        .where('active', isEqualTo: true)
        .get();

    final docs = snapshot.docs.toList();

    docs.sort((a, b) {
      final aOrder = a.data()['order'] as int? ?? 0;
      final bOrder = b.data()['order'] as int? ?? 0;

      return aOrder.compareTo(bOrder);
    });

    return docs.map((doc) => doc.data()['name'] as String).toList();
  }
}
