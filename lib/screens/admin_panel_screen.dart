import 'package:flutter/material.dart';
import '../theme_manager.dart';
import '../services/api_service.dart';
import 'sub_users_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  final ThemeManager themeManager;
  const AdminPanelScreen({Key? key, required this.themeManager}) : super(key: key);

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });
    final users = await ApiService().fetchUsers(widget.themeManager);
    if (mounted) {
      setState(() {
        if (widget.themeManager.userRole == 'super_admin') {
          // Super admin only sees other admins and themselves
          _users = users.where((u) => u['role'] == 'admin' || u['role'] == 'super_admin').toList();
        } else {
          _users = users;
        }
        _isLoading = false;
      });
    }
  }

  void _addUser() {
    final formKey = GlobalKey<FormState>();
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    bool obscurePassword = true;
    String selectedRole = 'user';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color ?? const Color(0xFF1E1E2E),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                ),
                padding: const EdgeInsets.all(28),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                      Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Row(
                        children: [
                          Icon(Icons.person_add_rounded, color: Color(0xFF6C63FF), size: 28),
                          SizedBox(width: 12),
                          Text(
                            'Create New User',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: usernameController,
                        maxLength: 25,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) => value!.trim().isEmpty ? 'Username is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        maxLength: 10,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () {
                              setModalState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) => value!.trim().isEmpty ? 'Password is required' : null,
                      ),
                      if (widget.themeManager.userRole == 'super_admin') ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedRole,
                          dropdownColor: Theme.of(context).cardTheme.color ?? const Color(0xFF1E1E2E),
                          borderRadius: BorderRadius.circular(16),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          decoration: const InputDecoration(
                            labelText: 'Role',
                            prefixIcon: Icon(Icons.shield_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'user', child: Text('User')),
                            DropdownMenuItem(value: 'admin', child: Text('Admin')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() {
                                selectedRole = val;
                              });
                            }
                          },
                        ),
                      ],
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (formKey.currentState!.validate()) {
                                  setModalState(() {
                                    isSaving = true;
                                  });
                                  final result = await ApiService().registerUser(
                                    widget.themeManager,
                                    usernameController.text.trim(),
                                    passwordController.text.trim(),
                                    selectedRole,
                                  );
                                  if (mounted) {
                                    setModalState(() {
                                      isSaving = false;
                                    });
                                    if (result['success'] == true) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('User created successfully!'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      _loadUsers();
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(result['message'] ?? 'Failed to create user'),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Save User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ],
                  ),
                ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _deleteUser(Map<String, dynamic> user) async {
    // Safety check: Cannot delete yourself
    if (user['username'] == widget.themeManager.userName) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot delete your own logged-in account!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete user "${user['username']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });
      final ok = await ApiService().deleteUser(widget.themeManager, user['_id']);
      if (mounted) {
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted successfully!'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete user'), backgroundColor: Colors.redAccent),
          );
        }
        _loadUsers();
      }
    }
  }

  void _showUserDetails(Map<String, dynamic> user) {
    final username = user['username'] ?? '';
    final role = user['role'] ?? 'user';
    final id = user['_id'] ?? '';
    final createdAt = user['createdAt'] != null 
        ? DateTime.tryParse(user['createdAt']) 
        : null;
    final dateStr = createdAt != null 
        ? "${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}"
        : 'N/A';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.person_pin_rounded, color: Color(0xFF6C63FF), size: 28),
              SizedBox(width: 12),
              Text(
                'User Details',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Username:', username),
                _buildDetailRow('Role:', role.toUpperCase()),
                _buildDetailRow('User ID:', id),
                _buildDetailRow('Created At:', dateStr),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRefresh() async {
    final users = await ApiService().fetchUsers(widget.themeManager);
    if (mounted) {
      setState(() {
        _users = users;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 28,
              width: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: Colors.grey.withOpacity(0.2), width: 0.5),
              ),
              padding: const EdgeInsets.all(2),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/icon.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Control Center', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addUser,
        backgroundColor: theme.colorScheme.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('ADD USER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: _isLoading && _users.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _users.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline_rounded, size: 80, color: Colors.grey.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            const Text('No users found.', style: TextStyle(color: Colors.grey, fontSize: 18)),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final username = user['username'] ?? '';
                      final role = user['role'] ?? 'user';
                      final isSelf = username == widget.themeManager.userName;

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: (role == 'admin' || role == 'super_admin')
                                ? const Color(0xFF6C63FF).withOpacity(0.25)
                                : const Color(0xFF03DAC6).withOpacity(0.25), 
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                if (widget.themeManager.userRole == 'super_admin' && role == 'admin') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SubUsersScreen(
                                        themeManager: widget.themeManager,
                                        adminId: user['_id'],
                                        adminName: username,
                                      ),
                                    ),
                                  ).then((_) => _loadUsers()); // Refresh on return
                                } else {
                                  _showUserDetails(user);
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(18.0),
                                child: Row(
                                  children: [
                                    // Premium Icon Container (Rounded square)
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: (role == 'admin' || role == 'super_admin')
                                            ? const Color(0xFF6C63FF).withOpacity(0.12)
                                            : const Color(0xFF03DAC6).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        (role == 'admin' || role == 'super_admin')
                                            ? Icons.admin_panel_settings_rounded 
                                            : Icons.person_rounded,
                                        color: (role == 'admin' || role == 'super_admin')
                                            ? const Color(0xFF6C63FF) 
                                            : const Color(0xFF03DAC6),
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 18),
                                    // Username & Badges Column
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            username,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              // Role Badge
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: (role == 'admin' || role == 'super_admin')
                                                      ? const Color(0xFF6C63FF).withOpacity(0.1)
                                                      : const Color(0xFF03DAC6).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  role.toUpperCase(),
                                                  style: TextStyle(
                                                    color: (role == 'admin' || role == 'super_admin') ? const Color(0xFF6C63FF) : const Color(0xFF03DAC6),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              if (isSelf) ...[
                                                const SizedBox(width: 8),
                                                // "YOU" Badge
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Text(
                                                    'YOU',
                                                    style: TextStyle(
                                                      color: Colors.blue,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ]
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Actions: Delete Button and Details Indicator
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (!isSelf)
                                          Padding(
                                            padding: const EdgeInsets.only(right: 8),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () => _deleteUser(user),
                                                borderRadius: BorderRadius.circular(10),
                                                splashColor: Colors.redAccent.withOpacity(0.2),
                                                highlightColor: Colors.redAccent.withOpacity(0.1),
                                                child: Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.redAccent.withOpacity(0.08),
                                                    borderRadius: BorderRadius.circular(10),
                                                    border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1),
                                                  ),
                                                  child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                                ),
                                              ),
                                            ),
                                          ),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: Colors.grey,
                                          size: 22,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
