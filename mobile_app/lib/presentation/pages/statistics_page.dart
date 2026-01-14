import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/entities/shot_type.dart';
import '../../domain/entities/usage_statistics.dart';
import '../bloc/usage_statistics/usage_statistics_bloc.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
  }

  void _loadInitialData() {
    context.read<UsageStatisticsBloc>()
        .add(LoadDailyStatistics(DateTime.now()));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.statistics),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            if (index == 0) {
              context.read<UsageStatisticsBloc>()
                  .add(LoadDailyStatistics(DateTime.now()));
            } else if (index == 1) {
              final now = DateTime.now();
              final weekStart = now.subtract(Duration(days: now.weekday - 1));
              context.read<UsageStatisticsBloc>()
                  .add(LoadWeeklyStatistics(weekStart));
            } else if (index == 2) {
              final now = DateTime.now();
              context.read<UsageStatisticsBloc>()
                  .add(LoadMonthlyStatistics(now.year, now.month));
            }
          },
          tabs: [
            Tab(text: l10n.daily),
            Tab(text: l10n.weekly),
            Tab(text: l10n.monthly),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _DailyStatisticsView(),
          _WeeklyStatisticsView(),
          _MonthlyStatisticsView(),
        ],
      ),
    );
  }
}

class _DailyStatisticsView extends StatelessWidget {
  const _DailyStatisticsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<UsageStatisticsBloc, UsageStatisticsState>(
      builder: (context, state) {
        if (state is UsageStatisticsLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is UsageStatisticsLoaded) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(l10n.dailyUsageTime, state.statistics, l10n),
                const SizedBox(height: 16),
                _buildPieChartCard(l10n.usageByType, state.statistics, l10n),
                const SizedBox(height: 16),
                _buildUsageByTypeCard(l10n.details, state.statistics, l10n),
              ],
            ),
          );
        } else if (state is UsageStatisticsError) {
          return Center(
            child: Text(l10n.error(state.message)),
          );
        }
        return Center(child: Text(l10n.noUsageData));
      },
    );
  }

  Widget _buildSummaryCard(String title, UsageStatistics statistics, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '${statistics.totalUsageMinutes} ${l10n.minutes}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartCard(String title, UsageStatistics statistics, AppLocalizations l10n) {
    final hasData = statistics.usageByShot.values.any((v) => v > 0);

    if (!hasData) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              Center(child: Text(l10n.noUsageData)),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildPieChartSections(statistics),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(statistics),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(UsageStatistics statistics) {
    final colors = {
      ShotType.uShot: Colors.blue,
      ShotType.eShot: Colors.orange,
      ShotType.ledCare: Colors.green,
    };

    final sections = <PieChartSectionData>[];
    final total = statistics.usageByShot.values.fold(0, (a, b) => a + b);

    statistics.usageByShot.forEach((type, minutes) {
      if (minutes > 0 && type != ShotType.unknown) {
        final percentage = (minutes / total * 100).round();
        sections.add(
          PieChartSectionData(
            color: colors[type] ?? Colors.grey,
            value: minutes.toDouble(),
            title: '$percentage%',
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }
    });

    return sections;
  }

  Widget _buildLegend(UsageStatistics statistics) {
    final colors = {
      ShotType.uShot: Colors.blue,
      ShotType.eShot: Colors.orange,
      ShotType.ledCare: Colors.green,
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: statistics.usageByShot.entries
          .where((e) => e.value > 0 && e.key != ShotType.unknown)
          .map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colors[entry.key] ?? Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(entry.key.displayName),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUsageByTypeCard(String title, UsageStatistics statistics, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...statistics.usageByShot.entries
                .where((e) => e.key != ShotType.unknown)
                .map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key.displayName),
                    Text('${entry.value} ${l10n.minutes}'),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _WeeklyStatisticsView extends StatelessWidget {
  const _WeeklyStatisticsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<UsageStatisticsBloc, UsageStatisticsState>(
      builder: (context, state) {
        if (state is UsageStatisticsLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is UsageStatisticsLoaded) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWeeklySummaryCard(l10n.weeklyUsageTime, state.statistics, l10n),
                const SizedBox(height: 16),
                _buildBarChartCard(l10n.dailyUsage, state.statistics, state.dailyUsages, l10n),
                const SizedBox(height: 16),
                _buildPieChartCard(l10n.usageByType, state.statistics, l10n),
              ],
            ),
          );
        } else if (state is UsageStatisticsError) {
          return Center(child: Text(l10n.error(state.message)));
        }
        return Center(child: Text(l10n.noUsageData));
      },
    );
  }

  Widget _buildWeeklySummaryCard(String title, UsageStatistics statistics, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '${statistics.totalUsageMinutes} ${l10n.minutes}',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${l10n.average}: ${(statistics.totalUsageMinutes / 7).round()} ${l10n.minutesPerDay}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartCard(String title, UsageStatistics statistics, List<DailyUsage>? dailyUsages, AppLocalizations l10n) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Calculate max Y based on actual data
    double maxY = 60.0;
    if (dailyUsages != null && dailyUsages.isNotEmpty) {
      final maxUsage = dailyUsages.map((d) => d.usageMinutes).reduce((a, b) => a > b ? a : b);
      maxY = maxUsage > 0 ? (maxUsage * 1.2).ceilToDouble() : 60.0;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < days.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(days[index], style: const TextStyle(fontSize: 10)),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}m', style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (index) {
                    final usageMinutes = (dailyUsages != null && index < dailyUsages.length)
                        ? dailyUsages[index].usageMinutes.toDouble()
                        : 0.0;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: usageMinutes,
                          color: Colors.blue,
                          width: 20,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartCard(String title, UsageStatistics statistics, AppLocalizations l10n) {
    final hasData = statistics.usageByShot.values.any((v) => v > 0);

    if (!hasData) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              Center(child: Text(l10n.noUsageData)),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
    }

    final colors = {
      ShotType.uShot: Colors.blue,
      ShotType.eShot: Colors.orange,
      ShotType.ledCare: Colors.green,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: PieChart(
                PieChartData(
                  sections: _buildPieChartSections(statistics, colors),
                  centerSpaceRadius: 30,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildLegend(statistics, colors),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(UsageStatistics statistics, Map<ShotType, Color> colors) {
    final sections = <PieChartSectionData>[];
    final total = statistics.usageByShot.values.fold(0, (a, b) => a + b);

    statistics.usageByShot.forEach((type, minutes) {
      if (minutes > 0 && type != ShotType.unknown) {
        final percentage = (minutes / total * 100).round();
        sections.add(
          PieChartSectionData(
            color: colors[type] ?? Colors.grey,
            value: minutes.toDouble(),
            title: '$percentage%',
            radius: 50,
            titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        );
      }
    });
    return sections;
  }

  Widget _buildLegend(UsageStatistics statistics, Map<ShotType, Color> colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: statistics.usageByShot.entries
          .where((e) => e.value > 0 && e.key != ShotType.unknown)
          .map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[entry.key], shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(entry.key.displayName, style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MonthlyStatisticsView extends StatelessWidget {
  const _MonthlyStatisticsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<UsageStatisticsBloc, UsageStatisticsState>(
      builder: (context, state) {
        if (state is UsageStatisticsLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is UsageStatisticsLoaded) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMonthlySummaryCard(l10n.monthlyUsageTime, state.statistics, l10n),
                const SizedBox(height: 16),
                _buildLineChartCard(l10n.usageTrend, state.statistics, state.dailyUsages, l10n),
                const SizedBox(height: 16),
                _buildPieChartCard(l10n.usageByType, state.statistics, l10n),
              ],
            ),
          );
        } else if (state is UsageStatisticsError) {
          return Center(child: Text(l10n.error(state.message)));
        }
        return Center(child: Text(l10n.noUsageData));
      },
    );
  }

  Widget _buildMonthlySummaryCard(String title, UsageStatistics statistics, AppLocalizations l10n) {
    final daysInMonth = DateTime(statistics.endDate.year, statistics.endDate.month + 1, 0).day;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '${statistics.totalUsageMinutes} ${l10n.minutes}',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${l10n.average}: ${(statistics.totalUsageMinutes / daysInMonth).round()} ${l10n.minutesPerDay}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChartCard(String title, UsageStatistics statistics, List<DailyUsage>? dailyUsages, AppLocalizations l10n) {
    final daysInMonth = DateTime(statistics.endDate.year, statistics.endDate.month + 1, 0).day;

    // Calculate max Y based on actual data
    double maxY = 60.0;
    if (dailyUsages != null && dailyUsages.isNotEmpty) {
      final maxUsage = dailyUsages.map((d) => d.usageMinutes).reduce((a, b) => a > b ? a : b);
      maxY = maxUsage > 0 ? (maxUsage * 1.2).ceilToDouble() : 60.0;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 7,
                        getTitlesWidget: (value, meta) {
                          final day = value.toInt() + 1;
                          if (day == 1 || day == 8 || day == 15 || day == 22 || day == 29) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text('$day', style: const TextStyle(fontSize: 10)),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}m', style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (daysInMonth - 1).toDouble(),
                  minY: 0,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(daysInMonth, (index) {
                        final usageMinutes = (dailyUsages != null && index < dailyUsages.length)
                            ? dailyUsages[index].usageMinutes.toDouble()
                            : 0.0;
                        return FlSpot(index.toDouble(), usageMinutes);
                      }),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withAlpha(50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartCard(String title, UsageStatistics statistics, AppLocalizations l10n) {
    final hasData = statistics.usageByShot.values.any((v) => v > 0);

    if (!hasData) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              Center(child: Text(l10n.noUsageData)),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
    }

    final colors = {
      ShotType.uShot: Colors.blue,
      ShotType.eShot: Colors.orange,
      ShotType.ledCare: Colors.green,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: PieChart(
                PieChartData(
                  sections: _buildPieChartSections(statistics, colors),
                  centerSpaceRadius: 30,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildLegend(statistics, colors),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(UsageStatistics statistics, Map<ShotType, Color> colors) {
    final sections = <PieChartSectionData>[];
    final total = statistics.usageByShot.values.fold(0, (a, b) => a + b);

    statistics.usageByShot.forEach((type, minutes) {
      if (minutes > 0 && type != ShotType.unknown) {
        final percentage = (minutes / total * 100).round();
        sections.add(
          PieChartSectionData(
            color: colors[type] ?? Colors.grey,
            value: minutes.toDouble(),
            title: '$percentage%',
            radius: 50,
            titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        );
      }
    });
    return sections;
  }

  Widget _buildLegend(UsageStatistics statistics, Map<ShotType, Color> colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: statistics.usageByShot.entries
          .where((e) => e.value > 0 && e.key != ShotType.unknown)
          .map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[entry.key], shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(entry.key.displayName, style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
