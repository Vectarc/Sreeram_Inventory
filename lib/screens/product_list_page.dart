import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../app_colors.dart';
import '../widgets/theme_toggle.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class ProductListPage extends StatefulWidget {
  final String branch;
  const ProductListPage({super.key, required this.branch});
  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List<Map<String, dynamic>> _allProducts = [];
  bool _loading = true;
  String? _error;
  String _selectedCategory = 'All';
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

  List<Map<String, dynamic>> get _filtered => _selectedCategory == 'All'
      ? _allProducts
      : _allProducts.where((p) => p['category'] == _selectedCategory).toList();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ApiService.getProducts(branch: widget.branch);
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _allProducts = List<Map<String, dynamic>>.from(
          result['products'] ?? [],
        ).map((p) => {...p, 'shop': widget.branch}).toList();
      } else {
        _error = result['message'];
      }
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
                color: AppColors.orange.withOpacity(0.3),
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
                      'Product List – ${widget.branch}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const ThemeToggleButton(),
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
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.orange))
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
          : Column(
              children: [
                // Filter bar
                Container(
                  color: AppColors.card(isDark),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', ..._categories].map((cat) {
                        final sel = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
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
                // Summary bar
                Container(
                  color: AppColors.orange.withOpacity(isDark ? 0.08 : 0.05),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.inventory_2,
                        size: 16,
                        color: AppColors.orange,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_filtered.length} product${_filtered.length != 1 ? 's' : ''} found',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.orange,
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
                            'No products in this category.',
                            style: GoogleFonts.poppins(
                              color: AppColors.textSecondary(isDark),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadProducts,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filtered.length,
                            itemBuilder: (ctx, i) {
                              final p = _filtered[i];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.card(isDark),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.border(isDark),
                                  ),
                                  boxShadow: isDark
                                      ? []
                                      : [
                                          BoxShadow(
                                            color: AppColors.orange.withOpacity(
                                              0.05,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                ),
                                child: Row(
                                  children: [
                                    Stack(
                                      children: [
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: AppColors.orange.withOpacity(
                                              isDark ? 0.15 : 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: AppColors.orange
                                                  .withOpacity(0.25),
                                            ),
                                          ),
                                          child: ApiService.getFullImageUrl(p['imageUrl']) != null
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Image.network(
                                                    ApiService.getFullImageUrl(p['imageUrl'])!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (c, e, s) =>
                                                        Icon(
                                                          Icons.inventory_2,
                                                          color:
                                                              AppColors.orange,
                                                          size: 30,
                                                        ),
                                                  ),
                                                )
                                              : Icon(
                                                  Icons.inventory_2,
                                                  color: AppColors.orange,
                                                  size: 30,
                                                ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p['name'] ?? '',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: AppColors.textPrimary(
                                                isDark,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            'Brand: ${p['brand'] ?? '-'}  |  Code: ${p['code'] ?? '-'}  |  ${p['unit'] ?? ''}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: AppColors.textSecondary(
                                                isDark,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              if (p['category'] != null)
                                                _tag(
                                                  isDark,
                                                  p['category'],
                                                  AppColors.orange,
                                                ),
                                              if (p['shop'] != null) ...[
                                                const SizedBox(width: 6),
                                                _tag(
                                                  isDark,
                                                  p['shop'],
                                                  AppColors.indigo,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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

  Widget _tag(bool isDark, String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(isDark ? 0.18 : 0.1),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.25)),
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
