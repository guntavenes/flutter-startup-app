import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_startup_app/core/database/app_database.dart';
import 'package:flutter_startup_app/features/items/data/item_providers.dart';
import 'package:flutter_startup_app/features/items/data/item_repository_provider.dart';

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
        categoryId: 1,
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
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5FA),
      appBar: AppBar(title: const Text('Ürün Ekle')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Ürün adı',
                  icon: Icons.shopping_bag_outlined,
                  isRequired: true,
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
                SwitchListTile(
                  value: _isPurchased,
                  onChanged: (value) {
                    setState(() {
                      _isPurchased = value;
                    });
                  },
                  title: const Text('Alındı olarak işaretle'),
                  activeColor: const Color(0xFFD96BA7),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _saveItem,
                    child: const Text('Kaydet'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
