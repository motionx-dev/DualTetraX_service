import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/entities/shot_type.dart';
import '../../domain/entities/device_mode.dart';
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

/// Date navigation header widget
class _DateNavigationHeader extends StatelessWidget {
  final String displayText;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onTap;
  final bool canGoNext;

  const _DateNavigationHeader({
    required this.displayText,
    required this.onPrevious,
    required this.onNext,
    required this.onTap,
    this.canGoNext = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
          ),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Text(
                displayText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: canGoNext ? onNext : null,
          ),
        ],
      ),
    );
  }
}

/// Format seconds as "X분 Y초" or "Y초" for short durations
String _formatDuration(int seconds, AppLocalizations l10n) {
  if (seconds < 60) {
    return '$seconds${l10n.secondsShort}';
  }
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  if (remainingSeconds == 0) {
    return '$minutes${l10n.minutes}';
  }
  return '$minutes${l10n.minutes} $remainingSeconds${l10n.secondsShort}';
}

/// Colors for U-Shot modes (firmware: GLOW, TONEUP, RENEW, VOLUME)
final Map<DeviceMode, Color> _uShotModeColors = {
  DeviceMode.glow: Colors.blue.shade300,
  DeviceMode.toneup: Colors.blue.shade500,
  DeviceMode.renew: Colors.blue.shade700,
  DeviceMode.volume: Colors.blue.shade900,
};

/// Colors for E-Shot modes (firmware: CLEAN, FIRM, LINE, LIFT)
final Map<DeviceMode, Color> _eShotModeColors = {
  DeviceMode.clean: Colors.orange.shade300,
  DeviceMode.firm: Colors.orange.shade500,
  DeviceMode.line: Colors.orange.shade700,
  DeviceMode.lift: Colors.orange.shade900,
};

class _DailyStatisticsView extends StatefulWidget {
  const _DailyStatisticsView();

  @override
  State<_DailyStatisticsView> createState() => _DailyStatisticsViewState();
}

