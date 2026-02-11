import 'package:flutter/material.dart';
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
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _HeroSection(service: service)),
                  SliverToBoxAdapter(child: _ThisWeekStrip(service: service)),
                  SliverToBoxAdapter(child: _RecentActivity(service: service)),
                  SliverToBoxAdapter(child: _SkillsGlance(service: service)),
                  SliverToBoxAdapter(child: _PracticeCalendar(service: service)),
                  SliverToBoxAdapter(child: _BottomStats(service: service)),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 顶部：一个核心数字 + 一句话
class _HeroSection extends StatelessWidget {
  final SkillService service;

  const _HeroSection({required this.service});

  @override
  Widget build(BuildContext context) {
    final streak = service.currentStreak;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$streak',
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.w800,
              height: 0.95,
              letterSpacing: -3,
              color: AppTheme.primaryColor,
              shadows: isDark
                  ? null
                  : [
                      Shadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.25),
                        offset: const Offset(0, 4),
                        blurRadius: 12,
                      ),
                    ],
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1), curve: Curves.easeOutBack),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '天连续打卡',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 450.ms, delay: 120.ms)
              .slideX(begin: -0.05, end: 0, curve: Curves.easeOutCubic),
          const SizedBox(height: 8),
          Text(
            streak > 0 ? '保持练习，技能不生锈' : '开始练习，点亮第一天',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          )
              .animate()
              .fadeIn(duration: 450.ms, delay: 200.ms)
              .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }
}

/// 本周练习：一周 7 天，每天一格显示练习次数
class _ThisWeekStrip extends StatelessWidget {
  final SkillService service;

  const _ThisWeekStrip({required this.service});

