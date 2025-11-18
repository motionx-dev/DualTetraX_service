import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../l10n/app_localizations.dart';
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
        title: Text(l10n.usageHistory),
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
                _buildUsageByTypeCard(l10n.usageByType, state.statistics, l10n),
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

  Widget _buildSummaryCard(String title, statistics, AppLocalizations l10n) {
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

  Widget _buildUsageByTypeCard(String title, statistics, AppLocalizations l10n) {
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
            ...statistics.usageByShot.entries.map((entry) {
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
            }).toList(),
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

    return Center(
      child: Text(l10n.weeklyStatsComingSoon),
    );
  }
}

class _MonthlyStatisticsView extends StatelessWidget {
  const _MonthlyStatisticsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Text(l10n.monthlyStatsComingSoon),
    );
  }
}
