import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class BranchSelectionPage extends StatefulWidget {
  final Widget Function(String branchName) builder;
  final String title;
  final bool isAdmin;

  const BranchSelectionPage({
    super.key,
    required this.builder,
    required this.title,
    this.isAdmin = false,
  });

  @override
  State<BranchSelectionPage> createState() => _BranchSelectionPageState();
}

class _BranchSelectionPageState extends State<BranchSelectionPage> {
  List<Map<String, dynamic>> _branches = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    
    // Admins get all branches, users get public branches
    final result = widget.isAdmin 
        ? await ApiService.getBranches() 
        : await ApiService.getPublicBranches();
        
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _branches = List<Map<String, dynamic>>.from(result['branches'] ?? []);
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
                      'Select Branch - ${widget.title}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
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
                        onPressed: _loadBranches,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _branches.isEmpty
                  ? Center(
                      child: Text(
                        'No branches found.',
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary(isDark),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _branches.length,
                      itemBuilder: (ctx, i) {
                        final b = _branches[i];
                        final name = b['name'] ?? 'Unknown Branch';
                        final location = b['location'] ?? 'No location provided';
                        
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => widget.builder(name),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.card(isDark),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border(isDark)),
                              boxShadow: isDark
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: AppColors.orange.withOpacity(0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.orange.withOpacity(isDark ? 0.15 : 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.storefront_outlined,
                                    color: AppColors.orange,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: AppColors.textPrimary(isDark),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        location,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: AppColors.textSecondary(isDark),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: AppColors.textMuted(isDark),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
