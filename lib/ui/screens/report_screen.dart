import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/distribution_provider.dart';
import '../../core/theme.dart';
import '../../providers/locale_provider.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _handleDiscrepancy(InventoryStatus type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report ${type == InventoryStatus.short ? 'Shortage' : 'Overage'}', style: GoogleFonts.outfit()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter the actual physical amount you received:', style: GoogleFonts.inter()),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Actual Count',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(_amountController.text.trim());
              if (val != null && val >= 0) {
                ref.read(inventoryProvider.notifier).reportDiscrepancy(val, type);
                Navigator.pop(context);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _handleReturn() {
    _amountController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Log Returned Aid', style: GoogleFonts.outfit()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter the amount of aid you are returning to the NGO:', style: GoogleFonts.inter()),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Amount to Return',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(_amountController.text.trim());
              if (val != null && val >= 0) {
                ref.read(inventoryProvider.notifier).recordReturn(val);
                Navigator.pop(context);
              }
            },
            child: const Text('Submit Return'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventory = ref.watch(inventoryProvider);
    final distributions = ref.watch(distributionProvider);
    
    final today = DateTime.now();
    final todaysDistributions = distributions.where((d) => 
      d.timestamp.year == today.year &&
      d.timestamp.month == today.month &&
      d.timestamp.day == today.day
    ).toList();
    
    final disbursedCount = todaysDistributions.length;
    final remainingInventory = inventory.receivedAid != null 
        ? inventory.receivedAid! - inventory.returnedAid - disbursedCount 
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).get('dailyReport'), style: GoogleFonts.outfit()),
        elevation: 0,
      ),
      body: inventory.status == InventoryStatus.pending
          ? _buildSetupView(inventory.assignedAid)
          : _buildReportView(inventory, disbursedCount, remainingInventory, todaysDistributions),
      floatingActionButton: inventory.status != InventoryStatus.pending 
          ? FloatingActionButton.extended(
              onPressed: _handleReturn,
              backgroundColor: AppTheme.accentTerracotta,
              label: Text('Log Returns', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              icon: const Icon(Icons.undo),
            )
          : null,
    );
  }

  Widget _buildSetupView(int assigned) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2, size: 80, color: AppTheme.primaryTeal).animate().scale(duration: 400.ms),
            const SizedBox(height: 24),
            Text(
              'NGO Assignment',
              style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textCharcoal),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.primaryTeal, width: 2),
              ),
              child: Column(
                children: [
                  Text('Assigned Aid Quantity:', style: GoogleFonts.inter(fontSize: 16, color: Colors.black54)),
                  const SizedBox(height: 8),
                  Text('$assigned Boxes', style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal)),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms).moveY(begin: 20),
            
            const SizedBox(height: 48),

            ElevatedButton(
              onPressed: () => ref.read(inventoryProvider.notifier).acceptAll(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.statusSuccess,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('Accept All ($assigned)', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
            ).animate().fadeIn(delay: 400.ms).moveY(begin: 20),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleDiscrepancy(InventoryStatus.short),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.statusError, width: 2),
                      minimumSize: const Size(0, 60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('Report Short', style: GoogleFonts.outfit(fontSize: 18, color: AppTheme.statusError)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleDiscrepancy(InventoryStatus.over),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.blue, width: 2),
                      minimumSize: const Size(0, 60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('Report Over', style: GoogleFonts.outfit(fontSize: 18, color: Colors.blue)),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 500.ms).moveY(begin: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildReportView(DailyInventory inventory, int disbursed, int remaining, List todaysDistributions) {
    String statusText = 'Accepted Full Assignment';
    Color statusColor = AppTheme.statusSuccess;
    if (inventory.status == InventoryStatus.short) {
      statusText = 'Reported Shortage (${inventory.receivedAid} Rcvd)';
      statusColor = AppTheme.statusError;
    } else if (inventory.status == InventoryStatus.over) {
      statusText = 'Reported Overage (${inventory.receivedAid} Rcvd)';
      statusColor = Colors.blue;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Inventory Tracker', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textCharcoal)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: statusColor)),
                child: Text(statusText, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor)),
              )
            ],
          ).animate().fadeIn(),
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Aid Collected',
                  inventory.receivedAid.toString(),
                  Icons.archive,
                  Colors.blue.shade100,
                  Colors.blue.shade800,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Disbursed',
                  disbursed.toString(),
                  Icons.check_circle,
                  AppTheme.statusSuccess.withOpacity(0.2),
                  AppTheme.statusSuccess,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 100.ms).moveY(begin: 10),
          const SizedBox(height: 16),
          
          Row(
            children: [
               Expanded(
                child: _buildMetricCard(
                  'Returned',
                  inventory.returnedAid.toString(),
                  Icons.undo,
                  AppTheme.accentTerracotta.withOpacity(0.1),
                  AppTheme.accentTerracotta,
                ),
              ),
               const SizedBox(width: 16),
               Expanded(
                child: _buildMetricCard(
                  'Remaining',
                  remaining.toString(),
                  remaining <= 5 ? Icons.warning_amber_rounded : Icons.inventory,
                  remaining <= 5 ? AppTheme.statusError.withOpacity(0.1) : AppTheme.primaryTeal.withOpacity(0.1),
                  remaining <= 5 ? AppTheme.statusError : AppTheme.primaryTeal,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms).moveY(begin: 10),
          
          const SizedBox(height: 48),
          
          Text(
            'Recent Distributions',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textCharcoal),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 16),
          
          if (todaysDistributions.isEmpty)
             Center(
               child: Padding(
                 padding: const EdgeInsets.all(32.0),
                 child: Text('No aid distributed today yet.', style: GoogleFonts.inter(color: Colors.black54)),
               )
             )
          else
            ...todaysDistributions.reversed.take(5).map((log) {
              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.bgOffWhite,
                    child: Icon(Icons.person, color: Colors.black54),
                  ),
                  title: Text(log.beneficiaryId.replaceAll('WALK-IN-', 'Reg ID: '), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text(
                    '${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')} • ${log.aidType}',
                    style: GoogleFonts.inter(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.verified, color: AppTheme.statusSuccess, size: 20),
                ),
              ).animate().fadeIn(delay: 400.ms);
            }),
            
          const SizedBox(height: 32),
          
          if (inventory.status != InventoryStatus.pending && inventory.status != InventoryStatus.reconciling && inventory.status != InventoryStatus.completed)
            ElevatedButton(
              onPressed: _showFinishConfirmation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.textCharcoal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.flag_circle),
                  const SizedBox(width: 12),
                  Text('FINISH MISSION & RETURN STOCK', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms).moveY(begin: 20),

          if (inventory.status == InventoryStatus.reconciling || inventory.status == InventoryStatus.completed)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.bgOffWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.pending_actions, size: 48, color: AppTheme.primaryTeal),
                  const SizedBox(height: 12),
                  Text(
                    inventory.status == InventoryStatus.completed ? 'Mission Completed & Verified' : 'Mission Reconciling...',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textCharcoal),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    inventory.status == InventoryStatus.completed 
                      ? 'The NGO has verified all distributions and returns. This mission is archived.'
                      : 'Waiting for NGO Admin to verify your reported distributions and returns.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms),
            
          const SizedBox(height: 80), // Fab space
        ],
      ),
    );
  }

  void _showFinishConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Finish Mission?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          'This will submit your final report and returned stock counts to the NGO. You will not be able to log more distributions for this mission once submitted.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Show loading
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submitting final report...')));
                await ref.read(networkProvider.notifier).reconcileMission();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mission reconciliation submitted successfully!'), backgroundColor: AppTheme.statusSuccess)
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to submit: $e'), backgroundColor: AppTheme.statusError)
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.textCharcoal, foregroundColor: Colors.white),
            child: const Text('Confirm & Submit'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color bgColor, Color fgColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fgColor, size: 28),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: fgColor.withOpacity(0.8))),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: fgColor, height: 1.0)),
        ],
      ),
    );
  }
}
