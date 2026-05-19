import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_startup_app/core/database/app_database.dart';
import 'package:flutter_startup_app/core/extensions/currency_extensions.dart';
import 'package:flutter_startup_app/features/expenses/domain/expense_sort_type.dart';
import 'package:flutter_startup_app/features/items/presentation/item_form_screen.dart';

class ExpenseDetailScreen extends StatefulWidget {
  const ExpenseDetailScreen({super.key, required this.items});

  final List<Item> items;

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  ExpenseSortType _sortType = ExpenseSortType.dateDesc;

  @override
  Widget build(BuildContext context) {
    final purchasedItems = widget.items
        .where((item) => item.isPurchased)
        .toList();

    final sortedItems = _sortItems(purchasedItems);

    final totalExpense = purchasedItems.fold<double>(
      0,
      (sum, item) => sum + (item.purchasedPrice ?? 0),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5FA),
      appBar: AppBar(
        title: const Text('Harcama Detayı'),
        backgroundColor: const Color(0xFFFFF5FA),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF5FA), Color(0xFFFFF7F0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            _buildHeader(totalExpense, purchasedItems.length),
            _buildSortBar(),
            Expanded(
              child: sortedItems.isEmpty
                  ? const Center(
                      child: Text(
                        'Henüz alınan ürün yok',
                        style: TextStyle(
                          color: Color(0xFF8A6B79),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 100),
                      itemCount: sortedItems.length,
                      itemBuilder: (context, index) {
                        final item = sortedItems[index];

                        return GestureDetector(
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ItemFormScreen(item: item),
                              ),
                            );
                          },
                          child: _buildExpenseCard(item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Item> _sortItems(List<Item> items) {
    final sortedItems = [...items];

    switch (_sortType) {
      case ExpenseSortType.dateDesc:
        sortedItems.sort((a, b) => b.updateAt.compareTo(a.updateAt));
        break;
      case ExpenseSortType.dateAsc:
        sortedItems.sort((a, b) => a.updateAt.compareTo(b.updateAt));
        break;
      case ExpenseSortType.priceDesc:
        sortedItems.sort(
          (a, b) => (b.purchasedPrice ?? 0).compareTo(a.purchasedPrice ?? 0),
        );
        break;
      case ExpenseSortType.priceAsc:
        sortedItems.sort(
          (a, b) => (a.purchasedPrice ?? 0).compareTo(b.purchasedPrice ?? 0),
        );
        break;
    }

    return sortedItems;
  }

  Widget _buildHeader(double totalExpense, int itemCount) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD96BA7), Color(0xFFFF8DBA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD96BA7).withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.payments_outlined, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Toplam Harcama',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalExpense.toCurrency(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$itemCount alınan ürün',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: DropdownButtonFormField<ExpenseSortType>(
        value: _sortType,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelText: 'Sıralama',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
        ),
        items: const [
          DropdownMenuItem(
            value: ExpenseSortType.dateDesc,
            child: Text('En Yeni Ürünler'),
          ),
          DropdownMenuItem(
            value: ExpenseSortType.dateAsc,
            child: Text('En Eski Ürünler'),
          ),
          DropdownMenuItem(
            value: ExpenseSortType.priceDesc,
            child: Text('En Yüksek Fiyat'),
          ),
          DropdownMenuItem(
            value: ExpenseSortType.priceAsc,
            child: Text('En Düşük Fiyat'),
          ),
        ],
        onChanged: (value) {
          if (value == null) return;

          setState(() {
            _sortType = value;
          });
        },
      ),
    );
  }

  Widget _buildExpenseCard(Item item) {
    final price = item.purchasedPrice ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD6EA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD96BA7).withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
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
            child: Text(
              item.name.trim().isEmpty ? 'İsimsiz Ürün' : item.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2C1E26),
              ),
            ),
          ),
          Text(
            price.toCurrency(),
            style: const TextStyle(
              color: Color(0xFFD96BA7),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