  @override
  Widget build(BuildContext context) {
    final heatMap = service.practiceHeatMap;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // 本周一
    final weekStart = today.subtract(Duration(days: now.weekday - 1));
    const days = ['一', '二', '三', '四', '五', '六', '日'];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkSurfaceColor : Colors.white;

    int countForDay(int dayOffset) {
      final d = weekStart.add(Duration(days: dayOffset));
      final key = DateTime(d.year, d.month, d.day);
      return heatMap[key] ?? 0;
    }

    final maxCount = List.generate(7, (i) => countForDay(i)).fold<int>(0, (a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '本周练习',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: List.generate(7, (i) {
                final c = countForDay(i);
                final isToday = (weekStart.add(Duration(days: i))).isAtSameMomentAs(today);
                final h = maxCount > 0 ? 4.0 + 36.0 * (c / maxCount) : 4.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          days[i],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                            color: isToday ? AppTheme.primaryColor : AppTheme.textHint,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: h.clamp(4.0, 40.0),
                          decoration: BoxDecoration(
                            color: c > 0
                                ? AppTheme.primaryColor.withValues(alpha: 0.3 + 0.5 * (maxCount > 0 ? c / maxCount : 0))
                                : (isDark ? Colors.white12 : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        )
                            .animate()
                            .scaleY(begin: 0, end: 1, duration: 500.ms, delay: (300 + i * 50).ms, curve: Curves.easeOutCubic),
                        if (c > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            '$c',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 450.ms, delay: 250.ms)
        .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
  }
}

/// 最近练习记录：技能名 + 时长 + 相对时间
class _RecentActivity extends StatelessWidget {
  final SkillService service;

  const _RecentActivity({required this.service});

  @override
  Widget build(BuildContext context) {
    final list = <({PracticeRecord record, Skill skill})>[];
    for (final skill in service.skills) {
      for (final r in skill.practiceHistory) {
        list.add((record: r, skill: skill));
      }
    }
    list.sort((a, b) => b.record.date.compareTo(a.record.date));
    final recent = list.take(8).toList();
    if (recent.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkSurfaceColor : Colors.white;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '最近练习',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                children: recent.asMap().entries.map((e) {
                  final i = e.key;
                  final item = e.value;
                  final r = item.record;
                  final s = item.skill;
                  final rel = _relativeTime(r.date);
                  final hasFlow = r.flowMultiplier > 1.0;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: i < recent.length - 1
                          ? Border(
                              bottom: BorderSide(
                                color: isDark ? Colors.white12 : Colors.grey.shade200,
                                width: 1,
                              ),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: s.category.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(s.category.icon, color: s.category.color, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                rel,
                                style: TextStyle(fontSize: 12, color: AppTheme.textHint),
                              ),
                            ],
                          ),
                        ),
                        if (hasFlow)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.water_drop_rounded,
                              size: 16,
                              color: Colors.purple.shade400,
                            ),
                          ),
                        Text(
                          '${r.durationMinutes} 分钟',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 350.ms, delay: (350 + i * 60).ms)
                      .slideX(begin: 0.04, end: 0, curve: Curves.easeOutCubic);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 450.ms, delay: 320.ms)
        .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
  }

  String _relativeTime(DateTime date) {
    final now = DateTime.now();
    final d = DateTime(date.year, date.month, date.day);
    final t = DateTime(now.year, now.month, now.day);
    final diff = t.difference(d).inDays;
    if (diff == 0) return '今天';
    if (diff == 1) return '昨天';
    if (diff < 7) return '$diff 天前';
    if (diff < 30) return '${diff ~/ 7} 周前';
    return '${date.month}/${date.day}';
  }
}

/// 技能一览：每行 图标 + 名称 + 进度条 + 状态
class _SkillsGlance extends StatelessWidget {
  final SkillService service;

  const _SkillsGlance({required this.service});

  @override
  Widget build(BuildContext context) {
    if (service.skills.isEmpty) return const SizedBox.shrink();

    final sorted = List<Skill>.from(service.skills)
      ..sort((a, b) {
        final ai = a.status.index;
        final bi = b.status.index;
        if (ai != bi) return ai.compareTo(bi);
        return b.daysSinceLastPractice.compareTo(a.daysSinceLastPractice);
      });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkSurfaceColor : Colors.white;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '技能一览',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: sorted.asMap().entries.map((e) {
                final i = e.key;
                final s = e.value;
                final status = s.status;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: s.category.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(s.category.icon, color: s.category.color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: s.currentProficiency / 100,
                                backgroundColor: status.color.withValues(alpha: 0.2),
                                color: status.color,
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${s.currentProficiency.toInt()}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: status.color,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(status.icon, size: 16, color: status.color),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 350.ms, delay: (400 + i * 55).ms)
                    .slideX(begin: 0.03, end: 0, curve: Curves.easeOutCubic);
              }).toList(),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 450.ms, delay: 380.ms)
        .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
  }
}

/// 打卡日历：最近 12 周，每周一列，7 行（一～日）
class _PracticeCalendar extends StatelessWidget {
  final SkillService service;

  const _PracticeCalendar({required this.service});

  @override
  Widget build(BuildContext context) {
    final heatMap = service.practiceHeatMap;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    const weeks = 12;
    const cellSize = 10.0;
    const cellGap = 2.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkSurfaceColor : Colors.white;
    final emptyColor = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200;

    // 本周一
    final weekStart = today.subtract(Duration(days: now.weekday - 1));
    final startWeekStart = weekStart.subtract(const Duration(days: 7 * (weeks - 1)));

    Color cellColor(int weekIdx, int dayIdx) {
      final d = startWeekStart.add(Duration(days: weekIdx * 7 + dayIdx));
      final key = DateTime(d.year, d.month, d.day);
      final isFuture = d.isAfter(today);
      final count = isFuture ? 0 : (heatMap[key] ?? 0);
      if (count <= 0) return emptyColor.withValues(alpha: isFuture ? 0.5 : 1.0);
      if (count == 1) return AppTheme.primaryColor.withValues(alpha: 0.4);
      if (count == 2) return AppTheme.primaryColor.withValues(alpha: 0.7);
      return AppTheme.primaryColor;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '打卡日历',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 18,
                  child: Column(
                    children: ['一', '二', '三', '四', '五', '六', '日'].asMap().entries.map((e) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: e.key < 6 ? cellGap : 0),
                        child: SizedBox(
                          height: cellSize,
                          child: Center(
                            child: Text(
                              e.value,
                              style: TextStyle(fontSize: 9, color: AppTheme.textHint),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(weeks, (w) {
                        return Padding(
                          padding: EdgeInsets.only(right: w < weeks - 1 ? cellGap : 0),
                          child: Column(
                            children: List.generate(7, (d) {
                              return Padding(
                                padding: EdgeInsets.only(bottom: d < 6 ? cellGap : 0),
                                child: Container(
                                  width: cellSize,
                                  height: cellSize,
                                  decoration: BoxDecoration(
                                    color: cellColor(w, d),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              );
                            }),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('少', style: TextStyle(fontSize: 10, color: AppTheme.textHint)),
              const SizedBox(width: 6),
              _legendDot(0, context),
              _legendDot(1, context),
              _legendDot(2, context),
              _legendDot(3, context),
              const SizedBox(width: 6),
              Text('多', style: TextStyle(fontSize: 10, color: AppTheme.textHint)),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 450.ms, delay: 450.ms)
        .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _legendDot(int level, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color c;
    if (level == 0) c = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100;
    else if (level == 1) c = AppTheme.primaryColor.withValues(alpha: 0.4);
    else if (level == 2) c = AppTheme.primaryColor.withValues(alpha: 0.7);
    else c = AppTheme.primaryColor;
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)),
      ),
    );
  }
}

/// 底部：总时长 · 总次数 · 最长连续
class _BottomStats extends StatelessWidget {
  final SkillService service;

  const _BottomStats({required this.service});

  @override
  Widget build(BuildContext context) {
    final stats = service.statistics;
    final totalMinutes = stats['totalPracticeMinutes'] as int;
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    final timeStr = hours > 0 ? '${hours}h ${mins}min' : '${mins} 分钟';
    final totalCount = stats['totalPracticeCount'] as int;
    final longest = stats['longestStreak'] as int;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _statChip(context, Icons.timer_outlined, timeStr, '总时长'),
          const SizedBox(width: 20),
          _statChip(context, Icons.check_circle_outline_rounded, '$totalCount', '总次数'),
          const SizedBox(width: 20),
          _statChip(context, Icons.local_fire_department_rounded, '$longest', '最长连续'),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 550.ms)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _statChip(BuildContext context, IconData icon, String value, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppTheme.textHint),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppTheme.textHint),
        ),
      ],
    );
  }
}
