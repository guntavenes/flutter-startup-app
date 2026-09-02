import 'package:ceyizim_plus/features/shared_lists/data/shared_list_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'budget_repository.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(ref.watch(sharedListRepositoryProvider));
});

final budgetProvider = StreamProvider<double?>((ref) {
  return ref.watch(budgetRepositoryProvider).watchBudget();
});
