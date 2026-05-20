import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../app_colors.dart';
import '../widgets/theme_toggle.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class PublicContactsPage extends StatefulWidget {
  const PublicContactsPage({super.key});
  @override
  State<PublicContactsPage> createState() => _PublicContactsPageState();
}

class _PublicContactsPageState extends State<PublicContactsPage> {
  List<Map<String, dynamic>> _contacts = [];
  bool _loading = true;
  String? _error;
  String _selected = 'All';
  final List<String> _filters = ['All','Transport','Services','Staff','Management'];

  List<Map<String, dynamic>> get _filtered => _selected == 'All' ? _contacts : _contacts.where((c) => c['category'] == _selected).toList();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final result = await ApiService.getContacts();
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        final allContacts = List<Map<String, dynamic>>.from(result['contacts'] ?? []);
        final allowed = ['Transport', 'Services', 'Staff', 'Management'];
        _contacts = allContacts.where((c) => allowed.contains(c['category'])).toList();
      } else {
        _error = result['message'];
      }
    });
  }

  Color _catColor(String cat) {
    switch (cat) {
      case 'Transport': return AppColors.blue;
      case 'Services': return AppColors.green;
      case 'Staff': return AppColors.violet;
      case 'Management': return AppColors.orange;
      default: return Colors.grey;
    }
  }

  IconData _catIcon(String cat) {
    switch (cat) {
      case 'Transport': return Icons.local_shipping;
      case 'Services': return Icons.build;
      case 'Staff': return Icons.person;
      case 'Management': return Icons.manage_accounts;
      default: return Icons.person_outline;
    }
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
            gradient: AppColors.gradCool,
            boxShadow: [BoxShadow(color: AppColors.violet.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: SafeArea(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
              Expanded(child: Text('Contacts', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
              const ThemeToggleButton(),
              IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _load),
            ]),
          )),
        ),
      ),
      body: _loading
        ? Center(child: CircularProgressIndicator(color: AppColors.violet))
        : _error != null
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.error_outline, color: AppColors.red, size: 48), const SizedBox(height: 12),
            Text(_error!, style: GoogleFonts.poppins(color: AppColors.red), textAlign: TextAlign.center),
            const SizedBox(height: 16), ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ]))
        : Column(children: [
            Container(
              color: AppColors.card(isDark),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SingleChildScrollView(scrollDirection: Axis.horizontal,
                child: Row(children: _filters.map((cat) {
                  final sel = _selected == cat;
                  final color = cat == 'All' ? AppColors.violet : _catColor(cat);
                  return GestureDetector(
                    onTap: () => setState(() => _selected = cat),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel ? color : AppColors.cardElevated(isDark),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? color : AppColors.border(isDark)),
                      ),
                      child: Text(cat, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : AppColors.textSecondary(isDark))),
                    ),
                  );
                }).toList()),
              ),
            ),
            Expanded(child: _filtered.isEmpty
              ? Center(child: Text('No contacts found.', style: GoogleFonts.poppins(color: AppColors.textSecondary(isDark))))
              : RefreshIndicator(onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) {
                      final c = _filtered[i];
                      final color = _catColor(c['category'] ?? '');
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.card(isDark),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border(isDark)),
                          boxShadow: isDark ? [] : [BoxShadow(color: color.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Padding(padding: const EdgeInsets.all(14), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(width: 46, height: 46,
                            decoration: BoxDecoration(color: color.withOpacity(isDark ? 0.18 : 0.1), borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: color.withOpacity(0.3))),
                            child: Icon(_catIcon(c['category'] ?? ''), color: color, size: 24)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            _labelRow(isDark, 'Name', c['name'] ?? '', AppColors.textPrimary(isDark)),
                            const SizedBox(height: 5),
                            _labelRow(isDark, 'Role', c['role'] ?? '', AppColors.textSecondary(isDark)),
                            const SizedBox(height: 5),
                            Row(children: [
                              SizedBox(width: 90, child: Text('Phone Number', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted(isDark), fontWeight: FontWeight.w500))),
                              Text(': ', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted(isDark))),
                              const Icon(Icons.phone, size: 12, color: Color(0xFF2ECC71)),
                              const SizedBox(width: 3),
                              Flexible(child: Text(c['phone'] ?? '', overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF2ECC71), fontWeight: FontWeight.w600))),
                            ]),
                            const SizedBox(height: 5),
                            Row(children: [
                              SizedBox(width: 90, child: Text('Category', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted(isDark), fontWeight: FontWeight.w500))),
                              Text(': ', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted(isDark))),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: color.withOpacity(isDark ? 0.18 : 0.1), borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: color.withOpacity(0.3))),
                                  child: Text(c['category'] ?? '', overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 10, color: color, fontWeight: FontWeight.w700))),
                              ),
                            ]),
                            if ((c['description'] ?? '').isNotEmpty) ...[
                              const SizedBox(height: 5),
                              _labelRow(isDark, 'Description', c['description'] ?? '', AppColors.textSecondary(isDark)),
                            ],
                          ])),
                        ])),
                      );
                    },
                  ))),
          ]),
    );
  }

  Widget _labelRow(bool isDark, String label, String value, Color valueColor) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    SizedBox(width: 90, child: Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted(isDark), fontWeight: FontWeight.w500))),
    Text(': ', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted(isDark))),
    Expanded(child: Text(value, style: GoogleFonts.poppins(fontSize: 13, color: valueColor, fontWeight: FontWeight.w600))),
  ]);
}
