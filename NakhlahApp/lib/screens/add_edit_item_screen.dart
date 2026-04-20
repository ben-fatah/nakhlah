import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../models/market_item.dart';
import '../models/seller_profile.dart';
import '../providers/locale_provider.dart';
import '../repositories/item_repository.dart';
import '../theme/app_colors.dart';

/// Screen to add a new item or edit an existing one.
///
/// Pass [item] to enter edit mode; omit for add mode.
/// Pass [seller] when adding so we can denormalize shop name + avatar.
class AddEditItemScreen extends StatefulWidget {
  final MarketItem? item; // null → add mode
  final SellerProfile? seller; // required in add mode

  const AddEditItemScreen({super.key, this.item, this.seller});

  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  File? _imageFile;
  String _selectedVariety = '';
  bool _negotiable = false; // true = price null
  bool _isLoading = false;

  final _picker = ImagePicker();
  final _repo = ItemRepository.instance;

  bool get _isEdit => widget.item != null;

  static const _varieties = [
    '', 'ajwa', 'medjool', 'sukkari', 'khalas', 'barhi', 'sagai',
  ];

  static const _varietyLabels = {
    '': {'en': 'Other / All', 'ar': 'أخرى'},
    'ajwa': {'en': 'Ajwa', 'ar': 'عجوة'},
    'medjool': {'en': 'Medjool', 'ar': 'مجهول'},
    'sukkari': {'en': 'Sukkari', 'ar': 'سكري'},
    'khalas': {'en': 'Khalas', 'ar': 'خلاص'},
    'barhi': {'en': 'Barhi', 'ar': 'برحي'},
    'sagai': {'en': 'Sagai', 'ar': 'صقعي'},
  };

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final item = widget.item!;
      _titleCtrl.text = item.title;
      _descCtrl.text = item.description;
      _selectedVariety = item.variety;
      _negotiable = item.price == null;
      if (item.price != null) {
        _priceCtrl.text = item.price!.toStringAsFixed(0);
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  // ── Image pick ────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (picked == null) return;
    setState(() => _imageFile = File(picked.path));
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEdit && _imageFile == null) {
      _showSnackBar(
        localeProvider.isArabic
            ? 'يرجى اختيار صورة للمنتج'
            : 'Please add an image for this item',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final priceVal =
          _negotiable ? null : double.tryParse(_priceCtrl.text.trim());

      if (_isEdit) {
        final updated = widget.item!.copyWith(
          title: _titleCtrl.text,
          description: _descCtrl.text,
          price: priceVal,
          clearPrice: _negotiable,
          variety: _selectedVariety,
        );
        await _repo.updateItem(item: updated, newImageFile: _imageFile);
      } else {
        await _repo.addItem(
          sellerName: widget.seller!.displayName,
          sellerAvatarUrl: widget.seller!.avatarUrl,
          title: _titleCtrl.text,
          description: _descCtrl.text,
          price: priceVal,
          imageFile: _imageFile!,
          variety: _selectedVariety,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true); // signal success to caller
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        localeProvider.isArabic
            ? 'فشل الحفظ. حاول مجدداً.'
            : 'Failed to save. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.cairo()),
        backgroundColor: isError ? Colors.red.shade700 : AppColors.brown700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Delete (edit mode only) ───────────────────────────────────────────────

  Future<void> _confirmDelete() async {
    final isAr = localeProvider.isArabic;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          isAr ? 'حذف المنتج؟' : 'Delete item?',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        content: Text(
          isAr
              ? 'لن يظهر هذا المنتج في السوق بعد الآن.'
              : 'This item will no longer appear in the market.',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isAr ? 'إلغاء' : 'Cancel', style: GoogleFonts.cairo()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              isAr ? 'حذف' : 'Delete',
              style: GoogleFonts.cairo(color: Colors.red.shade600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _repo.deleteItem(widget.item!.id);
    if (mounted) Navigator.of(context).pop('deleted');
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isAr = localeProvider.isArabic;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.offWhite,
        appBar: AppBar(
          backgroundColor: AppColors.brown900,
          foregroundColor: Colors.white,
          title: Text(
            _isEdit
                ? (isAr ? 'تعديل المنتج' : 'Edit Item')
                : (isAr ? 'إضافة منتج' : 'Add Item'),
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
          ),
          actions: [
            if (_isEdit)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                color: Colors.red.shade300,
                tooltip: isAr ? 'حذف' : 'Delete',
                onPressed: _confirmDelete,
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Image picker ──────────────────────────────────────────
                _ImagePickerCard(
                  imageFile: _imageFile,
                  existingUrl: _isEdit ? widget.item!.imageUrl : null,
                  onTap: _pickImage,
                  isAr: isAr,
                ),
                const SizedBox(height: 24),

                // ── Title ─────────────────────────────────────────────────
                _buildLabel(isAr ? 'عنوان المنتج' : 'Item Title'),
                const SizedBox(height: 8),
                _buildField(
                  controller: _titleCtrl,
                  hint: isAr ? 'تمر عجوة مدينة منورة 1 كيلو' : 'Ajwa dates 1 kg box',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? (isAr ? 'يرجى إدخال عنوان' : 'Title is required')
                          : null,
                ),
                const SizedBox(height: 20),

                // ── Variety ───────────────────────────────────────────────
                _buildLabel(isAr ? 'نوع التمر' : 'Variety'),
                const SizedBox(height: 8),
                _VarietySelector(
                  varieties: _varieties,
                  labels: _varietyLabels,
                  selected: _selectedVariety,
                  isAr: isAr,
                  onChanged: (v) => setState(() => _selectedVariety = v),
                ),
                const SizedBox(height: 20),

                // ── Description ───────────────────────────────────────────
                _buildLabel(isAr ? 'وصف المنتج' : 'Description'),
                const SizedBox(height: 8),
                _buildField(
                  controller: _descCtrl,
                  hint: isAr
                      ? 'اذكر الوزن، حالة التمر، طريقة التوصيل...'
                      : 'Weight, condition, delivery method...',
                  maxLines: 4,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? (isAr ? 'يرجى إدخال وصف' : 'Description is required')
                          : null,
                ),
                const SizedBox(height: 20),

                // ── Price ─────────────────────────────────────────────────
                _buildLabel(isAr ? 'السعر (ر.س)' : 'Price (SAR)'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        controller: _priceCtrl,
                        hint: isAr ? 'مثال: 150' : 'e.g. 150',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        enabled: !_negotiable,
                        validator: (v) {
                          if (_negotiable) return null;
                          if (v == null || v.trim().isEmpty) {
                            return isAr
                                ? 'أدخل السعر أو اختر التفاوض'
                                : 'Enter price or choose negotiate';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _negotiable = !_negotiable;
                          if (_negotiable) _priceCtrl.clear();
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: _negotiable
                              ? AppColors.brown700
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _negotiable
                                ? AppColors.brown700
                                : AppColors.fieldBorder,
                          ),
                        ),
                        child: Text(
                          isAr ? 'تفاوض' : 'Negotiate',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _negotiable ? Colors.white : AppColors.brown700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ── Submit ────────────────────────────────────────────────
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brown700,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.brown700.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            _isEdit
                                ? (isAr ? 'حفظ التعديلات' : 'Save Changes')
                                : (isAr ? 'نشر المنتج' : 'Publish Item'),
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.brown700,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      enabled: enabled,
      style: GoogleFonts.cairo(fontSize: 14, color: AppColors.brown900),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: enabled ? AppColors.fieldBg : AppColors.brown100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.brown700, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.fieldBorder.withValues(alpha: 0.5)),
        ),
        hintStyle: GoogleFonts.cairo(color: AppColors.hintColor, fontSize: 13),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ── Image Picker Card ──────────────────────────────────────────────────────────

class _ImagePickerCard extends StatelessWidget {
  final File? imageFile;
  final String? existingUrl;
  final VoidCallback onTap;
  final bool isAr;

  const _ImagePickerCard({
    required this.imageFile,
    this.existingUrl,
    required this.onTap,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (imageFile != null) {
      imageWidget = Image.file(imageFile!, fit: BoxFit.cover);
    } else if (existingUrl != null && existingUrl!.isNotEmpty) {
      imageWidget = Image.network(
        existingUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    } else {
      imageWidget = _placeholder();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.brown100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.fieldBorder,
            style: (imageFile == null && (existingUrl == null || existingUrl!.isEmpty))
                ? BorderStyle.solid
                : BorderStyle.solid,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageWidget,
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isAr ? 'اختر صورة' : 'Choose photo',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined,
            size: 48, color: AppColors.brown700.withValues(alpha: 0.4)),
        const SizedBox(height: 8),
        Text(
          isAr ? 'اضغط لإضافة صورة*' : 'Tap to add image*',
          style: GoogleFonts.cairo(
            color: AppColors.brown700.withValues(alpha: 0.5),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

// ── Variety Selector ──────────────────────────────────────────────────────────

class _VarietySelector extends StatelessWidget {
  final List<String> varieties;
  final Map<String, Map<String, String>> labels;
  final String selected;
  final bool isAr;
  final ValueChanged<String> onChanged;

  const _VarietySelector({
    required this.varieties,
    required this.labels,
    required this.selected,
    required this.isAr,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: varieties.map((v) {
        final isActive = selected == v;
        return GestureDetector(
          onTap: () => onChanged(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? AppColors.brown700 : Colors.white,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: isActive ? AppColors.brown700 : AppColors.fieldBorder,
              ),
            ),
            child: Text(
              labels[v]?[isAr ? 'ar' : 'en'] ?? v,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : AppColors.brown700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
