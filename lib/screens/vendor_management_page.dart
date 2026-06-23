import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../app_colors.dart';
import '../widgets/theme_toggle.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_notifications.dart';
import '../services/api_service.dart';

class VendorManagementPage extends StatefulWidget {
  final String? branch;
  const VendorManagementPage({super.key, this.branch});
  @override
  State<VendorManagementPage> createState() => _VendorManagementPageState();
}

class _VendorManagementPageState extends State<VendorManagementPage> {
  List<Map<String, dynamic>> _vendors = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  Future<void> _loadVendors() async {
    setState(() => _loading = true);
    final result = await ApiService.getVendors(branch: widget.branch);
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _vendors = List<Map<String, dynamic>>.from(result['vendors'] ?? []);
      }
    });
  }

  void _showDialog({Map<String, dynamic>? existing}) {
    final isDark = context.read<ThemeProvider>().isDark;
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final contactCtrl = TextEditingController(
      text: existing?['contactPerson'] ?? '',
    );
    final phoneCtrl = TextEditingController(text: existing?['phone'] ?? '');
    final emailCtrl = TextEditingController(text: existing?['email'] ?? '');
    final descCtrl = TextEditingController(text: existing?['description'] ?? '');
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
                  gradient: AppColors.gradCool,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.business,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                existing == null ? 'Add Vendor' : 'Edit Vendor',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: AppColors.indigo,
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
                  'Vendor Name',
                  Icons.business,
                  AppColors.indigo,
                ),
                const SizedBox(height: 12),
                _tf(
                  isDark,
                  contactCtrl,
                  'Contact Person',
                  Icons.person,
                  AppColors.indigo,
                ),
                const SizedBox(height: 12),
                 _tf(isDark, phoneCtrl, 'Phone', Icons.phone, AppColors.green),
                const SizedBox(height: 12),
                _tf(isDark, emailCtrl, 'Email', Icons.email, AppColors.blue),
                const SizedBox(height: 12),
                _tf(
                  isDark,
                  descCtrl,
                  'Description',
                  Icons.description_outlined,
                  AppColors.orange,
                  maxLines: null,
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
                gradient: AppColors.gradCool,
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
                          'contactPerson': contactCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim(),
                          'email': emailCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                          if (widget.branch != null) 'branch': widget.branch,
                        };
                        final res = existing == null
                            ? await ApiService.createVendor(data)
                            : await ApiService.updateVendor(
                                existing['_id'],
                                data,
                              );
                        ss(() => saving = false);
                        if (res['success'] == true) {
                          Navigator.pop(ctx);
                          _loadVendors();
                        } else {
                          AppNotifications.showError(context, res['message'] ?? 'Failed to save vendor');
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

  Future<void> _deleteVendor(String id, String name) async {
    final isDark = context.read<ThemeProvider>().isDark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardElevated(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Delete Vendor',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(isDark),
          ),
        ),
        content: Text(
          'Delete "$name"?',
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
      final res = await ApiService.deleteVendor(id);
      if (res['success'] == true) {
        _loadVendors();
        AppNotifications.showSuccess(context, 'Vendor deleted');
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
    Color accent,
    {int? maxLines = 1}
  ) => TextField(
    controller: c,
    maxLines: maxLines,
    keyboardType: maxLines == null ? TextInputType.multiline : TextInputType.text,
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
    return Scaffold(
      backgroundColor: AppColors.bg(isDark),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.gradCool,
            boxShadow: [
              BoxShadow(
                color: AppColors.indigo.withOpacity(0.3),
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
                      'Vendor Management',
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
                    onPressed: _loadVendors,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(),
        backgroundColor: AppColors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.indigo))
          : _vendors.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 56,
                    color: AppColors.textMuted(isDark),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No vendors yet.',
                    style: GoogleFonts.poppins(
                      color: AppColors.textSecondary(isDark),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap + to add a vendor.',
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
              itemCount: _vendors.length,
              itemBuilder: (ctx, i) {
                final v = _vendors[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.card(isDark),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border(isDark)),
                    boxShadow: isDark
                        ? []
                        : [
                            BoxShadow(
                              color: AppColors.indigo.withOpacity(0.05),
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
                            gradient: AppColors.gradCool,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.business,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v['name'] ?? '',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textPrimary(isDark),
                                ),
                              ),
                              if ((v['contactPerson'] ?? '').isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 13,
                                      color: AppColors.textSecondary(isDark),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        v['contactPerson'] ?? '',
                                        overflow: TextOverflow.ellipsis,
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
                              if ((v['phone'] ?? '').isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.phone,
                                      size: 13,
                                      color: AppColors.green,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        v['phone'] ?? '',
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: AppColors.green,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if ((v['email'] ?? '').isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.email,
                                      size: 13,
                                      color: AppColors.blue,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        v['email'] ?? '',
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: AppColors.blue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if ((v['description'] ?? '').isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.description_outlined,
                                      size: 13,
                                      color: AppColors.orange,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        v['description'] ?? '',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: AppColors.textSecondary(isDark),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.edit,
                                color: AppColors.blue,
                                size: 20,
                              ),
                              onPressed: () => _showDialog(existing: v),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed: () =>
                                  _deleteVendor(v['_id'], v['name'] ?? ''),
                            ),
                          ],
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
