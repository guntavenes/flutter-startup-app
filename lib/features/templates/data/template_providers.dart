import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ceyizim_plus/features/templates/domain/template_item.dart';

import 'template_repository.dart';

final templateRepositoryProvider = Provider<TemplateRepository>((ref) {
  return TemplateRepository();
});

final standardTemplateItemsProvider = FutureProvider<List<TemplateItem>>((
  ref,
) async {
  final repository = ref.watch(templateRepositoryProvider);
  return repository.getStandardTemplateItems();
});