class _DailyStatisticsViewState extends State<_DailyStatisticsView> {
  late DateTime _selectedDate;
  final _weekdays = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    context.read<UsageStatisticsBloc>().add(LoadDailyStatistics(_selectedDate));
  }

  void _goToPreviousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    _loadData();
  }

  void _goToNextDay() {
    final today = DateTime.now();
    if (_selectedDate.year < today.year ||
        _selectedDate.month < today.month ||
        _selectedDate.day < today.day) {
      setState(() {
        _selectedDate = _selectedDate.add(const Duration(days: 1));
      });
      _loadData();
    }
  }

  bool _canGoNext() {
    final today = DateTime.now();
    return _selectedDate.year < today.year ||
        (_selectedDate.year == today.year && _selectedDate.month < today.month) ||
        (_selectedDate.year == today.year && _selectedDate.month == today.month && _selectedDate.day < today.day);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadData();
    }
  }

  String _formatDateDisplay() {
    final locale = Localizations.localeOf(context).languageCode;
    final weekday = _weekdays[_selectedDate.weekday];
    if (locale == 'ko') {
      return '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일 ($weekday)';
    }
    return '${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day} ($weekday)';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        _DateNavigationHeader(
          displayText: _formatDateDisplay(),
          onPrevious: _goToPreviousDay,
          onNext: _goToNextDay,
          onTap: _pickDate,
          canGoNext: _canGoNext(),
        ),
        Expanded(
          child: BlocBuilder<UsageStatisticsBloc, UsageStatisticsState>(
            buildWhen: (previous, current) => previous.daily != current.daily,
            builder: (context, state) {
              final data = state.daily;
              if (data.isLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (data.error != null) {
                return Center(child: Text(l10n.error(data.error!)));
              } else if (data.statistics != null) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCard(l10n.dailyUsageTime, data.statistics!, l10n),
                      const SizedBox(height: 16),
                      _buildShotTypePieChartCard(l10n.usageByType, data.statistics!, l10n),
                      const SizedBox(height: 16),
                      _buildUShotModePieChartCard(l10n.usageByUShotMode, data.statistics!, l10n),
                      const SizedBox(height: 16),
                      _buildEShotModePieChartCard(l10n.usageByEShotMode, data.statistics!, l10n),
                    ],
                  ),
                );
              }
              return Center(child: Text(l10n.noUsageData));
            },
          ),
        ),
      ],
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
                _formatDuration(statistics.totalUsageSeconds, l10n),
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

  Widget _buildShotTypePieChartCard(String title, UsageStatistics statistics, AppLocalizations l10n) {
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
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildShotTypePieChartSections(statistics, colors),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildShotTypeLegend(statistics, colors, l10n),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildShotTypePieChartSections(UsageStatistics statistics, Map<ShotType, Color> colors) {
    final sections = <PieChartSectionData>[];
    final total = statistics.usageByShot.values.fold(0, (a, b) => a + b);

    statistics.usageByShot.forEach((type, seconds) {
      if (seconds > 0 && type != ShotType.unknown) {
        final percentage = (seconds / total * 100).round();
        sections.add(
          PieChartSectionData(
            color: colors[type] ?? Colors.grey,
            value: seconds.toDouble(),
            title: '$percentage%',
            radius: 60,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        );
      }
    });

    return sections;
  }

  Widget _buildShotTypeLegend(UsageStatistics statistics, Map<ShotType, Color> colors, AppLocalizations l10n) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: statistics.usageByShot.entries
          .where((e) => e.value > 0 && e.key != ShotType.unknown)
          .map((entry) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[entry.key], shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text('${entry.key.displayName} (${_formatDuration(entry.value, l10n)})', style: const TextStyle(fontSize: 12)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildUShotModePieChartCard(String title, UsageStatistics statistics, AppLocalizations l10n) {
    final uShotModes = statistics.usageByMode.entries
        .where((e) => e.key.isUShotMode && e.value > 0)
        .toList();

    if (uShotModes.isEmpty) {
      return const SizedBox.shrink();
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
              height: 180,
              child: PieChart(
                PieChartData(
                  sections: _buildModePieChartSections(uShotModes, _uShotModeColors),
                  centerSpaceRadius: 35,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildModeLegend(uShotModes, _uShotModeColors, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildEShotModePieChartCard(String title, UsageStatistics statistics, AppLocalizations l10n) {
    final eShotModes = statistics.usageByMode.entries
        .where((e) => e.key.isEShotMode && e.value > 0)
        .toList();

    if (eShotModes.isEmpty) {
      return const SizedBox.shrink();
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
              height: 180,
              child: PieChart(
                PieChartData(
                  sections: _buildModePieChartSections(eShotModes, _eShotModeColors),
                  centerSpaceRadius: 35,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildModeLegend(eShotModes, _eShotModeColors, l10n),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildModePieChartSections(
    List<MapEntry<DeviceMode, int>> modes,
    Map<DeviceMode, Color> colors,
  ) {
    final total = modes.fold(0, (sum, e) => sum + e.value);
    return modes.map((entry) {
      final percentage = (entry.value / total * 100).round();
      return PieChartSectionData(
        color: colors[entry.key] ?? Colors.grey,
        value: entry.value.toDouble(),
        title: '${entry.key.shortName}\n$percentage%',
        radius: 55,
        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  Widget _buildModeLegend(
    List<MapEntry<DeviceMode, int>> modes,
    Map<DeviceMode, Color> colors,
    AppLocalizations l10n,
  ) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: modes.map((entry) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[entry.key], shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text('${entry.key.shortName} - ${entry.key.displayName} (${_formatDuration(entry.value, l10n)})', style: const TextStyle(fontSize: 11)),
          ],
        );
      }).toList(),
    );
  }
}

class _WeeklyStatisticsView extends StatefulWidget {
  const _WeeklyStatisticsView();

  @override
  State<_WeeklyStatisticsView> createState() => _WeeklyStatisticsViewState();
}

class _WeeklyStatisticsViewState extends State<_WeeklyStatisticsView> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekStart = now.subtract(Duration(days: now.weekday - 1));
    _weekStart = DateTime(_weekStart.year, _weekStart.month, _weekStart.day);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    context.read<UsageStatisticsBloc>().add(LoadWeeklyStatistics(_weekStart));
  }

  void _goToPreviousWeek() {
    setState(() {
      _weekStart = _weekStart.subtract(const Duration(days: 7));
    });
    _loadData();
  }

  void _goToNextWeek() {
    final today = DateTime.now();
    final currentWeekStart = today.subtract(Duration(days: today.weekday - 1));
    if (_weekStart.isBefore(currentWeekStart)) {
      setState(() {
        _weekStart = _weekStart.add(const Duration(days: 7));
      });
      _loadData();
    }
  }

  bool _canGoNext() {
    final today = DateTime.now();
    final currentWeekStart = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: today.weekday - 1));
    return _weekStart.isBefore(currentWeekStart);
  }

  Future<void> _pickWeek() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _weekStart,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      // Calculate week start (Monday) from picked date
      final newWeekStart = picked.subtract(Duration(days: picked.weekday - 1));
      setState(() {
        _weekStart = DateTime(newWeekStart.year, newWeekStart.month, newWeekStart.day);
      });
      _loadData();
    }
  }

  String _formatWeekDisplay() {
    final locale = Localizations.localeOf(context).languageCode;
    final weekEnd = _weekStart.add(const Duration(days: 6));
    if (locale == 'ko') {
      return '${_weekStart.year}년 ${_weekStart.month}/${_weekStart.day} - ${weekEnd.month}/${weekEnd.day}';
    }
    return '${_weekStart.year} ${_weekStart.month}/${_weekStart.day} - ${weekEnd.month}/${weekEnd.day}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        _DateNavigationHeader(
          displayText: _formatWeekDisplay(),
          onPrevious: _goToPreviousWeek,
          onNext: _goToNextWeek,
          onTap: _pickWeek,
          canGoNext: _canGoNext(),
        ),
        Expanded(
          child: BlocBuilder<UsageStatisticsBloc, UsageStatisticsState>(
            buildWhen: (previous, current) => previous.weekly != current.weekly,
            builder: (context, state) {
              final data = state.weekly;
              if (data.isLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (data.error != null) {
                return Center(child: Text(l10n.error(data.error!)));
              } else if (data.statistics != null) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWeeklySummaryCard(l10n.weeklyUsageTime, data.statistics!, l10n),
                      const SizedBox(height: 16),
                      _buildBarChartCard(l10n.dailyUsage, data.statistics!, data.dailyUsages, l10n),
                      const SizedBox(height: 16),
                      _buildShotTypeBarChartCard(l10n.usageByType, data.dailyUsages, l10n),
                      const SizedBox(height: 16),
                      _buildUShotModePieChartCard(l10n.usageByUShotMode, data.statistics!, l10n),
                      const SizedBox(height: 16),
                      _buildEShotModePieChartCard(l10n.usageByEShotMode, data.statistics!, l10n),
                    ],
                  ),
                );
              }
              return Center(child: Text(l10n.noUsageData));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklySummaryCard(String title, UsageStatistics statistics, AppLocalizations l10n) {
    final avgSecondsPerDay = statistics.totalUsageSeconds ~/ 7;
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
                _formatDuration(statistics.totalUsageSeconds, l10n),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${l10n.average}: ${_formatDuration(avgSecondsPerDay, l10n)}/${l10n.daily}',
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

    // Calculate max Y based on actual data (in minutes for display)
    double maxY = 10.0;
    if (dailyUsages != null && dailyUsages.isNotEmpty) {
      final maxUsage = dailyUsages.map((d) => d.usageSeconds / 60.0).reduce((a, b) => a > b ? a : b);
      maxY = maxUsage > 0 ? (maxUsage * 1.2).ceilToDouble() : 10.0;
    }

    // Check if there are any unsynced sessions
    final hasUnsyncedData = dailyUsages?.any((d) => d.unsyncedSeconds > 0) ?? false;

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
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final dailyUsage = (dailyUsages != null && groupIndex < dailyUsages.length)
                            ? dailyUsages[groupIndex]
                            : null;
                        if (dailyUsage == null) return null;
                        return BarTooltipItem(
                          _formatDuration(dailyUsage.usageSeconds, l10n),
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      },
                    ),
                  ),
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
                    final dailyUsage = (dailyUsages != null && index < dailyUsages.length)
                        ? dailyUsages[index]
                        : null;
                    final syncedMinutes = (dailyUsage?.syncedSeconds ?? 0) / 60.0;
                    final unsyncedMinutes = (dailyUsage?.unsyncedSeconds ?? 0) / 60.0;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: syncedMinutes + unsyncedMinutes,
                          width: 20,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                          rodStackItems: [
                            BarChartRodStackItem(0, syncedMinutes, Colors.blue),
                            BarChartRodStackItem(syncedMinutes, syncedMinutes + unsyncedMinutes, Colors.blue.withAlpha(100)),
                          ],
                          color: Colors.transparent,
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            if (hasUnsyncedData) ...[
              const SizedBox(height: 12),
              _buildTimeSyncLegend(l10n),
              const SizedBox(height: 8),
              Text(
                l10n.unsyncedTimeExplanation,
                style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShotTypeBarChartCard(String title, List<DailyUsage>? dailyUsages, AppLocalizations l10n) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Calculate max Y based on shot type data (in minutes)
    double maxY = 10.0;
    if (dailyUsages != null && dailyUsages.isNotEmpty) {
      double maxUsage = 0;
      for (final daily in dailyUsages) {
        final uShotSeconds = daily.usageByShot[ShotType.uShot] ?? 0;
        final eShotSeconds = daily.usageByShot[ShotType.eShot] ?? 0;
        final maxForDay = (uShotSeconds > eShotSeconds ? uShotSeconds : eShotSeconds) / 60.0;
        if (maxForDay > maxUsage) maxUsage = maxForDay;
      }
      maxY = maxUsage > 0 ? (maxUsage * 1.2).ceilToDouble() : 10.0;
    }

    // Check if there's any data
    final hasData = dailyUsages?.any((d) =>
        (d.usageByShot[ShotType.uShot] ?? 0) > 0 ||
        (d.usageByShot[ShotType.eShot] ?? 0) > 0) ?? false;

    if (!hasData) {
      return const SizedBox.shrink();
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
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final dailyUsage = (dailyUsages != null && groupIndex < dailyUsages.length)
                            ? dailyUsages[groupIndex]
                            : null;
                        if (dailyUsage == null) return null;
                        final isUShot = rodIndex == 0;
                        final seconds = isUShot
                            ? (dailyUsage.usageByShot[ShotType.uShot] ?? 0)
                            : (dailyUsage.usageByShot[ShotType.eShot] ?? 0);
                        final label = isUShot ? 'U-Shot' : 'E-Shot';
                        return BarTooltipItem(
                          '$label: ${_formatDuration(seconds, l10n)}',
                          const TextStyle(color: Colors.white, fontSize: 11),
                        );
                      },
                    ),
                  ),
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
                    final dailyUsage = (dailyUsages != null && index < dailyUsages.length)
                        ? dailyUsages[index]
                        : null;
                    final uShotMinutes = ((dailyUsage?.usageByShot[ShotType.uShot] ?? 0) / 60.0);
                    final eShotMinutes = ((dailyUsage?.usageByShot[ShotType.eShot] ?? 0) / 60.0);

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: uShotMinutes,
                          width: 8,
                          color: Colors.blue,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(3),
                            topRight: Radius.circular(3),
                          ),
                        ),
                        BarChartRodData(
                          toY: eShotMinutes,
                          width: 8,
                          color: Colors.orange,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(3),
                            topRight: Radius.circular(3),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildShotTypeBarLegend(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildShotTypeBarLegend(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(l10n.shotTypeUShot, style: const TextStyle(fontSize: 11)),
        const SizedBox(width: 16),
        Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(l10n.shotTypeEShot, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _buildTimeSyncLegend(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(l10n.syncedUsage, style: const TextStyle(fontSize: 11)),
        const SizedBox(width: 16),
        Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.blue.withAlpha(100), shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(l10n.unsyncedUsage, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _buildUShotModePieChartCard(String title, UsageStatistics statistics, AppLocalizations l10n) {
    final uShotModes = statistics.usageByMode.entries
        .where((e) => e.key.isUShotMode && e.value > 0)
        .toList();

    if (uShotModes.isEmpty) {
      return const SizedBox.shrink();
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
              height: 160,
              child: PieChart(
                PieChartData(
                  sections: _buildModePieChartSections(uShotModes, _uShotModeColors),
                  centerSpaceRadius: 30,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildModeLegend(uShotModes, _uShotModeColors, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildEShotModePieChartCard(String title, UsageStatistics statistics, AppLocalizations l10n) {
    final eShotModes = statistics.usageByMode.entries
        .where((e) => e.key.isEShotMode && e.value > 0)
        .toList();

    if (eShotModes.isEmpty) {
      return const SizedBox.shrink();
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
              height: 160,
              child: PieChart(
                PieChartData(
                  sections: _buildModePieChartSections(eShotModes, _eShotModeColors),
                  centerSpaceRadius: 30,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildModeLegend(eShotModes, _eShotModeColors, l10n),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildModePieChartSections(
    List<MapEntry<DeviceMode, int>> modes,
    Map<DeviceMode, Color> colors,
  ) {
    final total = modes.fold(0, (sum, e) => sum + e.value);
    return modes.map((entry) {
      final percentage = (entry.value / total * 100).round();
      return PieChartSectionData(
        color: colors[entry.key] ?? Colors.grey,
        value: entry.value.toDouble(),
        title: '${entry.key.shortName}\n$percentage%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  Widget _buildModeLegend(
    List<MapEntry<DeviceMode, int>> modes,
    Map<DeviceMode, Color> colors,
    AppLocalizations l10n,
  ) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: modes.map((entry) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[entry.key], shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text('${entry.key.shortName} - ${entry.key.displayName} (${_formatDuration(entry.value, l10n)})', style: const TextStyle(fontSize: 11)),
          ],
        );
      }).toList(),
    );
  }
}

class _MonthlyStatisticsView extends StatefulWidget {
  const _MonthlyStatisticsView();

  @override
  State<_MonthlyStatisticsView> createState() => _MonthlyStatisticsViewState();
}

class _MonthlyStatisticsViewState extends State<_MonthlyStatisticsView> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    context.read<UsageStatisticsBloc>().add(LoadMonthlyStatistics(_selectedYear, _selectedMonth));
  }

  void _goToPreviousMonth() {
    setState(() {
      if (_selectedMonth == 1) {
        _selectedMonth = 12;
        _selectedYear--;
      } else {
        _selectedMonth--;
      }
    });
    _loadData();
  }

  void _goToNextMonth() {
    final now = DateTime.now();
    if (_selectedYear < now.year || (_selectedYear == now.year && _selectedMonth < now.month)) {
      setState(() {
        if (_selectedMonth == 12) {
          _selectedMonth = 1;
          _selectedYear++;
        } else {
          _selectedMonth++;
        }
      });
      _loadData();
    }
  }

  bool _canGoNext() {
    final now = DateTime.now();
    return _selectedYear < now.year || (_selectedYear == now.year && _selectedMonth < now.month);
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_selectedYear, _selectedMonth),
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _selectedYear = picked.year;
        _selectedMonth = picked.month;
      });
      _loadData();
    }
  }

  String _formatMonthDisplay() {
    final locale = Localizations.localeOf(context).languageCode;
    final monthNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (locale == 'ko') {
      return '$_selectedYear년 $_selectedMonth월';
    }
    return '${monthNames[_selectedMonth]} $_selectedYear';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        _DateNavigationHeader(
          displayText: _formatMonthDisplay(),
          onPrevious: _goToPreviousMonth,
          onNext: _goToNextMonth,
          onTap: _pickMonth,
          canGoNext: _canGoNext(),
        ),
        Expanded(
          child: BlocBuilder<UsageStatisticsBloc, UsageStatisticsState>(
            buildWhen: (previous, current) => previous.monthly != current.monthly,
            builder: (context, state) {
              final data = state.monthly;
              if (data.isLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (data.error != null) {
                return Center(child: Text(l10n.error(data.error!)));
              } else if (data.statistics != null) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMonthlySummaryCard(l10n.monthlyUsageTime, data.statistics!, l10n),
                      const SizedBox(height: 16),
                      _buildLineChartCard(l10n.usageTrend, data.statistics!, data.dailyUsages, l10n),
                      const SizedBox(height: 16),
                      _buildShotTypeLineChartCard(l10n.usageByType, data.statistics!, data.dailyUsages, l10n),
                      const SizedBox(height: 16),
                      _buildUShotModePieChartCard(l10n.usageByUShotMode, data.statistics!, l10n),
                      const SizedBox(height: 16),
                      _buildEShotModePieChartCard(l10n.usageByEShotMode, data.statistics!, l10n),
                    ],
                  ),
                );
              }
              return Center(child: Text(l10n.noUsageData));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlySummaryCard(String title, UsageStatistics statistics, AppLocalizations l10n) {
    final daysInMonth = DateTime(statistics.endDate.year, statistics.endDate.month + 1, 0).day;
    final avgSecondsPerDay = statistics.totalUsageSeconds ~/ daysInMonth;

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
                _formatDuration(statistics.totalUsageSeconds, l10n),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${l10n.average}: ${_formatDuration(avgSecondsPerDay, l10n)}/${l10n.daily}',
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

    // Calculate max Y based on actual data (in minutes for display)
    double maxY = 10.0;
    if (dailyUsages != null && dailyUsages.isNotEmpty) {
      final maxUsage = dailyUsages.map((d) => d.usageSeconds / 60.0).reduce((a, b) => a > b ? a : b);
      maxY = maxUsage > 0 ? (maxUsage * 1.2).ceilToDouble() : 10.0;
    }

    // Check if there are any unsynced sessions
    final hasUnsyncedData = dailyUsages?.any((d) => d.unsyncedSeconds > 0) ?? false;

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
                    // Synced usage line
                    LineChartBarData(
                      spots: List.generate(daysInMonth, (index) {
                        final syncedMinutes = (dailyUsages != null && index < dailyUsages.length)
                            ? dailyUsages[index].syncedSeconds / 60.0
                            : 0.0;
                        return FlSpot(index.toDouble(), syncedMinutes);
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
                    // Unsynced usage line (if any)
                    if (hasUnsyncedData)
                      LineChartBarData(
                        spots: List.generate(daysInMonth, (index) {
                          final unsyncedMinutes = (dailyUsages != null && index < dailyUsages.length)
                              ? dailyUsages[index].unsyncedSeconds / 60.0
                              : 0.0;
                          return FlSpot(index.toDouble(), unsyncedMinutes);
                        }),
                        isCurved: true,
                        color: Colors.blue.withAlpha(100),
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        dashArray: [5, 5],
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blue.withAlpha(25),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (hasUnsyncedData) ...[
              const SizedBox(height: 12),
              _buildTimeSyncLegendMonthly(l10n),
              const SizedBox(height: 8),
              Text(
                l10n.unsyncedTimeExplanation,
                style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShotTypeLineChartCard(String title, UsageStatistics statistics, List<DailyUsage>? dailyUsages, AppLocalizations l10n) {
    final daysInMonth = DateTime(statistics.endDate.year, statistics.endDate.month + 1, 0).day;

    // Calculate max Y based on shot type data (in minutes)
    double maxY = 10.0;
    if (dailyUsages != null && dailyUsages.isNotEmpty) {
      double maxUsage = 0;
      for (final daily in dailyUsages) {
        final uShotMinutes = (daily.usageByShot[ShotType.uShot] ?? 0) / 60.0;
        final eShotMinutes = (daily.usageByShot[ShotType.eShot] ?? 0) / 60.0;
        final maxForDay = uShotMinutes > eShotMinutes ? uShotMinutes : eShotMinutes;
        if (maxForDay > maxUsage) maxUsage = maxForDay;
      }
      maxY = maxUsage > 0 ? (maxUsage * 1.2).ceilToDouble() : 10.0;
    }

    // Check if there's any data
    final hasData = dailyUsages?.any((d) =>
        (d.usageByShot[ShotType.uShot] ?? 0) > 0 ||
        (d.usageByShot[ShotType.eShot] ?? 0) > 0) ?? false;

    if (!hasData) {
      return const SizedBox.shrink();
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
                    // U-Shot line
                    LineChartBarData(
                      spots: List.generate(daysInMonth, (index) {
                        final uShotMinutes = (dailyUsages != null && index < dailyUsages.length)
                            ? (dailyUsages[index].usageByShot[ShotType.uShot] ?? 0) / 60.0
                            : 0.0;
                        return FlSpot(index.toDouble(), uShotMinutes);
                      }),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withAlpha(30),
                      ),
                    ),
                    // E-Shot line
                    LineChartBarData(
                      spots: List.generate(daysInMonth, (index) {
                        final eShotMinutes = (dailyUsages != null && index < dailyUsages.length)
                            ? (dailyUsages[index].usageByShot[ShotType.eShot] ?? 0) / 60.0
                            : 0.0;
                        return FlSpot(index.toDouble(), eShotMinutes);
                      }),
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.orange.withAlpha(30),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildShotTypeLineLegend(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildShotTypeLineLegend(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 20, height: 2, color: Colors.blue),
        const SizedBox(width: 4),
        Text(l10n.shotTypeUShot, style: const TextStyle(fontSize: 11)),
        const SizedBox(width: 16),
        Container(width: 20, height: 2, color: Colors.orange),
        const SizedBox(width: 4),
        Text(l10n.shotTypeEShot, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _buildTimeSyncLegendMonthly(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 20, height: 2, color: Colors.blue),
        const SizedBox(width: 4),
        Text(l10n.syncedUsage, style: const TextStyle(fontSize: 11)),
        const SizedBox(width: 16),
        Container(width: 20, height: 2, color: Colors.blue.withAlpha(100)),
        const SizedBox(width: 4),
        Text(l10n.unsyncedUsage, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _buildUShotModePieChartCard(String title, UsageStatistics statistics, AppLocalizations l10n) {
    final uShotModes = statistics.usageByMode.entries
        .where((e) => e.key.isUShotMode && e.value > 0)
        .toList();

    if (uShotModes.isEmpty) {
      return const SizedBox.shrink();
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
              height: 160,
              child: PieChart(
                PieChartData(
                  sections: _buildModePieChartSections(uShotModes, _uShotModeColors),
                  centerSpaceRadius: 30,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildModeLegend(uShotModes, _uShotModeColors, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildEShotModePieChartCard(String title, UsageStatistics statistics, AppLocalizations l10n) {
    final eShotModes = statistics.usageByMode.entries
        .where((e) => e.key.isEShotMode && e.value > 0)
        .toList();

    if (eShotModes.isEmpty) {
      return const SizedBox.shrink();
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
              height: 160,
              child: PieChart(
                PieChartData(
                  sections: _buildModePieChartSections(eShotModes, _eShotModeColors),
                  centerSpaceRadius: 30,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildModeLegend(eShotModes, _eShotModeColors, l10n),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildModePieChartSections(
    List<MapEntry<DeviceMode, int>> modes,
    Map<DeviceMode, Color> colors,
  ) {
    final total = modes.fold(0, (sum, e) => sum + e.value);
    return modes.map((entry) {
      final percentage = (entry.value / total * 100).round();
      return PieChartSectionData(
        color: colors[entry.key] ?? Colors.grey,
        value: entry.value.toDouble(),
        title: '${entry.key.shortName}\n$percentage%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  Widget _buildModeLegend(
    List<MapEntry<DeviceMode, int>> modes,
    Map<DeviceMode, Color> colors,
    AppLocalizations l10n,
  ) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: modes.map((entry) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[entry.key], shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text('${entry.key.shortName} - ${entry.key.displayName} (${_formatDuration(entry.value, l10n)})', style: const TextStyle(fontSize: 11)),
          ],
        );
      }).toList(),
    );
  }
}
