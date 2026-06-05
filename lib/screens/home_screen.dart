import 'package:flutter/material.dart';
import 'scanner_screen.dart';
import 'saved_data_screen.dart';
import 'onboarding_screen.dart';
import 'admin_panel_screen.dart';
import '../theme_manager.dart';
import '../services/db_service.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  final ThemeManager themeManager;
  const HomeScreen({Key? key, required this.themeManager}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _unsyncedCount = 0;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _checkUnsynced();
  }

  Future<void> _checkUnsynced() async {
    final unsynced = await DBService().getUnsyncedScans();
    if (mounted) {
      setState(() {
        _unsyncedCount = unsynced.length;
      });
    }
  }

  Future<void> _performSync() async {
    if (_isSyncing) return;
    setState(() {
      _isSyncing = true;
    });

    try {
      final synced = await ApiService().syncLocalScans(widget.themeManager);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully synced $synced scans to backend!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
        _checkUnsynced();
      }
    }
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out and disconnect from backend?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService().logout(widget.themeManager);
      } catch (e) {
        debugPrint('Logout API call failed: $e');
      }
      await widget.themeManager.logout();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OnboardingScreen(themeManager: widget.themeManager)),
      );
    }
  }

  Widget _buildPremiumButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onPressed,
    required List<Color> gradientColors,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white54),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withOpacity(0.15),
              ),
            ),
          ),
          SafeArea(
<<<<<<< HEAD
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              height: 40,
                              width: 40,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              clipBehavior: Clip.antiAlias,
                              child: Image.network(
                                'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSqPj-wFvS93WwZ0Zf_W9_E75oJgLq53Wb-Zw&s',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.solar_power,
                                      color: Color(0xFF6C63FF),
                                    ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Premier Energies',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(
                            themeManager.themeMode == ThemeMode.dark
                                ? Icons.light_mode
                                : Icons.dark_mode,
                          ),
                          onPressed: themeManager.toggleTheme,
                        ),
                      ],
                    ),
=======
            child: Column(
              children: [
                // Sticky Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 40,
                            width: 40,
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
                            padding: const EdgeInsets.all(4),
                            clipBehavior: Clip.antiAlias,
                            child: Image.asset(
                              'assets/icon.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Premier Energies',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(widget.themeManager.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
                            onPressed: widget.themeManager.toggleTheme,
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                            onPressed: _logout,
                          ),
                        ],
                      ),
                    ],
>>>>>>> home_page
                  ),
                ),
                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
<<<<<<< HEAD
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.15),
=======
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.15),
>>>>>>> home_page
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
<<<<<<< HEAD
                              Icon(
                                Icons.waving_hand_rounded,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
=======
                              Icon(Icons.waving_hand_rounded, size: 16, color: theme.colorScheme.primary),
>>>>>>> home_page
                              const SizedBox(width: 8),
                              Text(
                                'Hello, ${widget.themeManager.userName} (${widget.themeManager.userRole.toUpperCase()})',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ready to Scan?',
<<<<<<< HEAD
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
=======
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
>>>>>>> home_page
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Divider(color: theme.dividerColor.withOpacity(0.2), height: 1),
                  ),

                  // Sync Status Indicator Section
                  if (_unsyncedCount > 0)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.sync_problem_rounded, color: Colors.orange, size: 28),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$_unsyncedCount Scans Unsynced',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Save locally. Tap Sync to upload.',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          _isSyncing
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
                                )
                              : ElevatedButton(
                                  onPressed: _performSync,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Sync', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                ),
                        ],
                      ),
                    )
                  else
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.cloud_done_rounded, color: Colors.green, size: 28),
                          SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'All Data Synced',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'All data store in Backend',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 10),

                  _buildPremiumButton(
                    context: context,
                    title: 'New Scan',
                    subtitle: 'Scan a barcode and fill the form',
                    icon: Icons.qr_code_scanner_rounded,
<<<<<<< HEAD
                    gradientColors: const [
                      Color(0xFF6C63FF),
                      Color(0xFF9D97FF),
                    ],
                    onPressed: () {
                      Navigator.push(
=======
                    gradientColors: const [Color(0xFF6C63FF), Color(0xFF9D97FF)],
                    onPressed: () async {
                      await Navigator.push(
>>>>>>> home_page
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScannerScreen(),
                        ),
                      );
                      _checkUnsynced();
                    },
                  ),
                  _buildPremiumButton(
                    context: context,
                    title: 'Saved Records',
                    subtitle: 'View and search past scans',
                    icon: Icons.folder_special_rounded,
<<<<<<< HEAD
                    gradientColors: const [
                      Color(0xFF03DAC6),
                      Color(0xFF64E6DA),
                    ],
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SavedDataScreen(),
=======
                    gradientColors: const [Color(0xFF03DAC6), Color(0xFF64E6DA)],
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SavedDataScreen(themeManager: widget.themeManager),
>>>>>>> home_page
                        ),
                      );
                      _checkUnsynced();
                    },
                  ),
                  if (widget.themeManager.userRole == 'admin')
                    _buildPremiumButton(
                      context: context,
                      title: 'User Management',
                      subtitle: 'Manage system users and access',
                      icon: Icons.admin_panel_settings_rounded,
                      gradientColors: const [Color(0xFFE040FB), Color(0xFFEA80FC)],
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminPanelScreen(themeManager: widget.themeManager),
                          ),
                        );
                        _checkUnsynced();
                      },
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  ],
),
    );
  }
}
