import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_startup_app/core/database/app_database.dart';
import 'package:flutter_startup_app/features/items/data/item_providers.dart';
import 'package:flutter_startup_app/features/items/data/item_repository_provider.dart';
import 'package:flutter_startup_app/features/categories/data/category_providers.dart';

class ItemFormScreen extends ConsumerStatefulWidget {
  const ItemFormScreen({super.key});

  @override
  ConsumerState<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends ConsumerState<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _priceController = TextEditingController();
  final _linkController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isPurchased = false;
  int? _selectedCategoryId;

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _priceController.dispose();
    _linkController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final repository = ref.read(itemRepositoryProvider);
    final now = DateTime.now().millisecondsSinceEpoch;

    final priceText = _priceController.text.trim().replaceAll(',', '.');
    final price = double.tryParse(priceText);

    await repository.addItem(
      ItemsCompanion.insert(
        categoryId: _selectedCategoryId!,
        name: _nameController.text.trim(),
        brand: Value(_emptyToNull(_brandController.text)),
        model: Value(_emptyToNull(_modelController.text)),
        purchasedPrice: Value(price),
        link: Value(_emptyToNull(_linkController.text)),
        note: Value(_emptyToNull(_noteController.text)),
        isPurchased: Value(_isPurchased),
        purchaseDate: _isPurchased ? Value(now) : const Value.absent(),
        createdAt: now,
        updateAt: now,
      ),
    );

    ref.invalidate(allItemsProvider);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String? _emptyToNull(String value) {
    final trimmedValue = value.trim();
    return trimmedValue.isEmpty ? null : trimmedValue;
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Ürün Ekle'),
        backgroundColor: Colors.transparent,
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildFormHeader(),

                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _nameController,
                    label: 'Ürün adı',
                    icon: Icons.shopping_bag_outlined,
                    isRequired: true,
                  ),

                  const SizedBox(height: 14),
                  categoriesAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Text('Kategori yüklenemedi: $error'),
                    data: (categories) {
                      return _buildCategoryDropdown(categories);
                    },
                  ),

                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _brandController,
                    label: 'Marka',
                    icon: Icons.sell_outlined,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _modelController,
                    label: 'Model',
                    icon: Icons.category_outlined,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _priceController,
                    label: 'Fiyat',
                    icon: Icons.payments_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _linkController,
                    label: 'Link',
                    icon: Icons.link,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _noteController,
                    label: 'Not',
                    icon: Icons.notes_outlined,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _buildPurchasedSwitch(),
                  const SizedBox(height: 24),
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(List<Category> categories) {
    return DropdownButtonFormField<int>(
      value: _selectedCategoryId,
      validator: (value) {
        if (value == null) {
          return 'Kategori seçmelisin';
        }

        return null;
      },
      decoration: InputDecoration(
        labelText: 'Kategori',
        prefixIcon: const Icon(
          Icons.category_outlined,
          color: Color(0xFFD96BA7),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.92),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFD96BA7), width: 1.4),
        ),
      ),
      items: categories.map((category) {
        return DropdownMenuItem<int>(
          value: category.id,
          child: Text(category.name),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategoryId = value;
        });
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: isRequired
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label zorunlu';
              }

              return null;
            }
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFD96BA7)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.92),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFD96BA7), width: 1.4),
        ),
      ),
    );
  }

  Widget _buildPurchasedSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD96BA7).withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _isPurchased,
        onChanged: (value) {
          setState(() {
            _isPurchased = value;
          });
        },
        title: const Text(
          'Alındı olarak işaretle',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C1E26),
          ),
        ),
        subtitle: const Text(
          'Bu ürün toplam harcamaya dahil edilir.',
          style: TextStyle(color: Color(0xFF8A6B79)),
        ),
        activeColor: const Color(0xFFD96BA7),
      ),
    );
  }

  Widget _buildFormHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8DBA), Color(0xFFD96BA7), Color(0xFFFFB6D5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD96BA7).withValues(alpha: 0.25),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.add_shopping_cart_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yeni Ürün',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Çeyiz listene yeni bir ihtiyaç veya alınan ürün ekle.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _saveItem,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD96BA7),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child: const Text(
          'Kaydet',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
