import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../app_colors.dart';
import '../widgets/theme_toggle.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class PublicStockPage extends StatefulWidget {
  const PublicStockPage({super.key});
  @override
  State<PublicStockPage> createState() => _PublicStockPageState();
}

class _PublicStockPageState extends State<PublicStockPage> {
  List<Map<String, dynamic>> _stocks = [];
  List<Map<String, dynamic>> _branchesList = [];
  List<String> get _branches => [
    'All',
    ..._branchesList.map((b) => b['name'] as String),
  ];
  bool _loading = true;
  String _selectedBranch = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final stockRes = await ApiService.getStocks();
    final branchRes = await ApiService.getPublicBranches();
    setState(() {
      _loading = false;
      if (stockRes['success'] == true) {
        _stocks = List<Map<String, dynamic>>.from(stockRes['stocks'] ?? []);
      }
      if (branchRes['success'] == true) {
        _branchesList = List<Map<String, dynamic>>.from(
          branchRes['branches'] ?? [],
        );
      }
    });
  }

  List<Map<String, dynamic>> get _filteredStocks => _selectedBranch == 'All'
      ? _stocks
      : _stocks.where((s) => s['branch'] == _selectedBranch).toList();

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
                          'Stock Overview',
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
                        onPressed: () => _loadData(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.card(isDark),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _branches.map((b) {
                  final sel = _selectedBranch == b;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedBranch = b),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        gradient: sel ? AppColors.gradStock : null,
                        color: sel ? null : AppColors.cardElevated(isDark),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel
                              ? Colors.transparent
                              : AppColors.border(isDark),
                        ),
                      ),
                      child: Text(
                        b,
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
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.green),
                  )
                : _filteredStocks.isEmpty
                ? Center(
                    child: Text(
                      'No stock data found.',
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary(isDark),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredStocks.length,
                      itemBuilder: (ctx, i) {
                        final s = _filteredStocks[i];
                        final qty = (s['quantity'] ?? 0).toDouble();
                        final minLevel = (s['minLevel'] ?? 10).toDouble();
                        final low = qty <= minLevel;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.card(isDark),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: low
                                  ? Colors.red.withOpacity(0.4)
                                  : AppColors.border(isDark),
                              width: low ? 1.5 : 1,
                            ),
                            boxShadow: isDark
                                ? []
                                : [
                                    BoxShadow(
                                      color:
                                          (low ? Colors.red : AppColors.green)
                                              .withOpacity(0.06),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: (low ? Colors.red : AppColors.green)
                                      .withOpacity(isDark ? 0.15 : 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: (low ? Colors.red : AppColors.green)
                                        .withOpacity(0.25),
                                  ),
                                ),
                                child: Icon(
                                  low ? Icons.warning : Icons.warehouse,
                                  color: low ? Colors.red : AppColors.green,
                                  size: 24,
                                ),
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
                                    Text(
                                      '${s['branch']}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppColors.textSecondary(isDark),
                                      ),
                                    ),
                                    Text(
                                      'Quantity: $qty ${s['unit'] ?? ''}  |  Min: $minLevel',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: low
                                            ? Colors.red
                                            : AppColors.textMuted(isDark),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (low)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.red.withOpacity(0.15)
                                        : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.red.withOpacity(0.4),
                                    ),
                                  ),
                                  child: Text(
                                    'LOW',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.red,
                                      fontWeight: FontWeight.w800,
                                    ),
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
}
