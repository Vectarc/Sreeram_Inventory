import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../app_colors.dart';
import '../widgets/theme_toggle.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../widgets/app_notifications.dart';
import '../widgets/searchable_dropdown.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});
  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  List<Map<String, dynamic>> _users = [];
  List<String> _branches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBranches();
    _loadUsers();
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

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    final result = await ApiService.getUsers();
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _users = List<Map<String, dynamic>>.from(result['users'] ?? []);
      }
    });
  }

  void _showAddUserDialog() {
    final isDark = context.read<ThemeProvider>().isDark;
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String? selectedBranch = _branches.isNotEmpty ? _branches[0] : null;
    bool saving = false;
    bool obscure = true;

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
                  Icons.person_add,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Create User Account',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: AppColors.blue,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _tf(isDark, userCtrl, 'Username', Icons.person, AppColors.blue),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                obscureText: obscure,
                style: TextStyle(color: AppColors.textPrimary(isDark)),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: AppColors.blue.withOpacity(0.7)),
                  prefixIcon: Icon(Icons.lock, size: 18, color: AppColors.blue),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                      color: AppColors.textSecondary(isDark),
                    ),
                    onPressed: () => ss(() => obscure = !obscure),
                  ),
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
                    borderSide: BorderSide(color: AppColors.blue, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
              if (_branches.isNotEmpty) ...[
                const SizedBox(height: 12),
                SearchableDropdown<String>(
                  label: 'Assign Branch',
                  value: selectedBranch,
                  items: _branches,
                  itemAsString: (v) => v,
                  onChanged: (v) => ss(() => selectedBranch = v),
                  isDark: isDark,
                  prefixIcon: Icons.storefront_outlined,
                ),
              ],
            ],
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
                gradient: AppColors.gradCool,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (userCtrl.text.trim().isEmpty ||
                            passCtrl.text.trim().length < 6) {
                          AppNotifications.showWarning(context, 'Username required, password min 6 chars');
                          return;
                        }
                        if (selectedBranch == null) {
                          AppNotifications.showWarning(context, 'Please select a branch');
                          return;
                        }
                        ss(() => saving = true);
                        final res = await ApiService.createUser({
                          'username': userCtrl.text.trim(),
                          'password': passCtrl.text.trim(),
                          'branch': selectedBranch,
                        });
                        ss(() => saving = false);
                        if (res['success'] == true) {
                          Navigator.pop(ctx);
                          _loadUsers();
                          AppNotifications.showSuccess(context, 'User created successfully');
                        } else {
                          AppNotifications.showError(context, res['message'] ?? 'Failed to create user');
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
                    : const Text(
                        'Create',
                        style: TextStyle(
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

  Future<void> _deleteUser(String id, String username) async {
    final isDark = context.read<ThemeProvider>().isDark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardElevated(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Delete User',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(isDark),
          ),
        ),
        content: Text(
          'Delete account for "$username"?',
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
    if (confirm == true) {
      final res = await ApiService.deleteUser(id);
      if (res['success'] == true) {
        _loadUsers();
        AppNotifications.showSuccess(context, 'User deleted');
      } else {
        AppNotifications.showError(context, res['message'] ?? 'Failed to delete user');
      }
    }
  }

  Future<void> _toggleStatus(String id) async {
    final res = await ApiService.toggleUserStatus(id);
    if (res['success'] == true) _loadUsers();
  }

  Future<void> _manageUserPassword(String id, String username) async {
    final isDark = context.read<ThemeProvider>().isDark;
    final adminPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    bool loading = false;
    bool saving = false;
    bool passedAuth = false;
    String? revealedPassword;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          backgroundColor: AppColors.cardElevated(isDark),
          title: Text(
            'Manage Password for $username',
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary(isDark),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: !passedAuth
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Enter Admin password to reveal and manage this user\'s password:',
                      style: TextStyle(color: AppColors.textSecondary(isDark)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: adminPassCtrl,
                      obscureText: true,
                      style: TextStyle(color: AppColors.textPrimary(isDark)),
                      decoration: InputDecoration(
                        labelText: 'Admin Password',
                        filled: true,
                        fillColor: AppColors.card(isDark),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Current Password:',
                      style: TextStyle(color: AppColors.textSecondary(isDark)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      revealedPassword ?? 'Not available for old accounts',
                      style: GoogleFonts.poppins(
                        color: AppColors.blue,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (revealedPassword == 'Password not available')
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Note: Set a new password to make it viewable.',
                          style: TextStyle(
                            color: AppColors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: newPassCtrl,
                      obscureText: true,
                      style: TextStyle(color: AppColors.textPrimary(isDark)),
                      decoration: InputDecoration(
                        labelText: 'Set New Password',
                        filled: true,
                        fillColor: AppColors.card(isDark),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Close',
                style: TextStyle(color: AppColors.textSecondary(isDark)),
              ),
            ),
            if (!passedAuth)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                ),
                onPressed: loading
                    ? null
                    : () async {
                        if (adminPassCtrl.text.isEmpty) return;
                        ss(() => loading = true);
                        final res = await ApiService.revealUserPassword(
                          id,
                          adminPassCtrl.text,
                        );
                        ss(() => loading = false);
                        if (res['success'] == true) {
                          ss(() {
                            revealedPassword = res['password'];
                            passedAuth = true;
                          });
                        } else {
                          AppNotifications.showError(context, res['message'] ?? 'Failed to authenticate');
                        }
                      },
                child: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Authenticate',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            if (passedAuth)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                ),
                onPressed: saving
                    ? null
                    : () async {
                        if (newPassCtrl.text.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Min 6 characters required'),
                            ),
                          );
                          return;
                        }
                        ss(() => saving = true);
                        final res = await ApiService.changeUserPassword(
                          id,
                          newPassCtrl.text,
                        );
                        ss(() => saving = false);
                        if (res['success'] == true) {
                          Navigator.pop(ctx);
                          AppNotifications.showSuccess(context, 'Password updated successfully');
                        } else {
                          AppNotifications.showError(context, res['message'] ?? 'Failed to update');
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Update Password',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
          ],
        ),
      ),
    );
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
                color: AppColors.blue.withOpacity(0.3),
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
                      'User Management',
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
                    onPressed: _loadUsers,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        backgroundColor: AppColors.blue,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.blue))
          : _users.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_outlined,
                    size: 56,
                    color: AppColors.textMuted(isDark),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No users yet.',
                    style: GoogleFonts.poppins(
                      color: AppColors.textSecondary(isDark),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap + to create a user.',
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
              itemCount: _users.length,
              itemBuilder: (ctx, i) {
                final u = _users[i];
                final bool isActive = u['isActive'] ?? true;
                final bool isAdmin = (u['role'] ?? '') == 'admin';
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
                              color: AppColors.blue.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: isActive ? AppColors.gradCool : null,
                            color: isActive
                                ? null
                                : AppColors.cardElevated(isDark),
                            borderRadius: BorderRadius.circular(12),
                            border: isActive
                                ? null
                                : Border.all(color: AppColors.border(isDark)),
                          ),
                          child: Icon(
                            isAdmin ? Icons.admin_panel_settings : Icons.person,
                            color: isActive
                                ? Colors.white
                                : AppColors.textMuted(isDark),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                u['username'] ?? '',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textPrimary(isDark),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  _badge(
                                    isDark,
                                    (u['role'] ?? 'user')
                                        .toString()
                                        .toUpperCase(),
                                    isAdmin ? AppColors.violet : AppColors.blue,
                                  ),
                                  if (u['branch'] != null)
                                    _badge(
                                      isDark,
                                      u['branch'],
                                      AppColors.indigo,
                                    ),
                                  _badge(
                                    isDark,
                                    isActive ? 'Active' : 'Inactive',
                                    isActive
                                        ? AppColors.green
                                        : AppColors.orange,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (!isAdmin)
                          IconButton(
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            icon: const Icon(
                              Icons.vpn_key_rounded,
                              color: AppColors.blue,
                              size: 18,
                            ),
                            tooltip: 'Manage Password',
                            onPressed: () => _manageUserPassword(
                              u['_id'],
                              u['username'] ?? '',
                            ),
                          ),
                        Transform.scale(
                          scale: 0.75,
                          child: Switch(
                            value: isActive,
                            onChanged: (_) => _toggleStatus(u['_id']),
                            activeThumbColor: AppColors.blue,
                            inactiveThumbColor: isDark
                                ? Colors.grey.shade600
                                : Colors.grey.shade400,
                            inactiveTrackColor: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                          ),
                        ),
                        IconButton(
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 18,
                          ),
                          onPressed: () =>
                              _deleteUser(u['_id'], u['username'] ?? ''),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _badge(bool isDark, String text, Color color) => Container(
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
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
