import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../theme_provider.dart';
import '../app_colors.dart';
import '../widgets/theme_toggle.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../widgets/searchable_dropdown.dart';
import '../widgets/app_notifications.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});
  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Map<String, dynamic>> _stocks = [];
  List<Map<String, dynamic>> _txns = [];
  List<Map<String, dynamic>> _alerts = [];
  List<Map<String, dynamic>> _allProducts = [];
  List<String> _branches = [];
  bool _loadingStocks = true;
  bool _loadingTxns = true;
  bool _loadingAlerts = true;

  // Category filter list (same as product_list_page)
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

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) return;
      if (_tab.index == 1) _loadTransactions();
      if (_tab.index == 2) _loadAlerts();
    });
    _loadBranches();
    _loadAllProducts();
    _loadStocks();
    _loadTransactions();
    _loadAlerts();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadAllProducts() async {
    final result = await ApiService.getProducts();
    if (result['success'] == true) {
      setState(() {
        _allProducts = List<Map<String, dynamic>>.from(
          result['products'] ?? [],
        );
      });
    }
  }

  Future<void> _loadStocks() async {
    setState(() => _loadingStocks = true);
    final result = await ApiService.getStocks();
    setState(() {
      _loadingStocks = false;
      if (result['success'] == true) {
        _stocks = List<Map<String, dynamic>>.from(result['stocks'] ?? []);
      }
    });
  }

  Future<void> _loadTransactions() async {
    setState(() => _loadingTxns = true);
    final result = await ApiService.getTransactions();
    setState(() {
      _loadingTxns = false;
      if (result['success'] == true) {
        _txns = List<Map<String, dynamic>>.from(result['transactions'] ?? []);
      }
    });
  }

  Future<void> _loadAlerts() async {
    setState(() => _loadingAlerts = true);
    final result = await ApiService.getStockAlerts();
    setState(() {
      _loadingAlerts = false;
      if (result['success'] == true) {
        _alerts = List<Map<String, dynamic>>.from(result['alerts'] ?? []);
      }
    });
  }

  Future<void> _loadBranches() async {
    final result = await ApiService.getBranches();
    if (result['success'] == true && mounted) {
      setState(() {
        _branches = (result['branches'] as List)
            .map((b) => b['name'].toString())
            .toList();
      });
    }
  }

  void _showEntry(
    String type, {
    Map<String, dynamic>? prefillProduct,
    String? prefillBranch,
    double? prefillMinLevel,
  }) {
    final isDark = context.read<ThemeProvider>().isDark;
    if (_branches.isEmpty) {
      AppNotifications.showWarning(context, 'Please add branches first');
      return;
    }
    final qCtrl = TextEditingController();
    final nCtrl = TextEditingController();
    final minLevelCtrl = TextEditingController(
      text: prefillMinLevel != null ? prefillMinLevel.toString() : '10',
    );
    String branch = prefillBranch != null && _branches.contains(prefillBranch)
        ? prefillBranch
        : _branches[0];
    String fromB = prefillBranch != null && _branches.contains(prefillBranch)
        ? prefillBranch
        : _branches[0];
    String? toB; // Start as null for "Select Branch" placeholder
    String adjReason = 'Damaged';
    final adjReasons = ['Damaged', 'Expired', 'Lost', 'Other'];
    bool saving = false;
    String? selectedCategory;
    Map<String, dynamic>? selectedProduct;

    if (prefillProduct != null) {
      String? pId;
      if (prefillProduct.containsKey('_id')) {
        pId = prefillProduct['_id']?.toString();
      }
      if (pId == null && prefillProduct.containsKey('product')) {
        final pObj = prefillProduct['product'];
        if (pObj is Map) {
          pId = pObj['_id']?.toString();
        } else {
          pId = pObj?.toString();
        }
      }

      if (pId != null) {
        try {
          selectedProduct = _allProducts.firstWhere(
            (p) => p['_id'].toString() == pId,
          );
        } catch (_) {
          selectedProduct = prefillProduct; // Fallback
        }
      } else {
        selectedProduct = prefillProduct;
      }
      selectedCategory =
          selectedProduct['category'] ??
          selectedProduct['product']?['category'];
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) {
          final filteredProducts = selectedCategory == null
              ? _allProducts
              : _allProducts
                    .where((p) => p['category'] == selectedCategory)
                    .toList();

          return AlertDialog(
            backgroundColor: AppColors.cardElevated(isDark),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _typeColor(type).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _typeIcon(type),
                    color: _typeColor(type),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    _entryTitle(type),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: _typeColor(type),
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SearchableDropdown<String?>(
                    label: 'Category',
                    value: selectedCategory,
                    items: [null, ..._categories],
                    itemAsString: (v) => v ?? 'All Categories',
                    onChanged: (v) => ss(() {
                      selectedCategory = v;
                      if (selectedProduct != null &&
                          v != null &&
                          selectedProduct!['category'] != v) {
                        selectedProduct = null;
                      }
                    }),
                    isDark: isDark,
                    prefixIcon: Icons.category_outlined,
                  ),
                  const SizedBox(height: 12),
                  SearchableDropdown<Map<String, dynamic>?>(
                    label: 'Product',
                    value: selectedProduct,
                    items: filteredProducts,
                    itemAsString: (p) =>
                        p?['name'] ?? p?['productName'] ?? 'Select Product',
                    onChanged: (p) => ss(() => selectedProduct = p),
                    isDark: isDark,
                    prefixIcon: Icons.inventory_2_outlined,
                    enabled: selectedCategory != null,
                  ),
                  if (selectedProduct != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _typeColor(
                          type,
                        ).withOpacity(isDark ? 0.12 : 0.07),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _typeColor(type).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: _typeColor(type),
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${selectedProduct!['name'] ?? selectedProduct!['productName'] ?? ''} • ${selectedProduct!['category'] ?? selectedProduct!['product']?['category'] ?? ''}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: _typeColor(type),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _stockTf(
                    isDark,
                    qCtrl,
                    type == 'adjust' ? 'Quantity to Remove' : 'Quantity',
                    Icons.numbers,
                    _typeColor(type),
                  ),
                  const SizedBox(height: 12),
                  if (type == 'transfer') ...[
                    SearchableDropdown<String>(
                      label: 'From Branch',
                      value: fromB,
                      items: _branches,
                      itemAsString: (v) => v,
                      onChanged: (v) => ss(() => fromB = v!),
                      isDark: isDark,
                      prefixIcon: Icons.storefront_outlined,
                    ),
                    const SizedBox(height: 12),
                    SearchableDropdown<String?>(
                      label: 'To Branch',
                      value: toB,
                      items: [null, ..._branches],
                      itemAsString: (v) => v ?? 'Select Branch',
                      onChanged: (v) => ss(() => toB = v),
                      isDark: isDark,
                      prefixIcon: Icons.store_outlined,
                    ),
                  ] else
                    SearchableDropdown<String>(
                      label: 'Branch',
                      value: branch,
                      items: _branches,
                      itemAsString: (v) => v,
                      onChanged: (v) => ss(() => branch = v!),
                      isDark: isDark,
                      prefixIcon: Icons.storefront_outlined,
                    ),
                  const SizedBox(height: 12),
                  if (type == 'adjust') ...[
                    SearchableDropdown<String>(
                      label: 'Reason',
                      value: adjReason,
                      items: adjReasons,
                      itemAsString: (v) => v,
                      onChanged: (v) => ss(() => adjReason = v!),
                      isDark: isDark,
                      prefixIcon: Icons.report_problem_outlined,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _stockTf(
                    isDark,
                    nCtrl,
                    type == 'adjust'
                        ? 'Additional Notes (optional)'
                        : 'Note / Reason (optional)',
                    Icons.note_outlined,
                    _typeColor(type),
                    maxLines: 2,
                  ),
                  if (type == 'purchase') ...[
                    const SizedBox(height: 12),
                    _stockTf(
                      isDark,
                      minLevelCtrl,
                      'Minimum Stock Level',
                      Icons.warning_amber_outlined,
                      Colors.orange,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                  if (type == 'adjust') ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withOpacity(isDark ? 0.3 : 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Adjustment reduces stock by the entered quantity.',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (selectedProduct == null ||
                            qCtrl.text.trim().isEmpty) {
                          AppNotifications.showWarning(
                            context,
                            'Please select a product and enter quantity',
                          );
                          return;
                        }
                        final qty = double.tryParse(qCtrl.text.trim());
                        if (qty == null || qty <= 0) {
                          AppNotifications.showError(
                            context,
                            'Please enter a valid quantity',
                          );
                          return;
                        }
                        if (type == 'transfer' && toB == null) {
                          AppNotifications.showWarning(
                            context,
                            'Please select destination branch',
                          );
                          return;
                        }
                        if (type == 'transfer' && fromB == toB) {
                          AppNotifications.showError(
                            context,
                            'From and To branch cannot be the same',
                          );
                          return;
                        }
                        ss(() => saving = true);
                        try {
                          final note = type == 'adjust'
                              ? '$adjReason${nCtrl.text.trim().isNotEmpty ? ' — ${nCtrl.text.trim()}' : ''}'
                              : nCtrl.text.trim();
                          final Map<String, dynamic> data = {
                            'type': type,
                            'productId': selectedProduct!['_id'] ?? '',
                            'productName': selectedProduct!['name'] ?? '',
                            'quantity': qty,
                            'note': note,
                          };
                          if (type == 'transfer') {
                            data['fromBranch'] = fromB;
                            data['toBranch'] = toB;
                          } else {
                            data['branch'] = branch;
                            if (type == 'purchase') {
                              final minLevel = double.tryParse(
                                minLevelCtrl.text.trim(),
                              );
                              if (minLevel != null && minLevel > 0) {
                                data['minLevel'] = minLevel;
                              }
                            }
                          }
                          final result = await ApiService.createTransaction(
                            data,
                          );
                          if (!ctx.mounted) return;
                          if (result['success'] == true) {
                            AppNotifications.showSuccess(
                              context,
                              '${_entryTitle(type)} saved!',
                            );
                            _loadStocks();
                            _loadTransactions();
                            _loadAlerts();
                            Navigator.pop(ctx);
                          } else {
                            AppNotifications.showError(
                              context,
                              result['message'] ?? 'Error',
                            );
                          }
                        } catch (e) {
                          AppNotifications.showError(
                            context,
                            'Connection Error: $e',
                          );
                        } finally {
                          if (ctx.mounted) ss(() => saving = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _typeColor(type),
                  foregroundColor: Colors.white,
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
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
  // Dropdowns replaced by SearchableDropdown

  Widget _stockTf(
    bool isDark,
    TextEditingController c,
    String label,
    IconData icon,
    Color accent, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) => TextField(
    controller: c,
    maxLines: maxLines,
    keyboardType: keyboardType,
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

  // InputDecoration removed
  void _deleteStock(Map<String, dynamic> stock) {
    final isDark = context.read<ThemeProvider>().isDark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardElevated(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Delete Stock Entry',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppColors.textPrimary(isDark),
          ),
        ),
        content: Text(
          'Remove "${stock['productName']}" from ${stock['branch']}?',
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
              final result = await ApiService.deleteStock(stock['_id']);
              if (result['success'] == true) {
                _loadStocks();
                _loadAlerts();
                AppNotifications.showSuccess(context, 'Stock entry deleted');
              } else {
                AppNotifications.showError(
                  context,
                  result['message'] ?? 'Delete failed',
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _setMin(Map<String, dynamic> stock) {
    final isDark = context.read<ThemeProvider>().isDark;
    final c = TextEditingController(text: (stock['minLevel'] ?? 10).toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardElevated(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set Minimum Stock Level',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.textPrimary(isDark),
              ),
            ),
            Text(
              stock['productName'] ?? '',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary(isDark),
              ),
            ),
            Text(
              stock['branch'] ?? '',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.textMuted(isDark),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _stockTf(
              isDark,
              c,
              'Minimum Level (${stock['unit'] ?? ''})',
              Icons.warning_amber_outlined,
              Colors.orange,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.orange,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'You will get an alert when stock falls below this level.',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
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
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await ApiService.updateMinLevel(
                stock['_id'],
                double.tryParse(c.text) ?? 10,
              );
              if (result['success'] == true) {
                _loadStocks();
                _loadAlerts();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Minimum level updated'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
            child: Text(
              'Save',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _entryTitle(String t) {
    switch (t) {
      case 'purchase':
        return 'Add Stock';
      case 'sale':
        return 'Reduce Stock';
      case 'transfer':
        return 'Stock Transfer';
      case 'adjust':
        return 'Stock Adjustment';
      default:
        return 'Stock Entry';
    }
  }

  Color _typeColor(String t) {
    switch (t) {
      case 'purchase':
        return AppColors.green;
      case 'sale':
        return AppColors.red;
      case 'transfer':
        return AppColors.blue;
      case 'adjust':
        return AppColors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _typeIcon(String t) {
    switch (t) {
      case 'purchase':
        return Icons.add_circle_outline;
      case 'sale':
        return Icons.remove_circle_outline;
      case 'transfer':
        return Icons.swap_horiz;
      case 'adjust':
        return Icons.build_circle_outlined;
      default:
        return Icons.edit;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    return Scaffold(
      backgroundColor: AppColors.bg(isDark),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.gradStock,
            boxShadow: [
              BoxShadow(
                color: AppColors.green.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'Stock Management',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const ThemeToggleButton(),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: () {
                          _loadStocks();
                          _loadTransactions();
                          _loadAlerts();
                          _loadAllProducts();
                        },
                      ),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  indicatorColor: const Color(0xFFFFD600),
                  labelStyle: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  tabs: [
                    const Tab(text: 'Stock List'),
                    const Tab(text: 'Transactions'),
                    Tab(
                      text: _alerts.isNotEmpty
                          ? 'Alerts (${_alerts.length})'
                          : 'Alerts',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'pur',
            onPressed: () => _showEntry('purchase'),
            backgroundColor: AppColors.green,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              'Add Stock',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          // STOCK LIST
          _loadingStocks
              ? Center(child: CircularProgressIndicator(color: AppColors.green))
              : _stocks.isEmpty
              ? _emptyState(
                  isDark,
                  Icons.inventory_2,
                  'No stock entries yet.',
                  'Tap + Purchase to add stock.',
                )
              : RefreshIndicator(
                  onRefresh: _loadStocks,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
                    itemCount: _stocks.length,
                    itemBuilder: (ctx, i) {
                      final s = _stocks[i];
                      final qty = (s['quantity'] ?? 0).toDouble();
                      final minLevel = (s['minLevel'] ?? 10).toDouble();
                      final low = qty <= minLevel;
                      // Adjustment alerts — list of pending adjustments
                      final adjAlerts = s['adjustmentAlerts'] as List? ?? [];
                      final hasAdjAlert = adjAlerts.isNotEmpty;
                      // Sum up all adjusted quantities for display
                      double totalAdjusted = 0;
                      String adjReasonLabel = '';
                      if (hasAdjAlert) {
                        for (final a in adjAlerts) {
                          totalAdjusted += ((a['quantity'] ?? 0) as num)
                              .toDouble();
                        }
                        // Show the most recent reason
                        final latest = adjAlerts.last;
                        adjReasonLabel = (latest['reason'] ?? 'Adjusted')
                            .toString();
                      }
                      // Border: red if low OR has adjustment alert
                      final needsAttention = low || hasAdjAlert;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card(isDark),
                          borderRadius: BorderRadius.circular(14),
                          border: needsAttention
                              ? Border.all(
                                  color: Colors.red.shade300,
                                  width: 1.5,
                                )
                              : Border.all(color: AppColors.border(isDark)),
                          boxShadow: isDark
                              ? []
                              : [
                                  BoxShadow(
                                    color:
                                        (needsAttention
                                                ? Colors.red
                                                : AppColors.green)
                                            .withOpacity(0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color:
                                        (needsAttention
                                                ? Colors.red
                                                : AppColors.green)
                                            .withOpacity(isDark ? 0.15 : 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color:
                                          (needsAttention
                                                  ? Colors.red
                                                  : AppColors.green)
                                              .withOpacity(0.25),
                                    ),
                                  ),
                                  child: s['product']?['imageUrl'] != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            ApiService.getFullImageUrl(
                                                  s['product']?['imageUrl'],
                                                ) ??
                                                '',
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s2) => Icon(
                                              needsAttention
                                                  ? Icons.warning
                                                  : Icons.warehouse,
                                              color: needsAttention
                                                  ? Colors.red
                                                  : AppColors.green,
                                              size: 24,
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          needsAttention
                                              ? Icons.warning
                                              : Icons.warehouse,
                                          color: needsAttention
                                              ? Colors.red
                                              : AppColors.green,
                                          size: 24,
                                        ),
                                ),
                                if (s['quantity'] == 0)
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'OUT OF\nSTOCK',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s['productName'] ?? '',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.textPrimary(isDark),
                                    ),
                                  ),
                                  if (s['category'] != null ||
                                      s['product']?['category'] != null)
                                    Text(
                                      s['category'] ??
                                          s['product']?['category'] ??
                                          '',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.green,
                                      ),
                                    ),
                                  Text(
                                    s['branch'] ?? '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppColors.textSecondary(isDark),
                                    ),
                                  ),
                                  // ── Stock info row with adjustment badge ──
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 2,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        'Qty: $qty ${s['unit'] ?? ''}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: low
                                              ? Colors.red
                                              : AppColors.green,
                                        ),
                                      ),
                                      if (hasAdjAlert) ...[
                                        Text(
                                          '|',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.red.withOpacity(0.5),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(
                                              isDark ? 0.18 : 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: Colors.red.withOpacity(
                                                0.35,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            '${totalAdjusted % 1 == 0 ? totalAdjusted.toInt() : totalAdjusted} ${s['unit'] ?? ''} $adjReasonLabel',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                      Text(
                                        '|',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.red.withOpacity(0.5),
                                        ),
                                      ),
                                      Text(
                                        'Min: $minLevel',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: low
                                              ? Colors.red
                                              : AppColors.textSecondary(isDark),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert,
                                color: AppColors.textSecondary(isDark),
                              ),
                              color: AppColors.cardElevated(isDark),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              onSelected: (val) {
                                switch (val) {
                                  case 'min':
                                    _setMin(s);
                                    break;
                                  case 'adjust':
                                    _showEntry(
                                      'adjust',
                                      prefillProduct: s['product'] is Map
                                          ? s['product']
                                          : s, // Fallback to s if product is just ID
                                      prefillBranch: s['branch'],
                                    );
                                    break;
                                  case 'reduce':
                                    _showEntry(
                                      'sale',
                                      prefillProduct: s['product'] is Map
                                          ? s['product']
                                          : s,
                                      prefillBranch: s['branch'],
                                    );
                                    break;
                                  case 'transfer':
                                    _showEntry(
                                      'transfer',
                                      prefillProduct: s['product'] is Map
                                          ? s['product']
                                          : s,
                                      prefillBranch: s['branch'],
                                    );
                                    break;
                                  case 'delete':
                                    _deleteStock(s);
                                    break;
                                }
                              },
                              itemBuilder: (context) {
                                final isDark = Provider.of<ThemeProvider>(
                                  context,
                                  listen: false,
                                ).isDark;
                                return [
                                  PopupMenuItem(
                                    value: 'min',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.tune,
                                          size: 18,
                                          color: AppColors.textSecondary(
                                            isDark,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Edit Min Value',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: AppColors.textPrimary(
                                              isDark,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'adjust',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.build_circle_outlined,
                                          size: 18,
                                          color: Colors.orange,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Adjustment',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: AppColors.textPrimary(
                                              isDark,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'reduce',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.remove_circle_outline,
                                          size: 18,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Reduce Stock',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: AppColors.textPrimary(
                                              isDark,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'transfer',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.swap_horiz,
                                          size: 18,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Transfer Stock',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: AppColors.textPrimary(
                                              isDark,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuDivider(),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Delete Stock',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ];
                              },
                            ),
                          ],
                        ), // End of outer Row
                      ); // End of Container
                    }, // End of itemBuilder
                  ),
                ), // End of RefreshIndicator
          // TRANSACTIONS
          _loadingTxns
              ? Center(child: CircularProgressIndicator(color: AppColors.green))
              : _txns.where((t) => t['type'] == 'transfer').isEmpty
              ? Center(
                  child: Text(
                    'No transfer history yet.',
                    style: GoogleFonts.poppins(
                      color: AppColors.textSecondary(isDark),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTransactions,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _txns
                        .where((t) => t['type'] == 'transfer')
                        .length,
                    itemBuilder: (ctx, i) {
                      final filteredList = _txns
                          .where((t) => t['type'] == 'transfer')
                          .toList();
                      final t = filteredList[i];
                      final color = _typeColor(t['type'] ?? '');
                      final dateStr = t['createdAt'] != null
                          ? t['createdAt']
                                .toString()
                                .substring(0, 16)
                                .replaceAll('T', ' ')
                          : '';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.card(isDark),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border(isDark)),
                          boxShadow: isDark
                              ? []
                              : [
                                  BoxShadow(
                                    color: color.withOpacity(0.05),
                                    blurRadius: 6,
                                  ),
                                ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color.withOpacity(isDark ? 0.15 : 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _typeIcon(t['type'] ?? ''),
                                color: color,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t['productName'] ?? '',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppColors.textPrimary(isDark),
                                    ),
                                  ),
                                  Text(
                                    '${(t['type'] ?? '').toUpperCase()}  |  Qty: ${t['quantity']}  |  ${t['branch'] ?? ''}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: AppColors.textSecondary(isDark),
                                    ),
                                  ),
                                  if ((t['note'] ?? '').toString().isNotEmpty)
                                    Text(
                                      t['note'].toString(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: color.withOpacity(0.8),
                                      ),
                                    ),
                                  if ((t['createdBy'] ?? '')
                                      .toString()
                                      .isNotEmpty)
                                    Text(
                                      'By: ${t['createdBy']}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: AppColors.textMuted(isDark),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              dateStr,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: AppColors.textMuted(isDark),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

          // ALERTS
          _loadingAlerts
              ? Center(child: CircularProgressIndicator(color: AppColors.green))
              : _alerts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.green,
                        size: 56,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'All stock levels are good!',
                        style: GoogleFonts.poppins(
                          color: AppColors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'No products are below minimum level.',
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary(isDark),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAlerts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _alerts.length,
                    itemBuilder: (ctx, i) {
                      final s = _alerts[i];
                      final qty = (s['quantity'] ?? 0).toDouble();
                      final minLevel = (s['minLevel'] ?? 10).toDouble();
                      final isLow = qty <= minLevel;
                      final adjAlerts = s['adjustmentAlerts'] as List? ?? [];
                      final hasAdj = adjAlerts.isNotEmpty;

                      // Build per-reason summary from all adjustment alerts
                      final Map<String, double> reasonTotals = {};
                      for (final a in adjAlerts) {
                        final r = (a['reason'] ?? 'Adjusted').toString();
                        reasonTotals[r] =
                            (reasonTotals[r] ?? 0) +
                            ((a['quantity'] ?? 0) as num).toDouble();
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.card(isDark),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? Colors.red.withOpacity(0.35)
                                : Colors.red.shade300,
                            width: 1.5,
                          ),
                          boxShadow: isDark
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.07),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                        ),
                        child: Column(
                          children: [
                            // ── Header row ──────────────────────────────
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
                              child: Row(
                                children: [
                                  // Product image / icon
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 46,
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(
                                            isDark ? 0.15 : 0.08,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: Colors.red.withOpacity(0.25),
                                          ),
                                        ),
                                        child:
                                            ApiService.getFullImageUrl(
                                                  s['product']?['imageUrl'],
                                                ) !=
                                                null
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.network(
                                                  ApiService.getFullImageUrl(
                                                    s['product']?['imageUrl'],
                                                  )!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (c, e, s2) =>
                                                      const Icon(
                                                        Icons
                                                            .warning_amber_rounded,
                                                        color: Colors.red,
                                                        size: 22,
                                                      ),
                                                ),
                                              )
                                            : const Icon(
                                                Icons.warning_amber_rounded,
                                                color: Colors.red,
                                                size: 26,
                                              ),
                                      ),
                                      if (qty == 0) ...[
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                              sigmaX: 1.5,
                                              sigmaY: 1.5,
                                            ),
                                            child: Container(
                                              width: 46,
                                              height: 46,
                                              color: isDark
                                                  ? Colors.black54
                                                  : Colors.white54,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 3,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            'OUT OF\nSTOCK',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.poppins(
                                              fontSize: 6.5,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              height: 1.1,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s['productName'] ?? '',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                            color: AppColors.textPrimary(
                                              isDark,
                                            ),
                                          ),
                                        ),
                                        if (s['category'] != null ||
                                            s['product']?['category'] != null)
                                          Text(
                                            s['category'] ??
                                                s['product']?['category'] ??
                                                '',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.green,
                                            ),
                                          ),
                                        Text(
                                          s['branch'] ?? '',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: AppColors.textSecondary(
                                              isDark,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Add Stock button
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.green.withOpacity(
                                        isDark ? 0.18 : 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.green.withOpacity(0.3),
                                      ),
                                    ),
                                    child: TextButton.icon(
                                      onPressed: () => _showEntry(
                                        'purchase',
                                        prefillProduct: s['product'] is Map
                                            ? s['product']
                                            : s,
                                        prefillBranch: s['branch'],
                                        prefillMinLevel: minLevel,
                                      ),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.green,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        minimumSize: Size.zero,
                                      ),
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                        size: 14,
                                      ),
                                      label: Text(
                                        'Add Stock',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ── Stock qty status bar ─────────────────────
                            Container(
                              margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.black26
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.border(isDark),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Qty
                                  RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.poppins(fontSize: 12),
                                      children: [
                                        TextSpan(
                                          text: 'Qty: ',
                                          style: TextStyle(
                                            color: AppColors.textSecondary(
                                              isDark,
                                            ),
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              '${qty % 1 == 0 ? qty.toInt() : qty} ${s['unit'] ?? ''}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: isLow
                                                ? Colors.red
                                                : AppColors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (hasAdj) ...[
                                    Text(
                                      '  |  ',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppColors.textMuted(isDark),
                                      ),
                                    ),
                                    // Show each reason+qty
                                    Expanded(
                                      child: Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: reasonTotals.entries.map((e) {
                                          final rQty = e.value;
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(
                                                isDark ? 0.18 : 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                              border: Border.all(
                                                color: Colors.red.withOpacity(
                                                  0.3,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              '${rQty % 1 == 0 ? rQty.toInt() : rQty} ${s['unit'] ?? ''} ${e.key}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.red,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ] else
                                    const Spacer(),
                                  Text(
                                    '  |  ',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppColors.textMuted(isDark),
                                    ),
                                  ),
                                  RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.poppins(fontSize: 12),
                                      children: [
                                        TextSpan(
                                          text: 'Min: ',
                                          style: TextStyle(
                                            color: AppColors.textSecondary(
                                              isDark,
                                            ),
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              '${minLevel % 1 == 0 ? minLevel.toInt() : minLevel}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: isLow
                                                ? Colors.red
                                                : AppColors.textSecondary(
                                                    isDark,
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ── Adjustment detail cards ──────────────────
                            if (hasAdj) ...[
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  0,
                                  12,
                                  0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.history_edu,
                                          size: 13,
                                          color: Colors.orange.shade700,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'ADJUSTMENT HISTORY',
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.orange.shade700,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ...adjAlerts.map((a) {
                                      final aQty = ((a['quantity'] ?? 0) as num)
                                          .toDouble();
                                      final aReason =
                                          (a['reason'] ?? 'Adjusted')
                                              .toString();
                                      final aNote = (a['note'] ?? '')
                                          .toString();
                                      final aBy = (a['createdBy'] ?? '')
                                          .toString();
                                      final aAt = a['createdAt'] != null
                                          ? a['createdAt']
                                                .toString()
                                                .substring(0, 16)
                                                .replaceAll('T', ' ')
                                          : '';
                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 6,
                                        ),
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(
                                            isDark ? 0.1 : 0.06,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.orange.withOpacity(
                                              isDark ? 0.25 : 0.3,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: Colors.orange
                                                    .withOpacity(0.15),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                _adjReasonIcon(aReason),
                                                color: Colors.orange.shade700,
                                                size: 14,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 7,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.red
                                                              .withOpacity(
                                                                0.12,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                5,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          aReason.toUpperCase(),
                                                          style:
                                                              GoogleFonts.poppins(
                                                                fontSize: 9,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        '${aQty % 1 == 0 ? aQty.toInt() : aQty} ${s['unit'] ?? ''} removed',
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: Colors.red,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (aNote.isNotEmpty) ...[
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      aNote,
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 11,
                                                        color:
                                                            AppColors.textSecondary(
                                                              isDark,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                  const SizedBox(height: 3),
                                                  Row(
                                                    children: [
                                                      if (aBy.isNotEmpty)
                                                        Text(
                                                          'By: $aBy',
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 10,
                                                            color:
                                                                AppColors.textMuted(
                                                                  isDark,
                                                                ),
                                                          ),
                                                        ),
                                                      if (aBy.isNotEmpty &&
                                                          aAt.isNotEmpty)
                                                        Text(
                                                          '  ·  ',
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 10,
                                                            color:
                                                                AppColors.textMuted(
                                                                  isDark,
                                                                ),
                                                          ),
                                                        ),
                                                      if (aAt.isNotEmpty)
                                                        Text(
                                                          aAt,
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 10,
                                                            color:
                                                                AppColors.textMuted(
                                                                  isDark,
                                                                ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],

                            // ── Low stock warning ────────────────────────
                            if (isLow)
                              Container(
                                margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(
                                    isDark ? 0.12 : 0.07,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.25),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.red,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'Stock is below minimum level! Add fresh stock to restore.',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: Colors.red,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 12),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  IconData _adjReasonIcon(String reason) {
    switch (reason.toLowerCase()) {
      case 'expired':
        return Icons.hourglass_disabled_outlined;
      case 'damaged':
        return Icons.broken_image_outlined;
      case 'lost':
        return Icons.search_off_outlined;
      default:
        return Icons.build_circle_outlined;
    }
  }

  Widget _emptyState(
    bool isDark,
    IconData icon,
    String title,
    String subtitle,
  ) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 56, color: AppColors.textMuted(isDark)),
        const SizedBox(height: 16),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary(isDark),
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            color: AppColors.textMuted(isDark),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
