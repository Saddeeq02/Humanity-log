import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../providers/distribution_provider.dart';

class AnalyticsTab extends ConsumerWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distributions = ref.watch(distributionProvider);
    
    // Calculate mock weekly data (last 7 days)
    final now = DateTime.now();
    final Map<int, int> weeklyData = {for (var i = 0; i < 7; i++) i: 0};
    
    for (var d in distributions) {
      final diff = now.difference(d.timestamp).inDays;
      if (diff >= 0 && diff < 7) {
        weeklyData[6 - diff] = (weeklyData[6 - diff] ?? 0) + 1; // 6 is today, 0 is 6 days ago
      }
    }

    final double maxVal = weeklyData.values.fold(0, (max, v) => v > max ? v : max).toDouble();
    final maxY = maxVal < 5 ? 5.0 : (maxVal + 2);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Analytics Overview',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textCharcoal,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 8),
          Text(
            'Your distribution metrics for the last 7 days.',
            style: GoogleFonts.inter(fontSize: 16, color: Colors.black54),
          ).animate().fadeIn(delay: 200.ms),
          
          const SizedBox(height: 32),
          
          Container(
            height: 300,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryTeal.withOpacity(0.08),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Weekly Distributions Out', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 24),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const style = TextStyle(color: Colors.black45, fontWeight: FontWeight.bold, fontSize: 12);
                              final daysAgo = 6 - value.toInt();
                              if (daysAgo == 0) return const Text('Today', style: style);
                              if (daysAgo == 1) return const Text('Yest', style: style);
                              return Text('-$daysAgo', style: style);
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false), // Hide left titles for clean look
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                      barGroups: weeklyData.entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.toDouble(),
                              color: AppTheme.primaryTeal,
                              width: 20,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ).animate().scaleXY(curve: Curves.easeOutBack, duration: 800.ms),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms).moveY(begin: 20, duration: 600.ms),

          const SizedBox(height: 32),

          Text(
            'Recent Logs',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textCharcoal,
            ),
          ).animate().fadeIn(delay: 600.ms),
          const SizedBox(height: 16),

          ...distributions.reversed.take(5).map((log) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.bgOffWhite, width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.statusSuccess.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle, color: AppTheme.statusSuccess),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Aid Delivered', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          'To Beneficiary: ${log.beneficiaryId.substring(0, 8)}...',
                          style: GoogleFonts.inter(color: Colors.black54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                  )
                ],
              ),
            ).animate().fadeIn(delay: 800.ms).moveX(begin: 30, duration: 500.ms);
          }).toList(),
          
          if (distributions.isEmpty)
             Padding(
               padding: const EdgeInsets.all(32.0),
               child: Center(child: Text('No distributions yet.', style: GoogleFonts.inter(color: Colors.black54))),
             ).animate().fadeIn(delay: 600.ms)
        ],
      ),
    );
  }
}
