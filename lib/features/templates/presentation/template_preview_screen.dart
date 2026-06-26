import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ceyizim_plus/core/database/app_database.dart';
import 'package:ceyizim_plus/features/categories/data/category_providers.dart';
import 'package:ceyizim_plus/features/items/data/item_providers.dart';
import 'package:ceyizim_plus/features/items/data/item_repository_provider.dart';
import 'package:ceyizim_plus/features/templates/data/template_providers.dart';

import '../domain/template_item.dart';

class TemplatePreviewScreen extends ConsumerStatefulWidget {
  const TemplatePreviewScreen({super.key, required this.title});

  final String title;

  @override
  ConsumerState<TemplatePreviewScreen> createState() =>
      _TemplatePreviewScreenState();
}

class _TemplatePreviewScreenState extends ConsumerState<TemplatePreviewScreen> {
  Set<TemplateItem> _selectedItems = {};
  final Set<String> _collapsedCategoryNames = {};
  bool _initializedSelection = false;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _addSelectedItemsToList() async {
    if (_isAdding) return;

    setState(() {
      _isAdding = true;
    });

    try {
      if (_selectedItems.isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listeye eklemek için en az bir ürün seçmelisin.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final categoryRepository = ref.read(categoryRepositoryProvider);
      final itemRepository = ref.read(itemRepositoryProvider);

      await categoryRepository.insertDefaultCategories();

      final categories = await categoryRepository.getAll();
      final existingItems = await itemRepository.getAllItems();
      final now = DateTime.now().millisecondsSinceEpoch;

      final itemsToInsert = <ItemsCompanion>[];

      int addedCount = 0;
      int skippedCount = 0;

      for (final templateItem in _selectedItems) {
        final category = categories.firstWhere(
          (category) => category.name == templateItem.categoryName,
          orElse: () {
            throw Exception(
              'Kategori bulunamadı: ${templateItem.categoryName}',
            );
          },
        );

        final alreadyExists = existingItems.any((item) {
          return item.categoryId == category.id &&
              item.name.trim().toLowerCase() ==
                  templateItem.name.trim().toLowerCase();
        });

        if (alreadyExists) {
          skippedCount++;
          continue;
        }

        itemsToInsert.add(
          ItemsCompanion.insert(
            categoryId: category.id,
            name: templateItem.name,
            createdAt: now,
            updateAt: now,
          ),
        );

        addedCount++;
      }

      if (itemsToInsert.isNotEmpty) {
        await itemRepository.addItemsToLocalOnly(itemsToInsert);
        unawaited(itemRepository.syncAllItemsToFirestore());
      }

      ref.invalidate(allItemsProvider);
      ref.invalidate(groupedItemsProvider);

      if (!mounted) return;

      Navigator.of(
        context,
      ).pop({'addedCount': addedCount, 'skippedCount': skippedCount});
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final templateItemsAsync = ref.watch(standardTemplateItemsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5FA),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFFFFF5FA),
        elevation: 0,
      ),
      body: templateItemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Şablon yüklenemedi: $error',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8A6B79),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        data: (items) {
          if (!_initializedSelection) {
            _selectedItems = items.toSet();
            _collapsedCategoryNames.addAll(
              items.map((item) => item.categoryName).toSet(),
            );
            _initializedSelection = true;
          }

          final groupedItems = <String, List<TemplateItem>>{};

          for (final item in items) {
            groupedItems.putIfAbsent(item.categoryName, () => []);
            groupedItems[item.categoryName]!.add(item);
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
                  children: groupedItems.entries.map((entry) {
                    return _buildCategorySection(entry.key, entry.value);
                  }).toList(),
                ),
              ),
              _buildBottomButton(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategorySection(String categoryName, List<TemplateItem> items) {
    final isCollapsed = _collapsedCategoryNames.contains(categoryName);

    final selectedCount = items.where((item) {
      return _selectedItems.contains(item);
    }).length;

    final allSelected = selectedCount == items.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD6EA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD96BA7).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                if (isCollapsed) {
                  _collapsedCategoryNames.remove(categoryName);
                } else {
                  _collapsedCategoryNames.add(categoryName);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (allSelected) {
                          _selectedItems.removeAll(items);
                        } else {
                          _selectedItems.addAll(items);
                        }
                      });
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: allSelected
                            ? const Color(0xFFD96BA7)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFD96BA7),
                          width: 2,
                        ),
                      ),
                      child: allSelected
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 18,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2C1E26),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$selectedCount/${items.length} seçili',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF8A6B79),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isCollapsed ? -0.25 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF8A6B79),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isCollapsed) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(children: items.map(_buildItemTile).toList()),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemTile(TemplateItem item) {
    final isSelected = _selectedItems.contains(item);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedItems.remove(item);
          } else {
            _selectedItems.add(item);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF0F7) : const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFFD96BA7) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              color: isSelected
                  ? const Color(0xFFD96BA7)
                  : const Color(0xFFBDBDBD),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C1E26),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
      color: const Color(0xFFFFF5FA),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: _isAdding ? null : _addSelectedItemsToList,
          icon: _isAdding
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.add_task_rounded),
          label: Text(
            _isAdding
                ? 'Listeye ekleniyor...'
                : 'Listeme Ekle (${_selectedItems.length})',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD96BA7),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
