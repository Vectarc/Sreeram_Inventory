import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../app_colors.dart';
import '../widgets/theme_toggle.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../widgets/app_notifications.dart';

class ContactPage extends StatefulWidget {
  final String? branch;
  const ContactPage({super.key, this.branch});
  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  List<Map<String, dynamic>> _contacts = [];
  bool _loading = true;
  String? _error;
  final List<String> _catFilters = [
    'All',
    'Transport',
    'Services',
    'Staff',
    'Management',
    'Import',
    'local supplier',
    'Non TN Supplier',
  ];
  String _selected = 'All';

  List<Map<String, dynamic>> get _filtered => _selected == 'All'
      ? _contacts
      : _contacts.where((c) => c['category'] == _selected).toList();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ApiService.getContacts(branch: widget.branch);
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        final list = List<Map<String, dynamic>>.from(result['contacts'] ?? []);
        list.sort((a, b) {
          final aEmerg = a['isEmergency'] == true ? 1 : 0;
          final bEmerg = b['isEmergency'] == true ? 1 : 0;
          if (aEmerg != bEmerg) {
            return bEmerg.compareTo(aEmerg);
          }
          final catComp = (a['category'] ?? '').compareTo(b['category'] ?? '');
          if (catComp != 0) return catComp;
          return (a['name'] ?? '').compareTo(b['name'] ?? '');
        });
        _contacts = list;
      } else {
        _error = result['message'];
      }
    });
  }

  void _showDialog({Map<String, dynamic>? existing}) {
    final isDark = context.read<ThemeProvider>().isDark;
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final roleCtrl = TextEditingController(text: existing?['role'] ?? '');
    final phoneCtrl = TextEditingController(text: existing?['phone'] ?? '');
    final emailCtrl = TextEditingController(text: existing?['email'] ?? '');
    final bloodGroupCtrl = TextEditingController(text: existing?['bloodGroup'] ?? '');
    final emergencyPhoneCtrl = TextEditingController(text: existing?['emergencyPhone'] ?? '');
    bool isEmergency = existing?['isEmergency'] == true;
    final descCtrl = TextEditingController(text: existing?['description'] ?? '');
    String category = existing?['category'] ?? 'Staff';
    final validCats = ['Transport', 'Services', 'Staff', 'Management', 'Import', 'local supplier', 'Non TN Supplier'];
    if (!validCats.contains(category)) category = 'Staff';
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
                  Icons.contacts,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                existing == null ? 'Add Contact' : 'Edit Contact',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: AppColors.violet,
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
                  'Name',
                  Icons.person_outline,
                  AppColors.violet,
                ),
                const SizedBox(height: 12),
                _tf(
                  isDark,
                  roleCtrl,
                  'Role / Designation',
                  Icons.work_outline,
                  AppColors.violet,
                ),
                const SizedBox(height: 12),
                _tf(
                  isDark,
                  phoneCtrl,
                  'Phone Number',
                  Icons.phone_outlined,
                  AppColors.green,
                ),
                const SizedBox(height: 12),
                 _tf(
                  isDark,
                  emailCtrl,
                  'Email Address',
                  Icons.email_outlined,
                  AppColors.blue,
                ),
                const SizedBox(height: 12),
                _tf(
                  isDark,
                  bloodGroupCtrl,
                  'Blood Group',
                  Icons.water_drop_outlined,
                  AppColors.red,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emergency Contact',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary(isDark),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pin to top of list and add emergency number',
                            style: GoogleFonts.poppins(
                              color: AppColors.textSecondary(isDark),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isEmergency,
                      activeColor: Colors.white,
                      activeTrackColor: AppColors.red,
                      onChanged: (val) {
                        ss(() {
                          isEmergency = val;
                        });
                      },
                    ),
                  ],
                ),
                if (isEmergency) ...[
                  const SizedBox(height: 12),
                  _tf(
                    isDark,
                    emergencyPhoneCtrl,
                    'Emergency Contact Number',
                    Icons.contact_phone_outlined,
                    AppColors.red,
                  ),
                ],
                const SizedBox(height: 12),
                _tf(
                  isDark,
                  descCtrl,
                  'Description',
                  Icons.description_outlined,
                  AppColors.orange,
                  maxLines: null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: category,
                  dropdownColor: AppColors.cardElevated(isDark),
                  style: TextStyle(
                    color: AppColors.textPrimary(isDark),
                    fontSize: 14,
                  ),
                  decoration: _dd(isDark, 'Category'),
                  items: validCats
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => ss(() => category = v!),
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
                        if (nameCtrl.text.trim().isEmpty ||
                            phoneCtrl.text.trim().isEmpty) {
                          AppNotifications.showWarning(context, 'Name and phone are required');
                          return;
                        }
                        ss(() => saving = true);
                        final data = {
                          'name': nameCtrl.text.trim(),
                          'role': roleCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim(),
                          'email': emailCtrl.text.trim(),
                          'bloodGroup': bloodGroupCtrl.text.trim(),
                          'isEmergency': isEmergency,
                          'emergencyPhone': isEmergency ? emergencyPhoneCtrl.text.trim() : '',
                          'category': category,
                          'description': descCtrl.text.trim(),
                          if (widget.branch != null) 'branch': widget.branch,
                        };
                        final result = existing == null
                            ? await ApiService.createContact(data)
                            : await ApiService.updateContact(
                                existing['_id'],
                                data,
                              );
                        ss(() => saving = false);
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (result['success'] == true) {
                          _loadContacts();
                          AppNotifications.showSuccess(context, 'Contact ${existing == null ? 'added' : 'updated'}!');
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

  void _delete(Map<String, dynamic> contact) {
    final isDark = context.read<ThemeProvider>().isDark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardElevated(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Delete Contact',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppColors.textPrimary(isDark),
          ),
        ),
        content: Text(
          'Delete "${contact['name']}"?',
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
              final result = await ApiService.deleteContact(contact['_id']);
              if (result['success'] == true) {
                _loadContacts();
                AppNotifications.showSuccess(context, 'Contact deleted');
              } else {
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

  Color _catColor(String cat) {
    switch (cat) {
      case 'Transport':
        return AppColors.blue;
      case 'Services':
        return AppColors.green;
      case 'Staff':
        return AppColors.violet;
      case 'Management':
        return AppColors.orange;
      case 'Import':
        return Colors.teal;
      case 'local supplier':
        return Colors.indigo;
      case 'Non TN Supplier':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  IconData _catIcon(String role) {
    switch (role) {
      case 'Transport':
        return Icons.local_shipping;
      case 'EB Man':
        return Icons.electric_bolt;
      case 'Electrician':
        return Icons.electrical_services;
      case 'Staff':
        return Icons.person;
      case 'Management':
        return Icons.manage_accounts;
      case 'Import':
        return Icons.flight_land;
      case 'local supplier':
        return Icons.storefront;
      case 'Non TN Supplier':
        return Icons.public;
      default:
        return Icons.person_outline;
    }
  }

  InputDecoration _dd(bool isDark, String label) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: AppColors.textSecondary(isDark)),
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
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  );

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
                color: AppColors.violet.withOpacity(0.3),
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
                      'Contact Directory',
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
                    onPressed: _loadContacts,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDialog(),
        backgroundColor: AppColors.violet,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: Text(
          'Add Contact',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.violet))
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
                    onPressed: _loadContacts,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  color: AppColors.card(isDark),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _catFilters.map((cat) {
                        final sel = _selected == cat;
                        final color = cat == 'All'
                            ? AppColors.violet
                            : _catColor(cat);
                        return GestureDetector(
                          onTap: () => setState(() => _selected = cat),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: sel
                                  ? color
                                  : AppColors.cardElevated(isDark),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: sel ? color : AppColors.border(isDark),
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
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No contacts found.',
                            style: GoogleFonts.poppins(
                              color: AppColors.textSecondary(isDark),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadContacts,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                            itemCount: _filtered.length,
                            itemBuilder: (ctx, i) {
                              final c = _filtered[i];
                              final color = _catColor(c['category'] ?? '');
                              final bool isEmerg = c['isEmergency'] == true;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.card(isDark),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isEmerg ? AppColors.red.withOpacity(0.5) : AppColors.border(isDark),
                                    width: isEmerg ? 1.5 : 1.0,
                                  ),
                                  boxShadow: isDark
                                      ? []
                                      : [
                                          BoxShadow(
                                            color: color.withOpacity(0.06),
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
                                          color: color.withOpacity(
                                            isDark ? 0.18 : 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: color.withOpacity(0.3),
                                          ),
                                        ),
                                        child: Icon(
                                          _catIcon(c['role'] ?? ''),
                                          color: color,
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
                                              'Name',
                                              c['name'] ?? '',
                                              AppColors.textPrimary(isDark),
                                            ),
                                            const SizedBox(height: 5),
                                            _labelRow(
                                              isDark,
                                              'Role',
                                              c['role'] ?? '',
                                              AppColors.textSecondary(isDark),
                                            ),
                                            const SizedBox(height: 5),
                                            Row(
                                              children: [
                                                SizedBox(
                                                  width: 90,
                                                  child: Text(
                                                    'Phone Number',
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
                                                const Icon(
                                                  Icons.phone,
                                                  size: 12,
                                                  color: Color(0xFF2ECC71),
                                                ),
                                                const SizedBox(width: 3),
                                                Flexible(
                                                  child: Text(
                                                    c['phone'] ?? '',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      color: const Color(
                                                        0xFF2ECC71,
                                                      ),
                                                     fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if ((c['email'] ?? '').isNotEmpty) ...[
                                              const SizedBox(height: 5),
                                              _labelRow(
                                                isDark,
                                                'Email Address',
                                                c['email'] ?? '',
                                                AppColors.blue,
                                              ),
                                            ],
                                            if ((c['bloodGroup'] ?? '').isNotEmpty) ...[
                                              const SizedBox(height: 5),
                                              Row(
                                                children: [
                                                  SizedBox(
                                                    width: 90,
                                                    child: Text(
                                                      'Blood Group',
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
                                                  const Icon(
                                                    Icons.water_drop,
                                                    size: 12,
                                                    color: AppColors.red,
                                                  ),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    c['bloodGroup'] ?? '',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      color: AppColors.red,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                            if (isEmerg && (c['emergencyPhone'] ?? '').isNotEmpty) ...[
                                              const SizedBox(height: 5),
                                              Row(
                                                children: [
                                                  SizedBox(
                                                    width: 90,
                                                    child: Text(
                                                      'Emergency Number',
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
                                                  const Icon(
                                                    Icons.contact_phone,
                                                    size: 12,
                                                    color: AppColors.red,
                                                  ),
                                                  const SizedBox(width: 3),
                                                  Flexible(
                                                    child: Text(
                                                      c['emergencyPhone'] ?? '',
                                                      overflow: TextOverflow.ellipsis,
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 12,
                                                        color: AppColors.red,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
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
                                                  child: Wrap(
                                                    spacing: 6,
                                                    runSpacing: 4,
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: color.withOpacity(
                                                            isDark ? 0.18 : 0.1,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                          border: Border.all(
                                                            color: color
                                                                .withOpacity(0.3),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          c['category'] ?? '',
                                                          overflow:
                                                              TextOverflow.ellipsis,
                                                          style:
                                                              GoogleFonts.poppins(
                                                                fontSize: 10,
                                                                color: color,
                                                                fontWeight:
                                                                    FontWeight.w700,
                                                              ),
                                                        ),
                                                      ),
                                                      if (isEmerg)
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 2,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: AppColors.red.withOpacity(
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
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              const Icon(
                                                                Icons.emergency,
                                                                size: 10,
                                                                color: AppColors.red,
                                                              ),
                                                              const SizedBox(width: 2),
                                                              Text(
                                                                'Emergency',
                                                                style:
                                                                    GoogleFonts.poppins(
                                                                      fontSize: 9,
                                                                      color: AppColors.red,
                                                                      fontWeight:
                                                                          FontWeight.w700,
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if ((c['description'] ?? '').isNotEmpty) ...[
                                              const SizedBox(height: 5),
                                              _labelRow(
                                                isDark,
                                                'Description',
                                                c['description'] ?? '',
                                                AppColors.textSecondary(isDark),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        color: AppColors.cardElevated(isDark),
                                        icon: Icon(
                                          Icons.more_vert,
                                          color: AppColors.textSecondary(
                                            isDark,
                                          ),
                                        ),
                                        onSelected: (v) {
                                          if (v == 'edit') {
                                            _showDialog(existing: c);
                                          } else if (v == 'delete')
                                            _delete(c);
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
                                                  style: GoogleFonts.poppins(
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
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _labelRow(bool isDark, String label, String value, Color valueColor) =>
      Row(
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
                color: valueColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
}
