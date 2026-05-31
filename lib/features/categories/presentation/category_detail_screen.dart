import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_startup_app/core/database/app_database.dart';
import 'package:flutter_startup_app/core/extensions/currency_extensions.dart';
import 'package:flutter_startup_app/core/formatters/turkish_currency_input_formatter.dart';
import 'package:flutter_startup_app/features/brands/data/brand_options.dart';
import 'package:flutter_startup_app/features/items/data/item_providers.dart';
import 'package:flutter_startup_app/features/items/data/item_repository_provider.dart';
import 'package:flutter_startup_app/features/items/presentation/item_form_screen.dart';

class CategoryDetailScreen extends ConsumerStatefulWidget {
  const CategoryDetailScreen({
    super.key,
    required this.category,
    required this.items,
    required this.filter,
  });

  final Category category;
  final List<Item> items;
  final ItemFilter filter;

  @override
  ConsumerState<CategoryDetailScreen> createState() =>
      _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  final TextEditingController _searchController = TextEditingController();

  late List<Item> _categoryItems;
  String _searchText = '';
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _categoryItems = widget.items;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reloadCategoryItemsFromDb() async {
    final repo = ref.read(itemRepositoryProvider);
    final allItems = await repo.getAllItems();

    final refreshedItems = allItems.where((item) {
      if (item.categoryId != widget.category.id) {
        return false;
      }

      switch (widget.filter) {
        case ItemFilter.remaining:
          return !item.isPurchased;
        case ItemFilter.purchased:
          return item.isPurchased;
        case ItemFilter.all:
          return true;
      }
    }).toList();

    if (!mounted) return;

    setState(() {
      _categoryItems = refreshedItems;
      _hasChanges = true;
    });

    ref.invalidate(allItemsProvider);
    ref.invalidate(groupedItemsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _categoryItems.where((item) {
      final query = _searchText.toLowerCase();

      return item.name.toLowerCase().contains(query) ||
          (item.brand?.toLowerCase().contains(query) ?? false) ||
          (item.model?.toLowerCase().contains(query) ?? false);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5FA),
      appBar: AppBar(
        title: Text(widget.category.name),
        backgroundColor: const Color(0xFFFFF5FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(_hasChanges);
          },
        ),
      ),
      body: _buildBody(filteredItems, _categoryItems),
    );
  }

