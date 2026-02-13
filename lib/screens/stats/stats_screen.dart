import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/skill.dart';
import '../../services/skill_service.dart';

class StatsScreen extends StatelessWidget {
  final VoidCallback? onGoToHome;

  const StatsScreen({super.key, this.onGoToHome});

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
                  SliverToBoxAdapter(child: _HeroSection(service: service, onGoToHome: onGoToHome)),
                  SliverToBoxAdapter(child: _SkillsGlance(service: service)),
                  SliverToBoxAdapter(child: _ThisWeekStrip(service: service)),
                  SliverToBoxAdapter(child: _RecentActivity(service: service)),
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

/// 顶部：连续打卡数字 + 火焰图标 + 渐变光晕 + CTA
class _HeroSection extends StatelessWidget {
  final SkillService service;
  final VoidCallback? onGoToHome;

  const _HeroSection({required this.service, this.onGoToHome});

  @override
  Widget build(BuildContext context) {
    final streak = service.currentStreak;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppTheme.primaryColor : AppTheme.statsCaramel;
    final flameColor = streak > 0 ? accent : AppTheme.textHint;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [Colors.white.withValues(alpha: 0.06), Colors.white.withValues(alpha: 0.02)]
                : [
                    AppTheme.statsCaramel.withValues(alpha: 0.12),
                    AppTheme.statsCaramel.withValues(alpha: 0.04),
                  ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$streak',
                  style: GoogleFonts.nunito(
                    fontSize: 64,
                    fontWeight: FontWeight.w800,
                    height: 0.95,
                    letterSpacing: -2,
                    color: accent,
                    shadows: isDark
                        ? null
                        : [
                            Shadow(
                              color: accent.withValues(alpha: 0.3),
                              offset: const Offset(0, 3),
                              blurRadius: 10,
                            ),
                          ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1), curve: Curves.easeOutBack),
                const SizedBox(width: 10),
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 40,
                  color: flameColor,
                )
                    .animate()
                    .fadeIn(duration: 450.ms, delay: 100.ms)
                    .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), curve: Curves.easeOutBack),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '天连续打卡',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            )
                .animate()
                .fadeIn(duration: 450.ms, delay: 80.ms)
                .slideX(begin: -0.03, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 12),
            Text(
              streak > 0 ? '保持练习，技能不生锈' : '开始练习，点亮第一天',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontWeight: streak > 0 ? FontWeight.normal : FontWeight.w500,
              ),
            )
                .animate()
                .fadeIn(duration: 450.ms, delay: 180.ms)
                .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
            if (onGoToHome != null) ...[
              const SizedBox(height: 16),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onGoToHome,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department_rounded, size: 20, color: accent),
                        const SizedBox(width: 8),
                        Text(
                          '立即开始今日练习',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 280.ms)
                  .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
            ],
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.02, end: 0, curve: Curves.easeOutCubic);
  }
}

/// 本周练习：一周 7 天，圆角长条 + 今日小圆点 + 柱上显示时长
class _ThisWeekStrip extends StatelessWidget {
  final SkillService service;

  const _ThisWeekStrip({required this.service});

  @override
  Widget build(BuildContext context) {
    final dailyMinutes = service.getDailyPracticeMinutes(days: 30);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: now.weekday - 1));
    const days = ['一', '二', '三', '四', '五', '六', '日'];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkSurfaceColor : AppTheme.statsCream;
    final accent = isDark ? AppTheme.primaryColor : AppTheme.statsCaramel;

    int minutesForDay(int dayOffset) {
      final d = weekStart.add(Duration(days: dayOffset));
      final key = DateTime(d.year, d.month, d.day);
      return dailyMinutes[key] ?? 0;
    }

    final minutesList = List.generate(7, (i) => minutesForDay(i));
    final maxMinutes = minutesList.fold<int>(0, (a, b) => a > b ? a : b);
    final maxH = 48.0;

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
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final mins = minutesForDay(i);
                final dayDate = weekStart.add(Duration(days: i));
                final isToday = dayDate.isAtSameMomentAs(today);
                final h = maxMinutes > 0 ? 8.0 + maxH * (mins / maxMinutes) : 8.0;
                final displayH = h.clamp(8.0, 56.0);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (mins > 0)
                          Text(
                            mins >= 60 ? '${mins ~/ 60}h' : '${mins}分钟',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: accent,
                              fontFamily: GoogleFonts.nunito().fontFamily,
                            ),
                          ),
                        if (mins > 0) const SizedBox(height: 4),
                        Container(
                          height: displayH,
                          decoration: BoxDecoration(
                            color: mins > 0
                                ? accent.withValues(alpha: 0.35 + 0.5 * (maxMinutes > 0 ? mins / maxMinutes : 0))
                                : (isDark ? Colors.white12 : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        )
                            .animate()
                            .scaleY(begin: 0, end: 1, duration: 500.ms, delay: (350 + i * 50).ms, curve: Curves.easeOutCubic),
                        const SizedBox(height: 6),
                        Text(
                          days[i],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                            color: isToday ? accent : AppTheme.textHint,
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(height: 4),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
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
        .fadeIn(duration: 450.ms, delay: 320.ms)
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
    final cardBg = isDark ? AppTheme.darkSurfaceColor : AppTheme.statsCream;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
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
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.statsCaramel.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${r.durationMinutes} 分钟',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                              fontFamily: GoogleFonts.nunito().fontFamily,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 350.ms, delay: (400 + i * 60).ms)
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

/// 技能一览：每行 图标 + 名称 + 加粗进度条 + 百分比与图标分列
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
    final cardBg = isDark ? AppTheme.darkSurfaceColor : AppTheme.statsCream;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
                final progress = s.currentProficiency / 100;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: s.category.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Stack(
                              alignment: Alignment.centerRight,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: status.color.withValues(alpha: 0.15),
                                    color: status.color,
                                    minHeight: 10,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Icon(status.icon, size: 14, color: status.color),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${s.currentProficiency.toInt()}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: status.color,
                          fontFamily: GoogleFonts.nunito().fontFamily,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 350.ms, delay: (300 + i * 55).ms)
                    .slideX(begin: 0.03, end: 0, curve: Curves.easeOutCubic);
              }).toList(),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 450.ms, delay: 220.ms)
        .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
  }
}

/// 底部：总时长、总次数、最长连续 — 三块小卡片勋章式
class _BottomStats extends StatelessWidget {
  final SkillService service;

  const _BottomStats({required this.service});

  @override
  Widget build(BuildContext context) {
    final stats = service.statistics;
    final totalMinutes = stats['totalPracticeMinutes'] as int;
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    final timeStr = hours > 0 ? '${hours}h ${mins}min' : '${mins}分钟';
    final totalCount = stats['totalPracticeCount'] as int;
    final longest = stats['longestStreak'] as int;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkSurfaceColor : AppTheme.statsCream;
    final accent = isDark ? AppTheme.primaryColor : AppTheme.statsCaramel;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _statCard(context, Icons.timer_outlined, timeStr, '总时长', cardBg, accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statCard(context, Icons.check_circle_outline_rounded, '$totalCount', '总次数', cardBg, accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statCard(context, Icons.local_fire_department_rounded, '$longest', '最长连续', cardBg, accent),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 520.ms)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _statCard(BuildContext context, IconData icon, String value, String label, Color cardBg, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: accent),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: AppTheme.textHint),
          ),
        ],
      ),
    );
  }
}
