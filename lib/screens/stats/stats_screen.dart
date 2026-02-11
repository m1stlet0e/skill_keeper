import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/skill.dart';
import '../../services/skill_service.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradientFor(context),
        ),
        child: SafeArea(
          child: Consumer<SkillService>(
            builder: (context, service, _) {
              if (service.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                );
              }

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildTitle(context)),
                  SliverToBoxAdapter(child: _buildOverviewCards(context, service)),
                  SliverToBoxAdapter(child: _buildFlowStats(context, service)),
                  SliverToBoxAdapter(child: _buildRadarChart(context, service)),
                  SliverToBoxAdapter(child: _buildHeatMap(context, service)),
                  SliverToBoxAdapter(child: _buildCategoryBreakdown(context, service)),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '数据分析',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
          const SizedBox(height: 4),
          Text(
            '全方位了解你的技能状态',
            style: Theme.of(context).textTheme.bodyMedium,
          ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(BuildContext context, SkillService service) {
    final stats = service.statistics;
    final totalMinutes = stats['totalPracticeMinutes'] as int;
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    final timeStr = hours > 0 ? '${hours}h${mins}m' : '${mins}m';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _OverviewCard(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: const Color(0xFFFF6B6B),
                  title: '${stats['currentStreak']}',
                  subtitle: '连续打卡',
                  gradientColors: const [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OverviewCard(
                  icon: Icons.emoji_events_rounded,
                  iconColor: const Color(0xFFFFB347),
                  title: '${stats['longestStreak']}',
                  subtitle: '最长连续',
                  gradientColors: const [Color(0xFFFFB347), Color(0xFFFFCC70)],
                ),
              ),
            ],
          ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1, end: 0),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _OverviewCard(
                  icon: Icons.timer_rounded,
                  iconColor: const Color(0xFF7ED6DF),
                  title: timeStr,
                  subtitle: '总练习时长',
                  gradientColors: const [Color(0xFF7ED6DF), Color(0xFFA0E6ED)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OverviewCard(
                  icon: Icons.check_circle_rounded,
                  iconColor: const Color(0xFF6BCB77),
                  title: '${stats['totalPracticeCount']}',
                  subtitle: '总练习次数',
                  gradientColors: const [Color(0xFF6BCB77), Color(0xFF8FD99A)],
                ),
              ),
            ],
          ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }

  Widget _buildFlowStats(BuildContext context, SkillService service) {
    // 收集所有练习记录
    final allRecords = <PracticeRecord>[];
    for (final skill in service.skills) {
      allRecords.addAll(skill.practiceHistory);
    }

    if (allRecords.isEmpty) return const SizedBox.shrink();

    // 计算心流相关统计
    int totalFlowMinutes = 0;
    int flowSessionCount = 0;       // 达到心流(>=2)的次数
    int deepFlowCount = 0;          // 达到深度心流(==3)的次数
    double totalFlowMultiplier = 0;
    int flowMultiplierCount = 0;
    final flowStateCounts = [0, 0, 0, 0]; // warmUp, focused, flow, deepFlow

    for (final r in allRecords) {
      if (r.highestFlowState >= 2) {
        flowSessionCount++;
        totalFlowMinutes += r.maxFlowMinutes;
      }
      if (r.highestFlowState == 3) {
        deepFlowCount++;
      }
      if (r.flowMultiplier > 1.0) {
        totalFlowMultiplier += r.flowMultiplier;
        flowMultiplierCount++;
      }
      if (r.highestFlowState >= 0 && r.highestFlowState <= 3) {
        flowStateCounts[r.highestFlowState]++;
      }
    }

    // 如果没有任何心流记录（全部都是旧版预热状态），不展示
    final hasFlowData = flowSessionCount > 0 || flowStateCounts[1] > 0;
    if (!hasFlowData) return const SizedBox.shrink();

    final avgMultiplier = flowMultiplierCount > 0
        ? (totalFlowMultiplier / flowMultiplierCount)
        : 1.0;

    // 找出最常达到的心流状态
    final stateNames = ['预热', '专注', '心流', '深度心流'];
    final stateColors = [
      Colors.blueGrey.shade300,
      Colors.lightBlue.shade400,
      Colors.purple.shade400,
      Colors.deepPurple.shade600,
    ];
    int maxStateIdx = 0;
    for (int i = 1; i < 4; i++) {
      if (flowStateCounts[i] > flowStateCounts[maxStateIdx]) {
        maxStateIdx = i;
      }
    }

    final flowHours = totalFlowMinutes ~/ 60;
    final flowMins = totalFlowMinutes % 60;
    final flowTimeStr = flowHours > 0 ? '${flowHours}h${flowMins}m' : '${flowMins}m';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkSurfaceColor : Colors.white;
    final shadowColor = isDark ? Colors.black.withValues(alpha: 0.25) : Colors.deepPurple.withValues(alpha: 0.08);
    final dividerColor = isDark ? Colors.white12 : Colors.grey.shade200;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade400, Colors.deepPurple.shade600],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.stream_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  '心流统计',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 核心指标行
            Row(
              children: [
                Expanded(
                  child: _buildFlowMetric(
                    context,
                    label: '心流总时长',
                    value: flowTimeStr,
                    color: Colors.purple.shade400,
                  ),
                ),
                Container(width: 1, height: 40, color: dividerColor),
                Expanded(
                  child: _buildFlowMetric(
                    context,
                    label: '心流次数',
                    value: '$flowSessionCount',
                    color: Colors.deepPurple.shade500,
                  ),
                ),
                Container(width: 1, height: 40, color: dividerColor),
                Expanded(
                  child: _buildFlowMetric(
                    context,
                    label: '平均倍率',
                    value: 'x${avgMultiplier.toStringAsFixed(1)}',
                    color: Colors.amber.shade700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 心流状态分布条
            const Text(
              '心流状态分布',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 24,
                child: Row(
                  children: List.generate(4, (i) {
                    final total = flowStateCounts.fold<int>(0, (a, b) => a + b);
                    if (total == 0) return const SizedBox.shrink();
                    final ratio = flowStateCounts[i] / total;
                    if (ratio == 0) return const SizedBox.shrink();
                    return Expanded(
                      flex: (ratio * 1000).round().clamp(1, 1000),
                      child: Container(
                        color: stateColors[i],
                        alignment: Alignment.center,
                        child: ratio >= 0.12
                            ? Text(
                                '${(ratio * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 图例
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: List.generate(4, (i) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: stateColors[i],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${stateNames[i]} (${flowStateCounts[i]})',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textHint,
                      ),
                    ),
                  ],
                );
              }),
            ),

            if (deepFlowCount > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.deepPurple.shade400),
                    const SizedBox(width: 8),
                    Text(
                      '你已达到深度心流 $deepFlowCount 次，继续保持!',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.deepPurple.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 最近 8 周心流时长趋势
            _buildWeeklyFlowTrend(context, service),
          ],
        ),
      ),
    ).animate(delay: 350.ms).fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildWeeklyFlowTrend(BuildContext context, SkillService service) {
    final weekly = service.getWeeklyFlowMinutes();
    final maxMin = weekly.isEmpty ? 1 : weekly.reduce((a, b) => a > b ? a : b);
    final maxHeight = maxMin > 0 ? maxMin.toDouble() : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          '最近 8 周心流时长',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(8, (i) {
              final min = weekly[i];
              final h = maxHeight > 0 ? (min / maxHeight * 64).clamp(4.0, 64.0) : 4.0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        min > 0 ? '$min' : '',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppTheme.textHint,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Builder(
                        builder: (context) {
                          final isDark = Theme.of(context).brightness == Brightness.dark;
                          final emptyColor = isDark ? Colors.white12 : Colors.grey.shade200;
                          return Container(
                            height: h,
                            decoration: BoxDecoration(
                              color: min > 0
                                  ? Colors.purple.withValues(alpha: 0.4 + 0.3 * (min / maxHeight))
                                  : emptyColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text('8周前', style: TextStyle(fontSize: 9, color: AppTheme.textHint)),
            const Spacer(),
            Text('本周', style: TextStyle(fontSize: 9, color: AppTheme.textHint)),
          ],
        ),
      ],
    );
  }

  Widget _buildFlowMetric(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textHint,
          ),
        ),
      ],
    );
  }

  Widget _buildRadarChart(BuildContext context, SkillService service) {
    final categoryProf = service.categoryProficiency;
    final hasData = categoryProf.values.any((v) => v > 0);

    if (!hasData) {
      return const SizedBox.shrink();
    }

    // 只展示有数据的分类
    final activeCategories = SkillCategory.values
        .where((c) => categoryProf[c]! > 0)
        .toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkSurfaceColor : Colors.white;

    if (activeCategories.length < 3) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                '技能雷达',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Icon(
                Icons.radar_rounded,
                size: 40,
                color: AppTheme.textHint.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 8),
              Text(
                '至少 3 个不同分类的技能后可显示',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textHint,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ).animate(delay: 400.ms).fadeIn();
    }

    // 参考能力雷达图：六边形网格、三层同心浅灰环、轴标签外置、半透明填充+描边、图例右上角
    final axisColor = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.grey.shade700;
    final ringColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.grey.shade300;
    final ringBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade400;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '技能雷达',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '各分类平均熟练度',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textHint,
              ),
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.topRight,
              children: [
                SizedBox(
                  height: 260,
                  child: RadarChart(
                    RadarChartData(
                      radarShape: RadarShape.polygon,
                      radarBorderData: BorderSide(
                        color: axisColor,
                        width: 1.2,
                      ),
                      gridBorderData: BorderSide(
                        color: ringColor,
                        width: 0.8,
                      ),
                      tickBorderData: BorderSide(
                        color: ringBorder,
                        width: 0.5,
                      ),
                      tickCount: 3,
                      ticksTextStyle: TextStyle(
                        fontSize: 9,
                        color: Colors.transparent,
                      ),
                      titlePositionPercentageOffset: 0.22,
                      titleTextStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                      getTitle: (index, angle) {
                        final cat = activeCategories[index];
                        return RadarChartTitle(
                          text: cat.displayName,
                          angle: 0,
                        );
                      },
                      dataSets: [
                        RadarDataSet(
                          fillColor: AppTheme.primaryColor.withValues(alpha: 0.25),
                          borderColor: AppTheme.primaryColor,
                          borderWidth: 2,
                          entryRadius: 2,
                          dataEntries: activeCategories.map((cat) {
                            return RadarEntry(value: categoryProf[cat]!);
                          }).toList(),
                        ),
                      ],
                      radarBackgroundColor: Colors.transparent,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: activeCategories.map((cat) {
                      final prof = categoryProf[cat]!;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: cat.color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${cat.displayName} ${prof.toInt()}%',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.05, end: 0);
  }

  /// 打卡热力图：按月份展示，每行一月、31 格为日 1–31
  Widget _buildHeatMap(BuildContext context, SkillService service) {
    final heatMap = service.practiceHeatMap;
    final now = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkSurfaceColor : Colors.white;
    final emptyColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.grey.shade200;

    const monthsCount = 12;
    const cellSize = 10.0;
    const cellGap = 1.5;

    // 最近 12 个月：当前月、上月、…
    final months = List.generate(monthsCount, (i) {
      final d = DateTime(now.year, now.month - i, 1);
      return DateTime(d.year, d.month);
    });

    int lastDayOfMonth(int y, int m) {
      return DateTime(y, m + 1, 0).day;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '打卡热力图',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '按月份',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textHint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 32,
                  child: Column(
                    children: months.asMap().entries.map((e) {
                      final i = e.key;
                      final monthDate = e.value;
                      final label = i == 0
                          ? '本月'
                          : monthDate.year != now.year
                              ? '${monthDate.month}月'
                              : '${monthDate.month}月';
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: i < monthsCount - 1 ? cellGap : 0,
                        ),
                        child: SizedBox(
                          height: cellSize,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 9,
                                color: AppTheme.textHint,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(31, (dayCol) {
                        final day = dayCol + 1;
                        return Padding(
                          padding: EdgeInsets.only(
                            right: dayCol < 30 ? cellGap : 0,
                          ),
                          child: Column(
                            children: months.asMap().entries.map((e) {
                              final monthDate = e.value;
                              final y = monthDate.year;
                              final m = monthDate.month;
                              final lastDay = lastDayOfMonth(y, m);
                              final invalidDay = day > lastDay;
                              final date = DateTime(y, m, day);
                              final isFuture = date.isAfter(now);
                              final dateKey = DateTime(y, m, day);
                              final count = invalidDay ? 0 : (heatMap[dateKey] ?? 0);

                              Color cellColor;
                              if (invalidDay || isFuture) {
                                cellColor = emptyColor.withValues(alpha: 0.5);
                              } else {
                                cellColor = _getHeatColor(context, count);
                              }

                              return Padding(
                                padding: EdgeInsets.only(bottom: cellGap),
                                child: Container(
                                  width: cellSize,
                                  height: cellSize,
                                  decoration: BoxDecoration(
                                    color: cellColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '少',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textHint,
                  ),
                ),
                const SizedBox(width: 4),
                ...List.generate(4, (i) => Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _getHeatColor(context, i),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
                const SizedBox(width: 4),
                Text(
                  '多',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textHint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.05, end: 0);
  }

  Color _getHeatColor(BuildContext context, int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (count <= 0) {
      return isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.grey.shade100;
    }
    if (count == 1) {
      return AppTheme.primaryColor.withValues(alpha: 0.35);
    }
    if (count == 2) {
      return AppTheme.primaryColor.withValues(alpha: 0.65);
    }
    return AppTheme.primaryColor;
  }

  Widget _buildCategoryBreakdown(BuildContext context, SkillService service) {
    if (service.skills.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkSurfaceColor : Colors.white;

    final categoryMap = <SkillCategory, List<Skill>>{};
    for (final skill in service.skills) {
      categoryMap.putIfAbsent(skill.category, () => []);
      categoryMap[skill.category]!.add(skill);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '分类详情',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...categoryMap.entries.map((entry) {
              final category = entry.key;
              final skills = entry.value;
              final avgProf = skills.fold<double>(
                0, (sum, s) => sum + s.currentProficiency) / skills.length;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        category.icon,
                        color: category.color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                category.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                '${avgProf.toInt()}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: category.color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: avgProf / 100,
                              backgroundColor: category.color.withValues(alpha: 0.15),
                              color: category.color,
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${skills.length}个技能: ${skills.map((s) => s.name).join("、")}',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textHint,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.1, end: 0);
  }
}

class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;

  const _OverviewCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: gradientColors[0],
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textHint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
