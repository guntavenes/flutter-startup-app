import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'brand_repository.dart';

final brandRepositoryProvider = Provider<BrandRepository>((ref) {
  return BrandRepository();
});

final brandsByCategoryProvider = FutureProvider.family<List<String>, String>((
  ref,
  categoryName,
) async {
  final repository = ref.watch(brandRepositoryProvider);
  final brands = await repository.getBrandsByCategory(categoryName);

  return [...brands, 'Diğer'];
});
