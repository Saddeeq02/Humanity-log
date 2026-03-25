import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';
import '../widgets/sync_indicator.dart';
import 'home_tab.dart';
import 'analytics_tab.dart';
import 'login_screen.dart';
import '../../providers/locale_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeTab(),
    const AnalyticsTab(),
  ];

  void _handleLogout() {
    ref.read(authProvider.notifier).logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgOffWhite,
      appBar: AppBar(
        title: Text(
          'HumanityLog',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language),
            tooltip: AppLocalizations.of(context).get('language'),
            onSelected: (Locale locale) {
              ref.read(localeProvider.notifier).setLocale(locale);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
              const PopupMenuItem<Locale>(value: Locale('en', ''), child: Text('English')),
              const PopupMenuItem<Locale>(value: Locale('ha', ''), child: Text('Hausa')),
              const PopupMenuItem<Locale>(value: Locale('fr', ''), child: Text('Français')),
              const PopupMenuItem<Locale>(value: Locale('sw', ''), child: Text('Kiswahili')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          const SyncIndicator(),
          if (authState.user != null)
             Container(
               width: double.infinity,
               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
               color: AppTheme.primaryTeal.withOpacity(0.05),
               child: Text(
                 '${AppLocalizations.of(context).get('welcome')}: ${authState.user!.name} • ${authState.user!.role.toUpperCase()}',
                 style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.textCharcoal),
               ),
             ).animate().fadeIn(duration: 400.ms),
          
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: Colors.white,
          indicatorColor: AppTheme.accentTerracotta.withOpacity(0.2),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home, color: AppTheme.accentTerracotta),
              label: AppLocalizations.of(context).get('dashboard'),
            ),
            const NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart, color: AppTheme.accentTerracotta),
              label: 'Reports',
            ),
          ],
        ),
      ),
    );
  }
}
