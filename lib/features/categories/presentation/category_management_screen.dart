import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../items/data/item_providers.dart';
import '../data/category_providers.dart';

class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  List<Map<String, dynamic>> get _iconOptions => [
    {'name': 'category', 'icon': Icons.category_rounded, 'label': 'Genel'},
    {'name': 'restaurant', 'icon': Icons.restaurant_rounded, 'label': 'Mutfak'},
    {'name': 'bed', 'icon': Icons.bed_rounded, 'label': 'Yatak'},
    {'name': 'shower', 'icon': Icons.shower_rounded, 'label': 'Banyo'},
    {'name': 'weekend', 'icon': Icons.weekend_rounded, 'label': 'Salon'},
    {
      'name': 'electrical',
      'icon': Icons.electrical_services_rounded,
      'label': 'Elektronik',
    },
    {
      'name': 'laundry',
      'icon': Icons.local_laundry_service_rounded,
      'label': 'Beyaz Eşya',
    },
    {'name': 'home', 'icon': Icons.home_rounded, 'label': 'Ev'},
    {'name': 'favorite', 'icon': Icons.favorite_rounded, 'label': 'Özel'},
    {
      'name': 'shopping',
      'icon': Icons.shopping_bag_rounded,
      'label': 'Alışveriş',
    },
  ];

  IconData _categoryIcon(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'bed':
        return Icons.bed_rounded;
      case 'shower':
        return Icons.shower_rounded;
      case 'weekend':
        return Icons.weekend_rounded;
      case 'electrical':
        return Icons.electrical_services_rounded;
      case 'laundry':
        return Icons.local_laundry_service_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'favorite':
        return Icons.favorite_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  String _categoryDescription(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return 'Mutfak eşyaları ve sofra ürünleri';
      case 'bed':
        return 'Nevresim, yorgan ve oda ürünleri';
      case 'shower':
        return 'Banyo ve temizlik ihtiyaçları';
      case 'weekend':
        return 'Salon dekorasyon ve ev ürünleri';
      case 'electrical':
        return 'Küçük ev aletleri ve cihazlar';
      case 'laundry':
        return 'Büyük ev eşyaları';
      case 'home':
        return 'Ev ihtiyaçları';
      case 'favorite':
        return 'Özel kategori';
      case 'shopping':
        return 'Alışveriş ürünleri';
      default:
        return 'Özel kategori';
    }
  }

  Future<void> _showCategoryDialog(
    BuildContext context,
    WidgetRef ref, {
    Category? category,
  }) async {
    final controller = TextEditingController(text: category?.name ?? '');
    String selectedIconName = category?.iconName ?? 'category';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                category == null ? 'Kategori Ekle' : 'Kategori Düzenle',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Kategori adı',
                        hintText: 'Örn: Beyaz Eşya',
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'İkon seç',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6D4C5B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _iconOptions.map((option) {
                        final iconName = option['name'] as String;
                        final icon = option['icon'] as IconData;
                        final label = option['label'] as String;
                        final isSelected = selectedIconName == iconName;

                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedIconName = iconName;
                            });
                          },
                          child: Container(
                            width: 76,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFFE3F1)
                                  : const Color(0xFFF9F4F7),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFD96BA7)
                                    : const Color(0xFFEAD5DF),
                                width: isSelected ? 1.6 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  icon,
                                  color: isSelected
                                      ? const Color(0xFFD96BA7)
                                      : const Color(0xFF8A6B79),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isSelected
                                        ? FontWeight.w900
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? const Color(0xFFD96BA7)
                                        : const Color(0xFF8A6B79),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Vazgeç'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final repo = ref.read(categoryRepositoryProvider);

                      if (category == null) {
                        await repo.addCategory(
                          name: controller.text,
                          iconName: selectedIconName,
                        );
                      } else {
                        await repo.updateCategory(
                          category: category,
                          name: controller.text,
                          iconName: selectedIconName,
                        );
                      }

                      ref.invalidate(categoriesProvider);
                      ref.invalidate(groupedItemsProvider);

                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    } catch (error) {
                      if (!dialogContext.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            error.toString().replaceFirst('Exception: ', ''),
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteCategory(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Kategori Sil'),
          content: Text(
            '"${category.name}" kategorisini silmek istediğine emin misin?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Vazgeç'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ref.read(categoryRepositoryProvider).deleteCategory(category);

      ref.invalidate(categoriesProvider);
      ref.invalidate(groupedItemsProvider);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kategori silindi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5FA),
      appBar: AppBar(
        title: const Text('Kategorileri Yönet'),
        backgroundColor: const Color(0xFFFFF5FA),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFD96BA7),
        foregroundColor: Colors.white,
        onPressed: () => _showCategoryDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Kategori Ekle'),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Kategoriler yüklenemedi: $error')),
        data: (categories) {
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final category = categories[index];

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFFFFD6EA)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD96BA7).withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD6EA), Color(0xFFFFEEF7)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      _categoryIcon(category.iconName),
                      color: const Color(0xFFD96BA7),
                      size: 28,
                    ),
                  ),
                  title: Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2C1E26),
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _categoryDescription(category.iconName),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9A7A89),
                      ),
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showCategoryDialog(context, ref, category: category);
                      }

                      if (value == 'delete') {
                        _deleteCategory(context, ref, category);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                      PopupMenuItem(value: 'delete', child: Text('Sil')),
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
