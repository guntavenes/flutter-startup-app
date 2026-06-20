import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_startup_app/features/shared_lists/models/shared_member.dart';

import 'shared_list_repository.dart';

final sharedListRepositoryProvider = Provider<SharedListRepository>((ref) {
  return SharedListRepository();
});

final activeListIdProvider = FutureProvider<String>((ref) async {
  final repository = ref.watch(sharedListRepositoryProvider);
  return repository.ensureActiveList();
});

final inviteCodeProvider = FutureProvider<String?>((ref) async {
  final repository = ref.watch(sharedListRepositoryProvider);
  return repository.getInviteCode();
});

final membersProvider = StreamProvider<List<SharedMember>>((ref) {
  return ref.watch(sharedListRepositoryProvider).watchMembers();
});
