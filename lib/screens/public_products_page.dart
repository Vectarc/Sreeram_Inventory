import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../app_colors.dart';
import '../widgets/theme_toggle.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class PublicProductsPage extends StatefulWidget {
  const PublicProductsPage({super.key});
  @override
  State<PublicProductsPage> createState() => _PublicProductsPageState();
}

class _PublicProductsPageState extends State<PublicProductsPage> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String? _error;
  String _selectedCategory = 'All';
  String _searchText = '';

  final List<String> _categories = [
    'All',
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
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ApiService.getProducts();
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _products = List<Map<String, dynamic>>.from(result['products'] ?? []);
        _applyFilter();
      } else {
        _error = result['message'];
      }
    });
  }

  void _applyFilter() {
    setState(() {
      _filtered = _products.where((p) {
        final matchCat =
            _selectedCategory == 'All' || p['category'] == _selectedCategory;
        final matchSearch =
            _searchText.isEmpty ||
            (p['name'] ?? '').toString().toLowerCase().contains(
              _searchText.toLowerCase(),
            ) ||
            (p['code'] ?? '').toString().toLowerCase().contains(
              _searchText.toLowerCase(),
            );
        return matchCat && matchSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
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
                      'Products',
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
                    onPressed: _load,
                  ),
                ],
              ),
            ),
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
                  ElevatedButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  color: AppColors.card(isDark),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: TextField(
                    onChanged: (v) {
                      _searchText = v;
                      _applyFilter();
                    },
                    style: TextStyle(color: AppColors.textPrimary(isDark)),
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: TextStyle(color: AppColors.textMuted(isDark)),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.red,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: AppColors.cardElevated(isDark),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                Container(
                  color: AppColors.card(isDark),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final sel = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () {
                            _selectedCategory = cat;
                            _applyFilter();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              gradient: sel ? AppColors.gradWarm : null,
                              color: sel
                                  ? null
                                  : AppColors.cardElevated(isDark),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: sel
                                    ? Colors.transparent
                                    : AppColors.border(isDark),
                              ),
                            ),
                            child: Text(
                              cat,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: sel
                                    ? Colors.white
                                    : AppColors.textSecondary(isDark),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Container(
                  color: AppColors.red.withOpacity(isDark ? 0.08 : 0.05),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2, size: 14, color: AppColors.red),
                      const SizedBox(width: 6),
                      Text(
                        '${_filtered.length} product${_filtered.length != 1 ? 's' : ''} found',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No products found.',
                            style: GoogleFonts.poppins(
                              color: AppColors.textSecondary(isDark),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filtered.length,
                            itemBuilder: (ctx, i) {
                              final p = _filtered[i];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.card(isDark),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.border(isDark),
                                  ),
                                  boxShadow: isDark
                                      ? []
                                      : [
                                          BoxShadow(
                                            color: AppColors.red.withOpacity(
                                              0.04,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 46,
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color: AppColors.red.withOpacity(
                                            isDark ? 0.15 : 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: AppColors.red.withOpacity(
                                              0.25,
                                            ),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.inventory_2,
                                          color: AppColors.red,
                                          size: 24,
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
                                                    color: AppColors.textMuted(
                                                      isDark,
                                                    ),
                                                  ),
                                                ),
                                                Flexible(
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.red
                                                          .withOpacity(
                                                            isDark ? 0.18 : 0.1,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                      border: Border.all(
                                                        color: AppColors.red
                                                            .withOpacity(0.3),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      p['category'] ?? '',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style:
                                                          GoogleFonts.poppins(
                                                            fontSize: 10,
                                                            color:
                                                                AppColors.red,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
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
}
