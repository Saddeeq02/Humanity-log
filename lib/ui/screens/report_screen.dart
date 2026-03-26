import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/distribution_provider.dart';
import '../../core/theme.dart';
import '../../providers/locale_provider.dart';
import '../../providers/sync_provider.dart';

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

  void _handleReturn(InventoryItemStock item) {
    _amountController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Return ${item.name}', style: GoogleFonts.outfit()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter amount of ${item.name} returning to warehouse:', style: GoogleFonts.inter()),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Current Physical Stock: ${item.assigned - item.distributed}',
                border: const OutlineInputBorder(),
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
                ref.read(inventoryProvider.notifier).recordReturn(item.inventoryId, val);
                Navigator.pop(context);
              }
            },
            child: const Text('Save Return'),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).get('dailyReport'), style: GoogleFonts.outfit()),
        elevation: 0,
      ),
      body: inventory.status == InventoryStatus.pending
          ? _buildSetupView(inventory.totalAssigned)
          : _buildReportView(inventory, todaysDistributions),
      floatingActionButton: (inventory.status == InventoryStatus.accepted || inventory.status == InventoryStatus.in_progress)
          ? FloatingActionButton.extended(
              onPressed: () => _showReconciliationDialog(inventory),
              backgroundColor: AppTheme.textCharcoal,
              label: Text('FINISH MISSION', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              icon: const Icon(Icons.flag_circle),
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
              'Mission Assignment',
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
                  Text('Total Items Allocated:', style: GoogleFonts.inter(fontSize: 16, color: Colors.black54)),
                  const SizedBox(height: 8),
                  Text('$assigned Units', style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal)),
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
              child: Text('Accept Assignment', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
            ).animate().fadeIn(delay: 400.ms).moveY(begin: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildReportView(DailyInventory inventory, List todaysDistributions) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Inventory Itemization', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textCharcoal)),
          const SizedBox(height: 16),
          
          ...inventory.items.map((item) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.name, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20, color: AppTheme.primaryTeal),
                        onPressed: () => _handleReturn(item),
                      )
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                       _buildItemMetric('Assigned', item.assigned.toString()),
                       _buildItemMetric('Distributed', item.distributed.toString()),
                       _buildItemMetric('Remaining', (item.assigned - item.distributed - item.returned).toString()),
                       _buildItemMetric('Returning', item.returned.toString(), color: AppTheme.accentTerracotta),
                    ],
                  )
                ],
              ),
            ),
          )),

          const SizedBox(height: 32),
          
          Text(
            'Recent Logs',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textCharcoal),
          ),
          const SizedBox(height: 16),
          
          if (todaysDistributions.isEmpty)
             Center(child: Text('No activity today.', style: GoogleFonts.inter(color: Colors.black54)))
          else
            ...todaysDistributions.reversed.take(5).map((log) => ListTile(
              title: Text('Distributed to ${log.beneficiaryId.substring(0, 8)}...'),
              subtitle: Text(log.aidType),
              trailing: const Icon(Icons.check_circle, color: AppTheme.statusSuccess),
            )),

          const SizedBox(height: 48),
          
          if (inventory.status == InventoryStatus.reconciling || inventory.status == InventoryStatus.completed)
             Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.statusSuccess.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.statusSuccess),
              ),
              child: Column(
                children: [
                  const Icon(Icons.verified, size: 48, color: AppTheme.statusSuccess),
                  const SizedBox(height: 12),
                  Text(
                    'Mission Finalized',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Your data is being audited for inventory clearance.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemMetric(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.black54)),
      ],
    );
  }

  void _showReconciliationDialog(DailyInventory inventory) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reconcile & Finish', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Confirm total return of stock: ${inventory.totalReturned} across ${inventory.items.length} items?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(networkProvider.notifier).reconcileMission();
            },
            child: const Text('Finish Mission'),
          ),
        ],
      ),
    );
  }
}
