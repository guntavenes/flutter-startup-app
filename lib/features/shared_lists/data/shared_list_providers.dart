import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shared_list_repository.dart';

final sharedListRepositoryProvider = Provider<SharedListRepository>((ref) {
  return SharedListRepository();
});

final activeListIdProvider = FutureProvider<String>((ref) async {
  final repository = ref.watch(sharedListRepositoryProvider);
  return repository.ensureActiveList();
});
