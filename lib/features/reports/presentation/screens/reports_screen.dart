import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/firebase_service.dart';

final reportStatsProvider = FutureProvider<Map<String,dynamic>>(
  (ref) => ref.read(firebaseServiceProvider).getDashboardStats());

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(reportStatsProvider);
    final fmt = NumberFormat('#,##0.##', 'ar');
    return Scaffold(
      appBar: AppBar(title: const Text('التقارير')),
      body: stats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e,_) => Center(child: Text('خطأ: $e')),
        data: (d) => ListView(padding: const EdgeInsets.all(16), children: [
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _ReportCard(icon: '💰', label: 'المقبوضات',
                value: fmt.format(d['totalCollected'] ?? 0) + ' ر.س', color: AppColors.accent),
              _ReportCard(icon: '📋', label: 'الديون',
                value: fmt.format(d['totalDebtAmount'] ?? 0) + ' ر.س', color: AppColors.primaryLight),
              _ReportCard(icon: '⚠️', label: 'المتأخرات',
                value: fmt.format(d['totalOverdue'] ?? 0) + ' ر.س', color: AppColors.danger),
              _ReportCard(icon: '👥', label: 'العملاء',
                value: (d['totalCustomers'] ?? 0).toString(), color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 20),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('الأرباح الشهرية',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 16),
              SizedBox(height: 160, child: BarChart(BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 20000,
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, m) {
                      const labels = ['يناير','فبراير','مارس','أبريل','مايو','يونيو'];
                      final idx = v.toInt();
                      if (idx < 0 || idx >= labels.length) return const SizedBox();
                      return Text(labels[idx], style: const TextStyle(fontSize: 9));
                    },
                  )),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [8000,12000,9000,15000,11000,18000].asMap().entries.map((e) =>
                  BarChartGroupData(x: e.key, barRods: [
                    BarChartRodData(
                      toY: e.value.toDouble(),
                      color: AppColors.primaryLight,
                      width: 22,
                      borderRadius: BorderRadius.circular(6),
                    )
                  ])).toList(),
              ))),
            ],
          ))),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String icon, label, value;
  final Color color;
  const _ReportCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 28)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    )),
  );
}
