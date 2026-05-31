import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_startup_app/core/database/app_database.dart';
import 'package:flutter_startup_app/features/categories/data/category_providers.dart';
import 'package:flutter_startup_app/features/items/data/item_providers.dart';
import 'package:flutter_startup_app/features/items/data/item_repository_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_startup_app/features/brands/data/brand_options.dart';
import 'package:flutter_startup_app/core/formatters/turkish_currency_input_formatter.dart';
import 'package:image_cropper/image_cropper.dart';

class ItemFormScreen extends ConsumerStatefulWidget {
  const ItemFormScreen({super.key, this.item});

  final Item? item;

  @override
  ConsumerState<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends ConsumerState<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();

  bool get _isEditMode => widget.item != null;

  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _priceController = TextEditingController();
  final _linkController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isPurchased = false;
  int? _selectedCategoryId;
  String? _selectedImagePath;
  DateTime? _purchaseDate;
  DateTime? _estimatedPurchaseDate;
  String? _selectedBrand;
  static const double _imageAspectRatio = 1.6;
  static const double _maxImagePickerWidth = 300;
  static const double _maxImagePickerHeight = 210;

  @override
  void initState() {
    super.initState();

    final item = widget.item;

    if (item == null) {
      return;
    }

    _nameController.text = item.name;
    _brandController.text = item.brand ?? '';
    _modelController.text = item.model ?? '';
    _priceController.text = item.purchasedPrice?.toString() ?? '';
    _linkController.text = item.link ?? '';
    _noteController.text = item.note ?? '';

    _isPurchased = item.isPurchased;
    _selectedCategoryId = item.categoryId;
    _selectedImagePath = item.imagePath;
    _selectedBrand = item.brand;

    if (item.purchaseDate != null) {
      _purchaseDate = DateTime.fromMillisecondsSinceEpoch(item.purchaseDate!);
    }

    if (item.estimatedPurchaseDate != null) {
      _estimatedPurchaseDate = DateTime.fromMillisecondsSinceEpoch(
        item.estimatedPurchaseDate!,
      );
    }
  }

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

    final itemName = _nameController.text.trim();

