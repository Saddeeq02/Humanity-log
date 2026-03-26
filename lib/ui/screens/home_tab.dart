import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/beneficiary_provider.dart';
import '../../providers/distribution_provider.dart';
import '../../providers/sync_provider.dart';
import '../../core/theme.dart';
import 'report_screen.dart';
import 'distribution_screen.dart';
import '../../providers/locale_provider.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  void _handleGlobalSync(BuildContext context, WidgetRef ref) async {
    // Show a loading snackbar or dialog if needed
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Synchronizing logs & pulling updates...'),
        duration: Duration(seconds: 1),
      ),
    );

    final summary = await ref.read(networkProvider.notifier).manualSync();

    if (summary.status == 'SUCCESS') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          backgroundColor: AppTheme.statusSuccess,
          content: Row(
            children: [
              const Icon(Icons.sync, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pull Complete: ${summary.pulledBeneficiaries} Beneficiaries Synced. Pushed ${summary.pushedRecords} records to system.',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sync Failed: Check network connection.'),
          backgroundColor: AppTheme.statusError,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beneficiaries = ref.watch(beneficiaryProvider);
    final distributions = ref.watch(distributionProvider);
    final pendingSync = ref.watch(pendingSyncCountProvider);
    
    final today = DateTime.now();
    final todayCount = distributions.where((d) => 
      d.timestamp.year == today.year &&
      d.timestamp.month == today.month &&
      d.timestamp.day == today.day
    ).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Operations Control',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textCharcoal,
                ),
              ).animate().fadeIn(duration: 400.ms),
              
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.sync_rounded, color: AppTheme.primaryTeal, size: 32),
                    onPressed: () => _handleGlobalSync(context, ref),
                  ).animate(onPlay: (controller) => controller.repeat())
                    .shimmer(delay: 2.seconds, duration: 1.5.seconds),
                  if (pendingSync > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text('$pendingSync', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context,
                  title: AppLocalizations.of(context).get('dailyReport'),
                  icon: Icons.analytics,
                  color: AppTheme.primaryTeal,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReportScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  context,
                  title: AppLocalizations.of(context).get('scanBeneficiary'),
                  icon: Icons.camera_alt,
                  color: AppTheme.accentTerracotta,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DistributionScreen()),
                    );
                  },
                ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms).moveY(begin: 20),

          const SizedBox(height: 32),

          Text(
            'Live Overview',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textCharcoal,
            ),
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 16),

          _buildStatCard(
            context, 
            title: AppLocalizations.of(context).get('verifiedBeneficiaries'), 
            value: '${beneficiaries.length}',
            icon: Icons.people,
            color: Colors.white,
            borderColor: AppTheme.primaryTeal.withOpacity(0.5),
          ).animate().fadeIn(delay: 500.ms).scaleXY(curve: Curves.easeOutBack),
          
          const SizedBox(height: 16),
          
          _buildStatCard(
            context, 
            title: AppLocalizations.of(context).get('totalDistributions'), 
            value: '$todayCount',
            icon: Icons.local_shipping,
            color: Colors.white,
            borderColor: AppTheme.accentTerracotta.withOpacity(0.5),
          ).animate().fadeIn(delay: 600.ms).scaleXY(curve: Curves.easeOutBack),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.white, size: 36),
            Text(
              title,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                height: 1.2,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, {required String title, required String value, required IconData icon, required Color color, required Color borderColor}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.bgOffWhite,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black12),
            ),
            child: Icon(icon, size: 36, color: AppTheme.textCharcoal),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textCharcoal,
                    fontSize: 36,
                    height: 1.0,
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
