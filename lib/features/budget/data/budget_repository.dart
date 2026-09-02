import 'package:ceyizim_plus/features/shared_lists/data/shared_list_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetRepository {
  BudgetRepository(this._sharedListRepository);

  final SharedListRepository _sharedListRepository;

  Stream<double?> watchBudget() async* {
    final listRef = await _sharedListRepository.getActiveListRef();
    yield* listRef.snapshots().map(
      (snapshot) => (snapshot.data()?['budget'] as num?)?.toDouble(),
    );
  }

  Future<void> updateBudget(double? budget) async {
    final listRef = await _sharedListRepository.getActiveListRef();
    await listRef.set({
      'budget': budget ?? FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
