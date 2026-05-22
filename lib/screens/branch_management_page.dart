import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../app_colors.dart';
import '../widgets/theme_toggle.dart';
import '../widgets/app_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class BranchManagementPage extends StatefulWidget {
  final String? selectedBranchName;
  const BranchManagementPage({super.key, this.selectedBranchName});
  @override
  State<BranchManagementPage> createState() => _BranchManagementPageState();
}

class _BranchManagementPageState extends State<BranchManagementPage> {
  List<Map<String, dynamic>> _branches = [];
  bool _loading = true;
  String? _selectedBranchName;

  @override
  void initState() {
    super.initState();
    _selectedBranchName = widget.selectedBranchName;
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    setState(() => _loading = true);
    final result = await ApiService.getBranches();
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        final allBranches = List<Map<String, dynamic>>.from(result['branches'] ?? []);
        if (_selectedBranchName != null) {
          _branches = allBranches
              .where((b) => b['name']?.toString().toLowerCase() ==
                  _selectedBranchName!.toLowerCase())
              .toList();
        } else {
          _branches = allBranches;
        }
      }
    });
  }

  void _showDialog({Map<String, dynamic>? existing}) {
    final isDark = context.read<ThemeProvider>().isDark;
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final locCtrl = TextEditingController(text: existing?['location'] ?? '');
    final phoneCtrl = TextEditingController(text: existing?['phone'] ?? '');
    final emailCtrl = TextEditingController(text: existing?['email'] ?? '');
    final hoursCtrl = TextEditingController(
      text: existing?['officeHours'] ?? '',
    );
    bool isMain = existing?['isMain'] ?? false;
    final hasMainElseWhere = _branches.any(
      (b) => b['isMain'] == true && b['_id'] != existing?['_id'],
    );
    bool saving = false;

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
                  gradient: AppColors.gradStock,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.store, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                existing == null ? 'Add Branch' : 'Edit Branch',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: AppColors.teal,
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
                  nameCtrl,
                  'Branch Name',
                  Icons.store,
                  AppColors.teal,
                ),
                const SizedBox(height: 12),
                _tf(
                  isDark,
                  locCtrl,
                  'Location / Address',
                  Icons.location_on,
                  AppColors.teal,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                _tf(isDark, phoneCtrl, 'Phone', Icons.phone, AppColors.green),
                const SizedBox(height: 12),
                _tf(isDark, emailCtrl, 'Email', Icons.email, AppColors.blue),
                const SizedBox(height: 12),
                _tf(
                  isDark,
                  hoursCtrl,
                  'Office Hours',
                  Icons.access_time,
                  AppColors.orange,
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.card(isDark),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border(isDark)),
                  ),
                  child: SwitchListTile(
                    title: Text(
                      'Main Branch',
                      style: TextStyle(
                        color: hasMainElseWhere
                            ? AppColors.textMuted(isDark)
                            : AppColors.textPrimary(isDark),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      hasMainElseWhere
                          ? 'Another branch is already set as main'
                          : 'Details shown in contact section',
                      style: TextStyle(
                        color: AppColors.textSecondary(isDark),
                        fontSize: 12,
                      ),
                    ),
                    value: isMain,
                    activeThumbColor: AppColors.teal,
                    onChanged: (hasMainElseWhere && !isMain)
                        ? null
                        : (v) => ss(() => isMain = v),
                  ),
                ),
              ],
            ),
          ),
          actions: [
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
                gradient: AppColors.gradStock,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (nameCtrl.text.trim().isEmpty) return;
                        ss(() => saving = true);
                        final data = {
                          'name': nameCtrl.text.trim(),
                          'location': locCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim(),
                          'email': emailCtrl.text.trim(),
                          'officeHours': hoursCtrl.text.trim(),
                          'isMain': isMain,
                        };
                        final res = existing == null
                            ? await ApiService.createBranch(data)
                            : await ApiService.updateBranch(
                                existing['_id'],
                                data,
                              );
                        ss(() => saving = false);
                        if (res['success'] == true) {
                          Navigator.pop(ctx);
                          if (existing != null && _selectedBranchName != null &&
                              existing['name']?.toString().toLowerCase() == _selectedBranchName!.toLowerCase()) {
                            final newName = nameCtrl.text.trim();
                            setState(() {
                              _selectedBranchName = newName;
                            });
                            final savedUsername = await ApiService.getSavedUsername();
                            if (savedUsername != null) {
                              await ApiService.saveUserInfo(savedUsername, 'admin', branch: newName);
                            }
                          }
                          _loadBranches();
                        } else {
                          if (mounted) {
                            AppNotifications.showError(context, res['message'] ?? 'Failed to save branch');
                          }
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

  Future<void> _deleteBranch(String id) async {
    final isDark = context.read<ThemeProvider>().isDark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardElevated(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Delete Branch',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(isDark),
          ),
        ),
        content: Text(
          'Are you sure you want to delete this branch?',
          style: TextStyle(color: AppColors.textSecondary(isDark)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary(isDark)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final res = await ApiService.deleteBranch(id);
      if (res['success'] == true) {
        _loadBranches();
        AppNotifications.showSuccess(context, 'Branch deleted');
      } else {
        AppNotifications.showError(context, res['message'] ?? 'Failed to delete');
      }
    }
  }

  Widget _tf(
    bool isDark,
    TextEditingController c,
    String label,
    IconData icon,
    Color accent, {
    int maxLines = 1,
  }) => TextField(
    controller: c,
    maxLines: maxLines,
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

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _selectedBranchName);
      },
      child: Scaffold(
      backgroundColor: AppColors.bg(isDark),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.gradStock,
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withOpacity(0.3),
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
                    onPressed: () => Navigator.pop(context, _selectedBranchName),
                  ),
                  Expanded(
                    child: Text(
                      'Branch Management',
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
                    onPressed: _loadBranches,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: _selectedBranchName != null
          ? null
          : FloatingActionButton(
              onPressed: () => _showDialog(),
              backgroundColor: AppColors.teal,
              child: const Icon(Icons.add, color: Colors.white),
            ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.teal))
          : _branches.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.store_outlined,
                    size: 56,
                    color: AppColors.textMuted(isDark),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No branches yet.',
                    style: GoogleFonts.poppins(
                      color: AppColors.textSecondary(isDark),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap + to add a branch.',
                    style: GoogleFonts.poppins(
                      color: AppColors.textMuted(isDark),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _branches.length,
              itemBuilder: (ctx, i) {
                final b = _branches[i];
                final isMain = b['isMain'] ?? false;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.card(isDark),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isMain
                          ? AppColors.teal.withOpacity(0.4)
                          : AppColors.border(isDark),
                      width: isMain ? 1.5 : 1,
                    ),
                    boxShadow: isDark
                        ? []
                        : [
                            BoxShadow(
                              color: AppColors.teal.withOpacity(
                                isMain ? 0.1 : 0.05,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: AppColors.gradStock,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.store,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      b['name'] ?? '',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: AppColors.textPrimary(isDark),
                                      ),
                                    ),
                                  ),
                                  if (isMain)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: AppColors.gradStock,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'Main',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if ((b['location'] ?? '').isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 13,
                                      color: AppColors.textSecondary(isDark),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        b['location'] ?? '',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: AppColors.textSecondary(
                                            isDark,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if ((b['phone'] ?? '').isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.phone,
                                      size: 13,
                                      color: AppColors.green,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      b['phone'] ?? '',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppColors.green,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if ((b['officeHours'] ?? '').isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 13,
                                      color: AppColors.textMuted(isDark),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      b['officeHours'] ?? '',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: AppColors.textMuted(isDark),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.edit,
                                color: AppColors.blue,
                                size: 20,
                              ),
                              onPressed: () => _showDialog(existing: b),
                            ),
                            if (_selectedBranchName == null)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: () => _deleteBranch(b['_id']),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }
}
