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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withValues(alpha: 0.08),
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
                Container(width: 1, height: 40, color: Colors.grey.shade200),
                Expanded(
                  child: _buildFlowMetric(
                    context,
                    label: '心流次数',
                    value: '$flowSessionCount',
                    color: Colors.deepPurple.shade500,
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade200),
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
                      Container(
                        height: h,
                        decoration: BoxDecoration(
                          color: min > 0
                              ? Colors.purple.withValues(alpha: 0.4 + 0.3 * (min / maxHeight))
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
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

    if (activeCategories.length < 3) {
      // 雷达图至少需要3个维度
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              const Text(
                '技能雷达',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Icon(
                Icons.radar_rounded,
                size: 48,
                color: AppTheme.textHint.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                '至少添加3个不同分类的技能\n才能解锁雷达图',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textHint,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ).animate(delay: 400.ms).fadeIn();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '技能雷达',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '各分类技能的平均熟练度',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textHint,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 260,
              child: RadarChart(
                RadarChartData(
                  radarShape: RadarShape.polygon,
                  radarBorderData: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                  gridBorderData: BorderSide(
                    color: Colors.grey.shade200,
                    width: 0.5,
                  ),
                  tickBorderData: const BorderSide(color: Colors.transparent),
                  tickCount: 4,
                  ticksTextStyle: TextStyle(
                    fontSize: 9,
                    color: AppTheme.textHint.withValues(alpha: 0.5),
                  ),
                  titlePositionPercentageOffset: 0.2,
                  titleTextStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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
                      fillColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                      borderColor: AppTheme.primaryColor,
                      borderWidth: 2,
                      entryRadius: 4,
                      dataEntries: activeCategories.map((cat) {
                        return RadarEntry(value: categoryProf[cat]!);
                      }).toList(),
                    ),
                  ],
                  radarBackgroundColor: Colors.transparent,
                ),
              ),
            ),
            // 图例
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: activeCategories.map((cat) {
                final prof = categoryProf[cat]!;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: cat.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${cat.displayName} ${prof.toInt()}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildHeatMap(BuildContext context, SkillService service) {
    final heatMap = service.practiceHeatMap;
    final now = DateTime.now();
    
    // 显示最近12周的数据
    const weeks = 12;
    final startDate = now.subtract(const Duration(days: weeks * 7));

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '打卡热力图',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '最近$weeks周',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textHint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 星期标签
            Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Column(
                    children: ['一', '三', '五', '日'].map((d) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: SizedBox(
                          height: 14,
                          child: Text(
                            d,
                            style: TextStyle(
                              fontSize: 9,
                              color: AppTheme.textHint,
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
                      children: List.generate(weeks, (weekIndex) {
                        return Column(
                          children: List.generate(7, (dayIndex) {
                            final date = startDate.add(Duration(days: weekIndex * 7 + dayIndex));
                            final dateKey = DateTime(date.year, date.month, date.day);
                            final count = heatMap[dateKey] ?? 0;
                            final isAfterToday = date.isAfter(now);
                            
                            return Padding(
                              padding: const EdgeInsets.all(1.5),
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: isAfterToday 
                                      ? Colors.transparent
                                      : _getHeatColor(count),
                                  borderRadius: BorderRadius.circular(3),
                                  border: isAfterToday ? Border.all(
                                    color: Colors.grey.shade200,
                                    width: 0.5,
                                  ) : null,
                                ),
                              ),
                            );
                          }),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 图例
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '少',
                  style: TextStyle(fontSize: 10, color: AppTheme.textHint),
                ),
                const SizedBox(width: 4),
                ...[0, 1, 2, 3].map((level) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getHeatColor(level),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 4),
                Text(
                  '多',
                  style: TextStyle(fontSize: 10, color: AppTheme.textHint),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.1, end: 0);
  }

  Color _getHeatColor(int count) {
    if (count <= 0) return Colors.grey.shade100;
    if (count == 1) return AppTheme.primaryColor.withValues(alpha: 0.3);
    if (count == 2) return AppTheme.primaryColor.withValues(alpha: 0.6);
    return AppTheme.primaryColor;
  }

  Widget _buildCategoryBreakdown(BuildContext context, SkillService service) {
    if (service.skills.isEmpty) return const SizedBox.shrink();
    
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
          color: Colors.white,
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
