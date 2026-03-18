
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/firebase_service.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(FutureProvider((r) => r.read(firebaseServiceProvider).getDashboardStats()).future as ProviderListenable);
    final fmt = NumberFormat('#,##0.##', 'ar');
    return Scaffold(
      appBar: AppBar(title: const Text('التقارير')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        GridView.count(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: [
          _Card('💰', 'المقبوضات', '84,500 ر.س', AppColors.accent),
          _Card('📋', 'الديون', '156,000 ر.س', AppColors.primaryLight),
          _Card('⚠️', 'المتأخرات', '18,200 ر.س', AppColors.danger),
          _Card('🔄', 'الاشتراكات', '14,876 ر.س', AppColors.warning),
        ]),
        const SizedBox(height: 20),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('الأرباح الشهرية', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 16),
          SizedBox(height: 160, child: BarChart(BarChartData(
            alignment: BarChartAlignment.spaceAround, maxY: 20000,
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) => Text(['يناير','فبراير','مارس','أبريل','مايو','يونيو'][v.toInt()], style: const TextStyle(fontSize: 9)))),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: [8000,12000,9000,15000,11000,18000].asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: e.value.toDouble(), color: AppColors.primaryLight, width: 22, borderRadius: BorderRadius.circular(6))])).toList(),
          ))),
        ]))),
        const SizedBox(height: 80),
      ]),
    );
  }
  Widget _Card(String icon, String label, String value, Color color) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(icon, style: const TextStyle(fontSize: 28)),
    const Spacer(),
    Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
    Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
  ])));
}