    if (itemName.isEmpty) {
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kategori seçmelisin.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final repository = ref.read(itemRepositoryProvider);
    final now = DateTime.now().millisecondsSinceEpoch;

    final priceText = _priceController.text
        .trim()
        .replaceAll('.', '')
        .replaceAll(',', '.');

    final price = double.tryParse(priceText);

    final purchaseDateValue = _isPurchased
        ? _purchaseDate?.millisecondsSinceEpoch
        : null;

    final estimatedPurchaseDateValue =
        _estimatedPurchaseDate?.millisecondsSinceEpoch;

    if (_isEditMode) {
      await repository.updateItemDetails(
        id: widget.item!.id,
        companion: ItemsCompanion(
          categoryId: Value(_selectedCategoryId!),
          name: Value(itemName),
          brand: Value(_getSelectedBrand()),
          model: Value(_emptyToNull(_modelController.text)),
          purchasedPrice: Value(price),
          link: Value(_emptyToNull(_linkController.text)),
          note: Value(_emptyToNull(_noteController.text)),
          imagePath: Value(_selectedImagePath),
          isPurchased: Value(_isPurchased),
          purchaseDate: Value(purchaseDateValue),
          estimatedPurchaseDate: Value(estimatedPurchaseDateValue),
          updateAt: Value(now),
        ),
      );
    } else {
      await repository.addItem(
        ItemsCompanion.insert(
          categoryId: _selectedCategoryId!,
          name: itemName,
          brand: Value(_getSelectedBrand()),
          model: Value(_emptyToNull(_modelController.text)),
          purchasedPrice: Value(price),
          link: Value(_emptyToNull(_linkController.text)),
          note: Value(_emptyToNull(_noteController.text)),
          imagePath: Value(_selectedImagePath),
          isPurchased: Value(_isPurchased),
          purchaseDate: Value(purchaseDateValue),
          estimatedPurchaseDate: Value(estimatedPurchaseDateValue),
          createdAt: now,
          updateAt: now,
        ),
      );
    }

    ref.invalidate(allItemsProvider);
    ref.invalidate(groupedItemsProvider);

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  String? _getSelectedBrand() {
    if (_selectedBrand == null) {
      return null;
    }

    if (_selectedBrand != BrandOptions.other) {
      return _selectedBrand;
    }

    return _emptyToNull(_brandController.text);
  }

  Future<void> _confirmDeleteItem() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Ürünü sil'),
          content: const Text('Bu ürünü silmek istediğine emin misin?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
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

    if (shouldDelete != true) {
      return;
    }

    final repository = ref.read(itemRepositoryProvider);

    await repository.deleteItemById(widget.item!.id);

    ref.invalidate(allItemsProvider);

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  String? _emptyToNull(String value) {
    final trimmedValue = value.trim();
    return trimmedValue.isEmpty ? null : trimmedValue;
  }

  Future<DateTime?> _pickDate(DateTime? initialDate) {
    return showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Tarih seç';
    }

    return '${date.day}.${date.month}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5FA),
      appBar: AppBar(
        title: Text(_isEditMode ? 'Ürün Düzenle' : 'Ürün Ekle'),
        backgroundColor: const Color(0xFFFFF5FA),
        elevation: 0,
        actions: _isEditMode
            ? [
                IconButton(
                  onPressed: _saveItem,
                  icon: const Icon(Icons.check_rounded),
                  tooltip: 'Güncelle',
                ),
                IconButton(
                  onPressed: _confirmDeleteItem,
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'Sil',
                ),
              ]
            : null,
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
                  _buildImagePicker(),
                  const SizedBox(height: 14),
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
                  categoriesAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (categories) {
                      return _buildBrandSelector(categories);
                    },
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _modelController,
                    label: 'Model',
                    icon: Icons.category_outlined,
                  ),
                  const SizedBox(height: 14),
                  _buildPurchasedSwitch(),

                  if (_isPurchased) ...[
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _priceController,
                      label: 'Fiyat',
                      icon: Icons.payments_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [TurkishCurrencyInputFormatter()],
                    ),
                    const SizedBox(height: 14),
                    _buildDatePickerTile(
                      title: 'Alınma Tarihi',
                      value: _purchaseDate,
                      icon: Icons.event_available_outlined,
                      onTap: () async {
                        final selectedDate = await _pickDate(_purchaseDate);

                        if (selectedDate == null) {
                          return;
                        }

                        setState(() {
                          _purchaseDate = selectedDate;
                        });
                      },
                    ),
                  ] else ...[
                    const SizedBox(height: 14),
                    _buildDatePickerTile(
                      title: 'Tahmini Alınma Tarihi',
                      value: _estimatedPurchaseDate,
                      icon: Icons.event_note_outlined,
                      onTap: () async {
                        final selectedDate = await _pickDate(
                          _estimatedPurchaseDate,
                        );

                        if (selectedDate == null) {
                          return;
                        }

                        setState(() {
                          _estimatedPurchaseDate = selectedDate;
                        });
                      },
                    ),
                  ],

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
                  if (!_isEditMode) ...[
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                  ],
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
          _selectedBrand = null;
          _brandController.clear();
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
    List<TextInputFormatter>? inputFormatters,
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
      inputFormatters: inputFormatters,
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

  Widget _buildBrandSelector(List<Category> categories) {
    final selectedCategory = categories
        .where((category) => category.id == _selectedCategoryId)
        .firstOrNull;

    final brandOptions = selectedCategory == null
        ? [BrandOptions.other]
        : BrandOptions.getBrands(selectedCategory.name);

    final dropdownValue = brandOptions.contains(_selectedBrand)
        ? _selectedBrand
        : null;

    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: dropdownValue,
          hint: const Text('Marka seçiniz'),
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.sell_outlined,
              color: Color(0xFFD96BA7),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.92),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
          ),
          items: brandOptions.map((brand) {
            return DropdownMenuItem<String>(value: brand, child: Text(brand));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedBrand = value;

              if (_selectedBrand != BrandOptions.other) {
                _brandController.clear();
              }
            });
          },
        ),
        if (_selectedBrand == BrandOptions.other) ...[
          const SizedBox(height: 14),
          _buildTextField(
            controller: _brandController,
            label: 'Diğer Marka',
            icon: Icons.edit_outlined,
          ),
        ],
      ],
    );
  }

  Widget _buildDatePickerTile({
    required String title,
    required DateTime? value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFD96BA7)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF8A6B79),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(value),
                    style: const TextStyle(
                      color: Color(0xFF2C1E26),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.calendar_month_outlined, color: Color(0xFF8A6B79)),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchasedSwitch() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          _buildPurchaseStatusChip(
            title: 'Planlanıyor',
            icon: Icons.event_note_outlined,
            isSelected: !_isPurchased,
            onTap: () {
              setState(() {
                _isPurchased = false;
                _purchaseDate = null;
              });
            },
          ),
          const SizedBox(width: 8),
          _buildPurchaseStatusChip(
            title: 'Alındı',
            icon: Icons.check_circle_outline_rounded,
            isSelected: _isPurchased,
            onTap: () {
              setState(() {
                _isPurchased = true;
                _purchaseDate ??= DateTime.now();
                _estimatedPurchaseDate = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseStatusChip({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFFD96BA7), Color(0xFFFF8DBA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : const Color(0xFFFFF7FB),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : const Color(0xFFD96BA7),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.white : const Color(0xFF6D4C5B),
                ),
              ),
            ],
          ),
        ),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditMode ? 'Ürünü Düzenle' : 'Yeni Ürün',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isEditMode
                      ? 'Ürün bilgilerini güncelle veya ürünü listenden kaldır.'
                      : 'Çeyiz listene yeni bir ihtiyaç veya alınan ürün ekle.',
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
        child: Text(
          _isEditMode ? 'Güncelle' : 'Kaydet',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();

    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1600,
      maxHeight: 1600,
    );

    if (pickedFile == null) {
      return;
    }

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 75,
      maxWidth: 800,
      maxHeight: 500,
      aspectRatio: CropAspectRatio(ratioX: _imageAspectRatio, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Fotoğrafı Ayarla',
          toolbarColor: const Color(0xFFD96BA7),
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: const Color(0xFFD96BA7),
          lockAspectRatio: true,
          cropFrameColor: const Color(0xFFD96BA7),
          cropGridColor: Colors.white,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: 'Fotoğrafı Ayarla',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          aspectRatioPickerButtonHidden: true,
        ),
      ],
    );

    if (croppedFile == null) {
      return;
    }

    setState(() {
      _selectedImagePath = croppedFile.path;
    });
  }

  Future<void> _showImageSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8C7D9),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: Color(0xFFD96BA7),
                  ),
                  title: const Text(
                    'Galeriden seç',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_camera_outlined,
                    color: Color(0xFFD96BA7),
                  ),
                  title: const Text(
                    'Kamera ile çek',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: _maxImagePickerWidth,
          maxHeight: _maxImagePickerHeight,
        ),
        child: GestureDetector(
          onTap: _showImageSourceSheet,
          child: AspectRatio(
            aspectRatio: _imageAspectRatio,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
              ),
              clipBehavior: Clip.antiAlias,
              child: _selectedImagePath == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          color: Color(0xFFD96BA7),
                          size: 34,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Fotoğraf ekle',
                          style: TextStyle(
                            color: Color(0xFF8A6B79),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                  : Image.file(
                      File(_selectedImagePath!),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      cacheWidth: 800,
                      cacheHeight: 500,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
