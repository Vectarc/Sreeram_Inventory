import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../app_colors.dart';
import '../widgets/theme_toggle.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/api_service.dart';
import '../widgets/searchable_dropdown.dart';
import '../widgets/app_notifications.dart';

class ProductPage extends StatefulWidget {
  final String branch;
  const ProductPage({super.key, required this.branch});
  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _vendors = [];
  bool _loading = true;
  String? _error;

  // ── Search & Filter ─────────────────────────────────────────
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _filterCategory = 'All';
  String _filterStatus = 'All'; // All, Active, Inactive
  String? _filterVendorId;

  // ── Bulk selection ───────────────────────────────────────────
  bool _bulkMode = false;
  final Set<String> _selectedIds = {};

  List<Map<String, dynamic>> get _filteredProducts {
    return _products.where((p) {
      final q = _searchQuery.toLowerCase();
      final matchSearch =
          q.isEmpty ||
          (p['name'] ?? '').toLowerCase().contains(q) ||
          (p['code'] ?? '').toLowerCase().contains(q) ||
          (p['brand'] ?? '').toLowerCase().contains(q);
      final matchCat =
          _filterCategory == 'All' || p['category'] == _filterCategory;
      final matchStatus =
          _filterStatus == 'All' ||
          (_filterStatus == 'Active' && (p['isActive'] ?? true)) ||
          (_filterStatus == 'Inactive' && !(p['isActive'] ?? true));
      final matchVendor =
          _filterVendorId == null ||
          (p['vendor'] is Map
              ? p['vendor']['_id'] == _filterVendorId
              : p['vendor'] == _filterVendorId);
      return matchSearch && matchCat && matchStatus && matchVendor;
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  final List<String> _categories = [
    'W/B',
    'SCREEN MAKING ACCESSORIES',
    'TPL',
    'PRINTING ADD ON',
    'PLASTISOL',
    'SILICONE',
    'NON PVC O/B',
    'O/B',
    'STICKER',
    'SPECIAL INKS',
  ];
  List<String> _units = [];

  @override
  void initState() {
    super.initState();
    _loadUnits();
    _loadProducts();
  }

  Future<void> _loadUnits() async {
    final result = await ApiService.getUnits();
    if (result['success'] == true) {
      if (mounted) {
        setState(() {
          _units = List<String>.from(
            (result['units'] as List).map((u) => u['name'] as String),
          );
        });
      }
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ApiService.getProducts(branch: widget.branch);
    final vendorRes = await ApiService.getVendors();
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _products = List<Map<String, dynamic>>.from(result['products'] ?? []);
      } else {
        _error = result['message'];
      }
      if (vendorRes['success'] == true) {
        _vendors = List<Map<String, dynamic>>.from(vendorRes['vendors'] ?? []);
      }
    });
  }

  void _showDialog({Map<String, dynamic>? existing}) {
    final isDark = context.read<ThemeProvider>().isDark;
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final codeCtrl = TextEditingController(text: existing?['code'] ?? '');
    final brandCtrl = TextEditingController(text: existing?['brand'] ?? '');
    String? unit = existing?['unit'];
    String? category = existing?['category'] ?? 'PLASTISOL';

    String? selectedVendorId;
    if (existing != null && existing['vendor'] != null) {
      selectedVendorId = existing['vendor'] is Map
          ? existing['vendor']['_id']
          : existing['vendor'];
    }
    XFile? pickedFile;
    Uint8List? webImageBytes;
    String? existingImagePath = existing?['imagePath'];
    bool imageRemoved = false;
    bool saving = false;

    // Helper: pick image with auto-compression to stay under 2MB
    Future<void> pickImage(StateSetter ss) async {
      final picker = ImagePicker();
      // Try with quality 85 first — covers most cases
      XFile? photo = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (photo != null) {
        Uint8List bytes = await photo.readAsBytes();
        // If still > 2MB, compress further
        if (bytes.lengthInBytes > 2 * 1024 * 1024) {
          photo = await picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 50,
            maxWidth: 800,
            maxHeight: 800,
          );
          if (photo != null) bytes = await photo.readAsBytes();
        }
        if (bytes.lengthInBytes > 2 * 1024 * 1024) {
          if (context.mounted) {
            AppNotifications.showError(context, 'Image is too large. Please choose a smaller image.');
          }
          return;
        }
        if (kIsWeb) {
          ss(() {
            webImageBytes = bytes;
            pickedFile = photo;
            imageRemoved = false;
          });
        } else {
          ss(() {
            pickedFile = photo;
            imageRemoved = false;
          });
        }
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          backgroundColor: AppColors.cardElevated(isDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: AppColors.gradWarm,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inventory_2,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                existing == null ? 'Add New Product' : 'Edit Product',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: AppColors.red,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _tf(
                  isDark,
                  codeCtrl,
                  'Product Code',
                  Icons.vpn_key_outlined,
                  AppColors.red,
                ),
                const SizedBox(height: 12),
                _tf(
                  isDark,
                  nameCtrl,
                  'Product Name',
                  Icons.label_outline,
                  AppColors.red,
                ),
                const SizedBox(height: 12),
                _tf(
                  isDark,
                  brandCtrl,
                  'Brand Name',
                  Icons.branding_watermark_outlined,
                  AppColors.red,
                ),
                const SizedBox(height: 12),
                SearchableDropdown<String?>(
                  label: 'Vendor',
                  value: selectedVendorId,
                  items: [null, ..._vendors.map((v) => v['_id'] as String)],
                  itemAsString: (id) {
                    if (id == null) return 'Select Vendor';
                    try {
                      return _vendors.firstWhere(
                            (v) => v['_id'] == id,
                          )['name'] ??
                          'Unknown';
                    } catch (_) {
                      return 'Unknown';
                    }
                  },
                  onChanged: (v) => ss(() => selectedVendorId = v),
                  isDark: isDark,
                  prefixIcon: Icons.business_outlined,
                ),
                const SizedBox(height: 12),
                SearchableDropdown<String?>(
                  label: 'Unit',
                  value: unit,
                  items: _units,
                  itemAsString: (v) => v ?? 'Select Unit',
                  onChanged: (v) async {
                    if (v != null && !_units.contains(v)) {
                      final res = await ApiService.addUnit(v);
                      if (res['success'] == true) {
                        await _loadUnits();
                        ss(() => unit = v);
                      } else {
                        if (mounted) {
                          AppNotifications.showError(context, res['message'] ?? 'Error');
                        }
                      }
                    } else {
                      ss(() => unit = v);
                    }
                  },
                  isDark: isDark,
                  allowCustom: true,
                  searchHintText: 'Enter new unit name...',
                  prefixIcon: Icons.straighten_outlined,
                  onDeleteItem: (u) async {
                    if (u == null) return false;
                    final res = await ApiService.deleteUnit(u);
                    if (res['success'] == true) {
                      await _loadUnits();
                      return true;
                    } else {
                      if (mounted) {
                        AppNotifications.showError(context, res['message'] ?? 'Error');
                      }
                      return false;
                    }
                  },
                ),
                const SizedBox(height: 12),
                SearchableDropdown<String?>(
                  label: 'Category',
                  value: category,
                  items: _categories,
                  itemAsString: (v) => v ?? 'Select Category',
                  onChanged: (v) => ss(() => category = v),
                  isDark: isDark,
                  prefixIcon: Icons.category_outlined,
                ),
                const SizedBox(height: 12),
                // Image upload section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => pickImage(ss),
                      child: Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.red, width: 2),
                          borderRadius: BorderRadius.circular(10),
                          color: AppColors.red.withOpacity(0.05),
                        ),
                        child: imageRemoved
                            ? _imagePlaceholder(isDark)
                            : kIsWeb
                            ? (webImageBytes != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        webImageBytes!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : _imagePlaceholder(isDark))
                            : (pickedFile != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        File(pickedFile!.path),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : (existing?['imageUrl'] != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: ApiService.getFullImageUrl(existing!['imageUrl']) != null
                                                ? Image.network(
                                                    ApiService.getFullImageUrl(existing['imageUrl'])!,
                                                    fit: BoxFit.cover,
                                                  )
                                                : _imagePlaceholder(isDark),
                                          )
                                        : _imagePlaceholder(isDark))),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Max size: 2 MB · JPG, PNG',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppColors.textMuted(isDark),
                            ),
                          ),
                        ),
                        if (!imageRemoved &&
                            (webImageBytes != null ||
                                pickedFile != null ||
                                existing?['imageUrl'] != null))
                          GestureDetector(
                            onTap: () => ss(() {
                              pickedFile = null;
                              webImageBytes = null;
                              imageRemoved = true;
                              existingImagePath = null;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Remove Image',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            const ThemeToggleButton(),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary(isDark),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.gradWarm,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (codeCtrl.text.trim().isEmpty ||
                            nameCtrl.text.trim().isEmpty) {
                          AppNotifications.showWarning(context, 'Please fill required fields');
                          return;
                        }
                        ss(() => saving = true);
                        Map<String, dynamic> result;
                        if (existing == null) {
                          result = await ApiService.createProduct({
                            'name': nameCtrl.text.trim(),
                            'code': codeCtrl.text.trim(),
                            'unit': unit,
                            'category': category,
                            'brand': brandCtrl.text.trim(),
                            'vendor': selectedVendorId,
                            'image': imageRemoved
                                ? null
                                : (pickedFile?.path ?? existingImagePath),
                            'webImageBytes': imageRemoved
                                ? null
                                : webImageBytes,
                            'removeImage': imageRemoved,
                            'branch': widget.branch,
                          });
                        } else {
                          result =
                              await ApiService.updateProduct(existing['_id'], {
                                'name': nameCtrl.text.trim(),
                                'code': codeCtrl.text.trim(),
                                'brand': brandCtrl.text.trim(),
                                'unit': unit,
                                'category': category,
                                'vendor': selectedVendorId,
                                'image': imageRemoved
                                    ? null
                                    : (pickedFile?.path ?? existingImagePath),
                                'webImageBytes': imageRemoved
                                    ? null
                                    : webImageBytes,
                                'removeImage': imageRemoved,
                                'branch': widget.branch,
                              });
                        }
                        ss(() => saving = false);
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (result['success'] == true) {
                          _loadProducts();
                          AppNotifications.showSuccess(context, 'Product ${existing == null ? 'added' : 'updated'}!');
                        } else {
                          AppNotifications.showError(context, result['message'] ?? 'Error');
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        existing == null ? 'Add' : 'Update',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder(bool isDark) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(
        Icons.image_outlined,
        size: 40,
        color: AppColors.red.withOpacity(0.5),
      ),
      const SizedBox(height: 8),
      Text(
        'Tap to select product image',
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: AppColors.textSecondary(isDark),
        ),
      ),
    ],
  );

  // ── Quick image upload when clicking empty image area ───────────
  Future<void> _showQuickImageUpload(
    BuildContext context,
    bool isDark,
    Map<String, dynamic> product,
  ) async {
    XFile? pickedFile;
    Uint8List? webImageBytes;
    bool uploading = false;
    bool imageRemoved = false;
    final bool hasExistingImage = product['imageUrl'] != null;

    Future<void> pickImage(StateSetter ss) async {
      final picker = ImagePicker();
      XFile? photo = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (photo != null) {
        Uint8List bytes = await photo.readAsBytes();
        if (bytes.lengthInBytes > 2 * 1024 * 1024) {
          photo = await picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 50,
            maxWidth: 800,
            maxHeight: 800,
          );
          if (photo != null) bytes = await photo.readAsBytes();
        }
        if (bytes.lengthInBytes > 2 * 1024 * 1024) {
          if (context.mounted) {
            AppNotifications.showError(context, 'Image is too large. Please choose a smaller image.');
          }
          return;
        }
        if (kIsWeb) {
          ss(() {
            webImageBytes = bytes;
            pickedFile = photo;
            imageRemoved = false;
          });
        } else {
          ss(() {
            pickedFile = photo;
            imageRemoved = false;
          });
        }
      }
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          backgroundColor: AppColors.cardElevated(isDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: AppColors.gradWarm,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.add_a_photo,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  hasExistingImage
                      ? 'Manage Product Image'
                      : 'Upload Product Image',
                  style: GoogleFonts.poppins(
                    color: AppColors.textPrimary(isDark),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                product['name'] ?? '',
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary(isDark),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => pickImage(ss),
                child: Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.red, width: 2),
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.red.withOpacity(0.05),
                  ),
                  child: imageRemoved
                      ? _uploadPrompt(isDark)
                      : kIsWeb
                      ? (webImageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(
                                  webImageBytes!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : (hasExistingImage
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: ApiService.getFullImageUrl(product['imageUrl']) != null
                                          ? Image.network(
                                              ApiService.getFullImageUrl(product['imageUrl'])!,
                                              fit: BoxFit.cover,
                                            )
                                          : _uploadPrompt(isDark),
                                    )
                                  : _uploadPrompt(isDark)))
                      : (pickedFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  File(pickedFile!.path),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : (hasExistingImage
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: ApiService.getFullImageUrl(product['imageUrl']) != null
                                          ? Image.network(
                                              ApiService.getFullImageUrl(product['imageUrl'])!,
                                              fit: BoxFit.cover,
                                            )
                                          : _uploadPrompt(isDark),
                                    )
                                  : _uploadPrompt(isDark))),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Max size: 2 MB · JPG, PNG',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppColors.textMuted(isDark),
                      ),
                    ),
                  ),
                  if (!imageRemoved &&
                      (webImageBytes != null ||
                          pickedFile != null ||
                          hasExistingImage))
                    GestureDetector(
                      onTap: () => ss(() {
                        pickedFile = null;
                        webImageBytes = null;
                        imageRemoved = true;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Remove Image',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary(isDark)),
              ),
            ),
            if (imageRemoved || pickedFile != null || webImageBytes != null)
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.gradWarm,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: uploading
                      ? null
                      : () async {
                          ss(() => uploading = true);
                          final result =
                              await ApiService.updateProduct(product['_id'], {
                                'name': product['name'],
                                'code': product['code'],
                                'brand': product['brand'],
                                'unit': product['unit'],
                                'category': product['category'],
                                'vendor': product['vendor'] is Map
                                    ? product['vendor']['_id']
                                    : product['vendor'],
                                'image': imageRemoved ? null : pickedFile?.path,
                                'webImageBytes': imageRemoved
                                    ? null
                                    : webImageBytes,
                                'removeImage': imageRemoved,
                              });
                          ss(() => uploading = false);
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (result['success'] == true) {
                            _loadProducts();
                            if (context.mounted) {
                              AppNotifications.showSuccess(
                                context,
                                imageRemoved
                                    ? 'Image removed successfully'
                                    : 'Image uploaded successfully',
                              );
                            }
                          } else {
                            if (context.mounted) {
                              AppNotifications.showError(
                                context,
                                result['message'] ?? 'Operation failed',
                              );
                            }
                          }
                        },
                  icon: uploading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          imageRemoved ? Icons.delete : Icons.upload,
                          color: Colors.white,
                          size: 16,
                        ),
                  label: Text(
                    uploading
                        ? 'Processing...'
                        : (imageRemoved ? 'Remove Image' : 'Upload Image'),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _uploadPrompt(bool isDark) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(
        Icons.add_photo_alternate_outlined,
        size: 40,
        color: AppColors.red.withOpacity(0.5),
      ),
      const SizedBox(height: 8),
      Text(
        'Tap to select product image',
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: AppColors.textSecondary(isDark),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'JPG, PNG supported',
        style: GoogleFonts.poppins(
          fontSize: 10,
          color: AppColors.textMuted(isDark),
        ),
      ),
    ],
  );

  void _delete(Map<String, dynamic> product) {
    final isDark = context.read<ThemeProvider>().isDark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardElevated(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Delete Product',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppColors.textPrimary(isDark),
          ),
        ),
        content: Text(
          'Delete "${product['name']}"? This cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary(isDark)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary(isDark)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await ApiService.deleteProduct(product['_id']);
              if (result['success'] == true) {
                _loadProducts();
              } else {
                if (!mounted) return;
                AppNotifications.showError(context, result['message'] ?? 'Delete failed');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggle(Map<String, dynamic> product) async {
    final result = await ApiService.toggleProduct(product['_id']);
    if (result['success'] == true) {
      _loadProducts();
    } else {
      if (!mounted) return;
      AppNotifications.showError(context, result['message'] ?? 'Error');
    }
  }

  Future<void> _bulkToggle(bool activate) async {
    if (_selectedIds.isEmpty) return;
    int success = 0;
    for (final id in _selectedIds) {
      final p = _products.firstWhere((x) => x['_id'] == id, orElse: () => {});
      if (p.isEmpty) continue;
      final isActive = p['isActive'] ?? true;
      if ((activate && !isActive) || (!activate && isActive)) {
        final result = await ApiService.toggleProduct(id);
        if (result['success'] == true) success++;
      } else {
        success++; // already in desired state
      }
    }
    setState(() {
      _bulkMode = false;
      _selectedIds.clear();
    });
    _loadProducts();
    if (mounted) {
      AppNotifications.showSuccess(
        context,
        '${activate ? "Activated" : "Deactivated"} $success product(s)',
      );
    }
  }

  Widget _tf(
    bool isDark,
    TextEditingController c,
    String label,
    IconData icon,
    Color accent,
  ) => TextField(
    controller: c,
    style: TextStyle(color: AppColors.textPrimary(isDark)),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: accent.withOpacity(0.7)),
      prefixIcon: Icon(icon, size: 18, color: accent),
      filled: true,
      fillColor: AppColors.card(isDark),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.border(isDark)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: accent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
  );

  Widget _filterChip(
    bool isDark,
    String label,
    bool selected,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.cardElevated(isDark),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : AppColors.border(isDark),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary(isDark),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final filtered = _filteredProducts;
    final activeCount = _products.where((p) => p['isActive'] == true).length;
    final inactiveCount = _products.length - activeCount;

    return Scaffold(
      backgroundColor: AppColors.bg(isDark),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.gradWarm,
            boxShadow: [
              BoxShadow(
                color: AppColors.red.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Product Management',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const ThemeToggleButton(),
                  IconButton(
                    icon: Icon(
                      _bulkMode ? Icons.close : Icons.checklist_rtl,
                      color: Colors.white,
                    ),
                    tooltip: _bulkMode ? 'Exit Bulk Mode' : 'Bulk Select',
                    onPressed: () => setState(() {
                      _bulkMode = !_bulkMode;
                      _selectedIds.clear();
                    }),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: _loadProducts,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: _bulkMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showDialog(),
              backgroundColor: AppColors.red,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Add Product',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.red))
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: AppColors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: GoogleFonts.poppins(color: AppColors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadProducts,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _products.isEmpty
          ? Center(
              child: Text(
                'No products yet. Tap + to add.',
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary(isDark),
                ),
              ),
            )
          : Column(
              children: [
                // ── Search bar ──────────────────────────────────
                Container(
                  color: AppColors.card(isDark),
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: TextStyle(
                      color: AppColors.textPrimary(isDark),
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by name, code, brand...',
                      hintStyle: TextStyle(
                        color: AppColors.textMuted(isDark),
                        fontSize: 12,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.red,
                        size: 18,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                size: 16,
                                color: AppColors.textMuted(isDark),
                              ),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.bg(isDark),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.border(isDark)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: AppColors.red,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                // ── Filter chips ─────────────────────────────────
                Container(
                  color: AppColors.card(isDark),
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip(
                          isDark,
                          'All',
                          _filterCategory == 'All' &&
                              _filterStatus == 'All' &&
                              _filterVendorId == null,
                          AppColors.red,
                          () => setState(() {
                            _filterCategory = 'All';
                            _filterStatus = 'All';
                            _filterVendorId = null;
                          }),
                        ),
                        _filterChip(
                          isDark,
                          'Active ($activeCount)',
                          _filterStatus == 'Active',
                          AppColors.green,
                          () => setState(
                            () => _filterStatus = _filterStatus == 'Active'
                                ? 'All'
                                : 'Active',
                          ),
                        ),
                        _filterChip(
                          isDark,
                          'Inactive ($inactiveCount)',
                          _filterStatus == 'Inactive',
                          AppColors.orange,
                          () => setState(
                            () => _filterStatus = _filterStatus == 'Inactive'
                                ? 'All'
                                : 'Inactive',
                          ),
                        ),
                        ..._categories.map(
                          (cat) => _filterChip(
                            isDark,
                            cat,
                            _filterCategory == cat,
                            AppColors.red,
                            () => setState(
                              () => _filterCategory = _filterCategory == cat
                                  ? 'All'
                                  : cat,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ── Bulk action bar ──────────────────────────────
                if (_bulkMode)
                  Container(
                    color: AppColors.red.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value:
                              filtered.isNotEmpty &&
                              _selectedIds.length == filtered.length,
                          onChanged: (v) => setState(() {
                            if (v == true) {
                              _selectedIds.addAll(
                                filtered.map((p) => p['_id'] as String),
                              );
                            } else {
                              _selectedIds.clear();
                            }
                          }),
                          activeColor: AppColors.red,
                        ),
                        Text(
                          '${_selectedIds.length} selected',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary(isDark),
                          ),
                        ),
                        const Spacer(),
                        if (_selectedIds.isNotEmpty) ...[
                          GestureDetector(
                            onTap: () => _bulkToggle(true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.green,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Activate',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _bulkToggle(false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.orange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Deactivate',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                // ── Product list ─────────────────────────────────
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No products match your filters.',
                            style: GoogleFonts.poppins(
                              color: AppColors.textSecondary(isDark),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadProducts,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, i) {
                              final p = filtered[i];
                              final isActive = p['isActive'] ?? true;
                              final isSelected = _selectedIds.contains(
                                p['_id'],
                              );
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.red.withOpacity(
                                          isDark ? 0.15 : 0.07,
                                        )
                                      : AppColors.card(isDark),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.red.withOpacity(0.5)
                                        : AppColors.border(isDark),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                  boxShadow: isDark
                                      ? []
                                      : [
                                          BoxShadow(
                                            color: AppColors.red.withOpacity(
                                              0.05,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: _bulkMode
                                      ? () => setState(() {
                                          if (isSelected) {
                                            _selectedIds.remove(p['_id']);
                                          } else {
                                            _selectedIds.add(p['_id']);
                                          }
                                        })
                                      : null,
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (_bulkMode)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              right: 10,
                                              top: 10,
                                            ),
                                            child: Checkbox(
                                              value: isSelected,
                                              onChanged: (v) => setState(() {
                                                if (v == true) {
                                                  _selectedIds.add(p['_id']);
                                                } else {
                                                  _selectedIds.remove(p['_id']);
                                                }
                                              }),
                                              activeColor: AppColors.red,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                          ),
                                        GestureDetector(
                                          onTap: () {
                                            if (_bulkMode) return;
                                            if (p['imageUrl'] != null) {
                                              showDialog(
                                                context: context,
                                                barrierColor: Colors.black87,
                                                builder: (ctx) => Dialog(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  insetPadding:
                                                      const EdgeInsets.all(20),
                                                  child: Stack(
                                                    children: [
                                                      ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              16,
                                                            ),
                                                        child: Image.network(
                                                          ApiService.getFullImageUrl(p['imageUrl'])!,
                                                          fit: BoxFit.contain,
                                                          errorBuilder: (c, e, s) => Container(
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  32,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  AppColors.card(
                                                                    isDark,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    16,
                                                                  ),
                                                            ),
                                                            child: Icon(
                                                              Icons
                                                                  .image_not_supported,
                                                              color:
                                                                  AppColors.textSecondary(
                                                                    isDark,
                                                                  ),
                                                              size: 64,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      Positioned(
                                                        top: 8,
                                                        right: 8,
                                                        child: GestureDetector(
                                                          onTap: () =>
                                                              Navigator.pop(
                                                                ctx,
                                                              ),
                                                          child: Container(
                                                            width: 32,
                                                            height: 32,
                                                            decoration:
                                                                const BoxDecoration(
                                                                  color: Colors
                                                                      .black54,
                                                                  shape: BoxShape
                                                                      .circle,
                                                                ),
                                                            child: const Icon(
                                                              Icons.close,
                                                              color:
                                                                  Colors.white,
                                                              size: 18,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      Positioned(
                                                        top: 8,
                                                        left: 8,
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            Navigator.pop(ctx);
                                                            _showQuickImageUpload(
                                                              context,
                                                              isDark,
                                                              p,
                                                            );
                                                          },
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      10,
                                                                  vertical: 6,
                                                                ),
                                                            decoration:
                                                                BoxDecoration(
                                                                  color: Colors
                                                                      .black54,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        20,
                                                                      ),
                                                                ),
                                                            child: const Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Icon(
                                                                  Icons.edit,
                                                                  color: Colors
                                                                      .white,
                                                                  size: 14,
                                                                ),
                                                                SizedBox(
                                                                  width: 4,
                                                                ),
                                                                Text(
                                                                  'Manage',
                                                                  style: TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      Positioned(
                                                        bottom: 8,
                                                        left: 0,
                                                        right: 0,
                                                        child: Center(
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      12,
                                                                  vertical: 6,
                                                                ),
                                                            decoration:
                                                                BoxDecoration(
                                                                  color: Colors
                                                                      .black54,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        20,
                                                                      ),
                                                                ),
                                                            child: Text(
                                                              p['name'] ?? '',
                                                              style: const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            } else {
                                              _showQuickImageUpload(
                                                context,
                                                isDark,
                                                p,
                                              );
                                            }
                                          },
                                          child: Container(
                                            width: 46,
                                            height: 46,
                                            decoration: BoxDecoration(
                                              color: AppColors.red.withOpacity(
                                                isDark ? 0.15 : 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: AppColors.red
                                                    .withOpacity(0.25),
                                              ),
                                            ),
                                            child: ApiService.getFullImageUrl(p['imageUrl']) != null
                                                ? ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    child: Image.network(
                                                      ApiService.getFullImageUrl(p['imageUrl'])!,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (c, e, s) => Icon(
                                                        Icons
                                                            .image_not_supported,
                                                        color:
                                                            AppColors.textSecondary(
                                                              isDark,
                                                            ),
                                                        size: 20,
                                                      ),
                                                    ),
                                                  )
                                                : Stack(
                                                    alignment: Alignment.center,
                                                    children: [
                                                      Icon(
                                                        Icons.inventory,
                                                        color: AppColors.red
                                                            .withOpacity(0.4),
                                                        size: 22,
                                                      ),
                                                      Positioned(
                                                        bottom: 2,
                                                        right: 2,
                                                        child: Container(
                                                          width: 14,
                                                          height: 14,
                                                          decoration:
                                                              BoxDecoration(
                                                                color: AppColors
                                                                    .red,
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                          child: const Icon(
                                                            Icons.add,
                                                            color: Colors.white,
                                                            size: 10,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _labelRow(
                                                isDark,
                                                'Product Code',
                                                p['code'] ?? '',
                                              ),
                                              const SizedBox(height: 5),
                                              _labelRow(
                                                isDark,
                                                'Product Name',
                                                p['name'] ?? '',
                                              ),
                                              const SizedBox(height: 5),
                                              _labelRow(
                                                isDark,
                                                'Brand Name',
                                                p['brand'] ?? '',
                                              ),
                                              const SizedBox(height: 5),
                                              _labelRow(
                                                isDark,
                                                'Unit',
                                                p['unit'] ?? '',
                                              ),
                                              const SizedBox(height: 5),
                                              _labelRow(
                                                isDark,
                                                'Vendor',
                                                (p['vendor'] is Map)
                                                    ? (p['vendor']['name'] ??
                                                          'No Vendor')
                                                    : (p['vendor'] ??
                                                          'No Vendor'),
                                              ),
                                              const SizedBox(height: 5),
                                              Row(
                                                children: [
                                                  SizedBox(
                                                    width: 90,
                                                    child: Text(
                                                      'Category',
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 11,
                                                        color:
                                                            AppColors.textMuted(
                                                              isDark,
                                                            ),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    ': ',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 11,
                                                      color:
                                                          AppColors.textMuted(
                                                            isDark,
                                                          ),
                                                    ),
                                                  ),
                                                  Flexible(
                                                    child: Wrap(
                                                      spacing: 6,
                                                      runSpacing: 4,
                                                      children: [
                                                        _tag(
                                                          isDark,
                                                          p['category'] ?? '',
                                                          AppColors.red,
                                                        ),
                                                        _tag(
                                                          isDark,
                                                          isActive
                                                              ? 'Active'
                                                              : 'Inactive',
                                                          isActive
                                                              ? AppColors.green
                                                              : AppColors
                                                                    .orange,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (!_bulkMode)
                                          PopupMenuButton<String>(
                                            color: AppColors.cardElevated(
                                              isDark,
                                            ),
                                            icon: Icon(
                                              Icons.more_vert,
                                              color: AppColors.textSecondary(
                                                isDark,
                                              ),
                                            ),
                                            onSelected: (v) {
                                              if (v == 'edit') {
                                                _showDialog(existing: p);
                                              } else if (v == 'toggle')
                                                _toggle(p);
                                              else if (v == 'delete')
                                                _delete(p);
                                            },
                                            itemBuilder: (_) => [
                                              PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.edit,
                                                      size: 16,
                                                      color: AppColors.blue,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Edit',
                                                      style: TextStyle(
                                                        color:
                                                            AppColors.textPrimary(
                                                              isDark,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: 'toggle',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      isActive
                                                          ? Icons.toggle_off
                                                          : Icons.toggle_on,
                                                      size: 16,
                                                      color: AppColors.orange,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      isActive
                                                          ? 'Deactivate'
                                                          : 'Activate',
                                                      style: TextStyle(
                                                        color:
                                                            AppColors.textPrimary(
                                                              isDark,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.delete,
                                                      size: 16,
                                                      color: Colors.red,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Delete',
                                                      style:
                                                          GoogleFonts.poppins(
                                                            color: Colors.red,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _labelRow(bool isDark, String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 90,
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AppColors.textMuted(isDark),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      Text(
        ': ',
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: AppColors.textMuted(isDark),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textPrimary(isDark),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );

  Widget _tag(bool isDark, String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(isDark ? 0.18 : 0.1),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 10,
        color: color,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