  Widget _buildBody(List<Item> filteredItems, List<Item> categoryItems) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF5FA), Color(0xFFFFF7F0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildSummaryHeader(categoryItems),
            _buildSearchBar(),
            const SizedBox(height: 10),
            Expanded(
              child: filteredItems.isEmpty
                  ? const Center(
                      child: Text(
                        'Ürün bulunamadı',
                        style: TextStyle(
                          color: Color(0xFF8A6B79),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 90),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];

                        return GestureDetector(
                          onTap: () async {
                            final result = await Navigator.of(context)
                                .push<bool>(
                                  MaterialPageRoute(
                                    builder: (_) => ItemFormScreen(item: item),
                                  ),
                                );

                            if (result == true) {
                              await _reloadCategoryItemsFromDb();
                            }
                          },
                          child: _buildItemCard(item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePurchaseAction(Item item) async {
    final repo = ref.read(itemRepositoryProvider);

    if (item.isPurchased) {
      final shouldMarkAsNotPurchased = await _confirmMarkAsNotPurchased();

      if (shouldMarkAsNotPurchased == true) {
        await repo.markAsNotPurchased(item);
        await _reloadCategoryItemsFromDb();
      }

      return;
    }

    final purchaseInfo = await _showPurchaseInfoDialog(item);

    if (purchaseInfo == null) return;

    await repo.markAsPurchased(
      item: item,
      price: purchaseInfo.price,
      brand: purchaseInfo.brand,
      purchaseDate: purchaseInfo.purchaseDate,
    );

    await _reloadCategoryItemsFromDb();

    if (mounted) {
      await _showPurchasedSuccessDialog(item);
    }
  }

  Future<void> _showPurchasedSuccessDialog(Item item) async {
    final shouldUndo = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Ürün alındı'),
          content: Text('${item.name} alınanlar listesine taşındı.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Tamam'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text(
                'Geri Al',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );

    if (shouldUndo != true) {
      return;
    }

    final repo = ref.read(itemRepositoryProvider);

    await repo.undoPurchased(item);

    await _reloadCategoryItemsFromDb();
  }

  Future<void> _handleDeleteAction(Item item) async {
    final shouldDelete = await _confirmDeleteItem();

    if (shouldDelete != true) return;

    final repo = ref.read(itemRepositoryProvider);

    await repo.deleteItemById(item.id);
    await _reloadCategoryItemsFromDb();
  }

  Widget _buildSummaryHeader(List<Item> items) {
    final purchasedCount = items.where((e) => e.isPurchased).length;
    final remainingCount = items.length - purchasedCount;

    final totalExpense = items
        .where((e) => e.isPurchased)
        .fold<double>(0, (sum, item) => sum + (item.purchasedPrice ?? 0));

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8DBA), Color(0xFFD96BA7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.category.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${items.length} ürün • $purchasedCount alındı • $remainingCount kalan',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              totalExpense.toCurrency(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchText = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Ürün ara...',
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFFD96BA7),
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.92),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(Item item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: item.imagePath != null && item.imagePath!.isNotEmpty
                ? Image.file(
                    File(item.imagePath!),
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFC7E3), Color(0xFFFFEEF7)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: Color(0xFFD96BA7),
                      size: 22,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name.trim().isEmpty ? 'İsimsiz Ürün' : item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2C1E26),
                  ),
                ),

                if (_buildSubtitle(item).isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _buildSubtitle(item),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2EAD5B),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildPurchaseActionButton(item),
          const SizedBox(width: 6),
          _buildDeleteActionButton(item),
        ],
      ),
    );
  }

  Widget _buildPurchaseActionButton(Item item) {
    return GestureDetector(
      onTap: () {
        _handlePurchaseAction(item);
      },
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: item.isPurchased
              ? const Color(0xFFFFF3E0)
              : const Color(0xFFEAF8F0),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(
          item.isPurchased
              ? Icons.undo_rounded
              : Icons.check_circle_outline_rounded,
          color: item.isPurchased
              ? const Color(0xFFFF9800)
              : const Color(0xFF2EAD5B),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildDeleteActionButton(Item item) {
    return GestureDetector(
      onTap: () {
        _handleDeleteAction(item);
      },
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.redAccent,
          size: 20,
        ),
      ),
    );
  }

  Future<bool?> _confirmDeleteItem() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Ürünü sil'),
          content: const Text('Bu ürünü silmek istediğine emin misin?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Sil',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _confirmMarkAsNotPurchased() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Alınmadı yap'),
          content: const Text(
            'Bu ürünü alınmadı olarak işaretlemek istediğine emin misin?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Alınmadı Yap'),
            ),
          ],
        );
      },
    );
  }

  Future<PurchaseInfoResult?> _showPurchaseInfoDialog(Item item) async {
    final priceController = TextEditingController(
      text: item.purchasedPrice?.toString() ?? '',
    );

    final brandController = TextEditingController(text: item.brand ?? '');

    final brandOptions = BrandOptions.getBrands(widget.category.name);

    String? selectedBrand = brandOptions.contains(item.brand)
        ? item.brand
        : null;

    if (selectedBrand != BrandOptions.other) {
      brandController.clear();
    }

    DateTime selectedDate = DateTime.now();

    return showDialog<PurchaseInfoResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Satın Alma Bilgisi'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [TurkishCurrencyInputFormatter()],
                    decoration: const InputDecoration(labelText: 'Fiyat'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: selectedBrand,
                    hint: const Text('Marka seçiniz'),
                    decoration: const InputDecoration(labelText: 'Marka'),
                    items: brandOptions.map((brand) {
                      return DropdownMenuItem<String>(
                        value: brand,
                        child: Text(brand),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedBrand = value;

                        if (selectedBrand != BrandOptions.other) {
                          brandController.clear();
                        }
                      });
                    },
                  ),
                  if (selectedBrand == BrandOptions.other) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: brandController,
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: [
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          final formatted = _capitalizeWords(newValue.text);

                          return TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(
                              offset: formatted.length,
                            ),
                          );
                        }),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Diğer Marka',
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Alınma Tarihi'),
                    subtitle: Text(
                      '${selectedDate.day}.${selectedDate.month}.${selectedDate.year}',
                    ),
                    trailing: const Icon(Icons.calendar_month_outlined),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: dialogContext,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );

                      if (pickedDate == null) return;

                      setDialogState(() {
                        selectedDate = pickedDate;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Vazgeç'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final priceText = priceController.text
                        .trim()
                        .replaceAll('.', '')
                        .replaceAll(',', '.');

                    final price = double.tryParse(priceText) ?? 0;

                    Navigator.of(dialogContext).pop(
                      PurchaseInfoResult(
                        price: price,
                        brand: selectedBrand == BrandOptions.other
                            ? _formatBrand(brandController.text)
                            : selectedBrand,
                        purchaseDate: selectedDate.millisecondsSinceEpoch,
                      ),
                    );
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

  String _capitalizeWords(String value) {
    return value
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;

          final lower = word.toLowerCase();
          return lower[0].toUpperCase() + lower.substring(1);
        })
        .join(' ');
  }

  String? _formatBrand(String value) {
    final formatted = _capitalizeWords(value.trim());

    if (formatted.isEmpty) {
      return null;
    }

    return formatted;
  }

  String _buildSubtitle(Item item) {
    if (item.isPurchased) {
      final price = item.purchasedPrice ?? 0;

      return price.toCurrency();
    }
    return '';
  }
}

class PurchaseInfoResult {
  const PurchaseInfoResult({
    required this.price,
    required this.brand,
    required this.purchaseDate,
  });

  final double price;
  final String? brand;
  final int purchaseDate;
}
