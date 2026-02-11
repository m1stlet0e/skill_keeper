import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/skill.dart';
import '../../services/skill_service.dart';
import '../../widgets/skill_card.dart';
import '../add_skill/add_skill_screen.dart';
import '../skill_detail/skill_detail_screen.dart';
import '../practice/practice_prepare_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedFilter = 0; // 0: 全部, 1: 需要关注, 2: 良好
  bool _dailyRecommendationExpanded = false;
  bool _attentionSectionExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradientFor(context),
        ),
        child: SafeArea(
          child: Consumer<SkillService>(
            builder: (context, skillService, child) {
              if (skillService.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                );
              }

              return CustomScrollView(
                slivers: [
                  // 顶部标题和统计
                  SliverToBoxAdapter(
                    child: _buildHeader(skillService),
                  ),
                  
                  // 连续打卡 + 快捷操作
                  SliverToBoxAdapter(
                    child: _buildStreakAndQuickActions(skillService),
                  ),

                  // 每日推荐（可折叠，默认收起）
                  if (skillService.dailyRecommendations.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _buildCollapsibleDailyRecommendation(skillService),
                    ),
                  ],
                  
                  // 需要关注（可折叠，默认收起）
                  if (skillService.skillsNeedingAttention.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _buildCollapsibleAttentionSection(skillService),
                    ),
                  ],
                  
                  // 筛选标签
                  SliverToBoxAdapter(
                    child: _buildFilterTabs(skillService),
                  ),
                  
                  // 技能列表
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: _buildSkillList(skillService),
                  ),
                  
                  // 底部间距
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(SkillService skillService) {
    final stats = skillService.statistics;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreeting(context),
                    const SizedBox(height: 4),
                    Text(
                      _getMotivationText(skillService),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
                  ],
                ),
              ),
              // 添加技能（非高频，放顶栏即可）
              Builder(
                builder: (context) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  final btnBg = isDark ? AppTheme.darkSurfaceColor : Colors.white;
                  return GestureDetector(
                    onTap: () => _navigateToAddSkill(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: btnBg,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  );
                },
              ).animate(delay: 150.ms).fadeIn().scale(),
              const SizedBox(width: 10),
              // 设置
              Builder(
                builder: (context) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  final btnBg = isDark ? AppTheme.darkSurfaceColor : Colors.white;
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: btnBg,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.settings_rounded,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  );
                },
              ).animate(delay: 200.ms).fadeIn().scale(),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 统计卡片
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.category_rounded,
                  value: '${stats['totalSkills']}',
                  label: '技能总数',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                _buildStatItem(
                  icon: Icons.speed_rounded,
                  value: '${(stats['averageProficiency'] as double).toInt()}%',
                  label: '平均熟练度',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                _buildStatItem(
                  icon: Icons.warning_amber_rounded,
                  value: '${stats['skillsInDanger']}',
                  label: '需要关注',
                  isWarning: (stats['skillsInDanger'] as int) > 0,
                ),
              ],
            ),
          ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;
    
    if (hour < 6) {
      greeting = '夜深了';
      greetingIcon = Icons.nightlight_rounded;
    } else if (hour < 12) {
      greeting = '早上好';
      greetingIcon = Icons.wb_sunny_rounded;
    } else if (hour < 18) {
      greeting = '下午好';
      greetingIcon = Icons.wb_cloudy_rounded;
    } else {
      greeting = '晚上好';
      greetingIcon = Icons.nights_stay_rounded;
    }
    
    return Row(
      children: [
        Icon(greetingIcon, color: AppTheme.primaryColor, size: 28),
        const SizedBox(width: 8),
        Text(
          greeting,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0);
  }

  String _getMotivationText(SkillService service) {
    if (service.skills.isEmpty) {
      return '添加你的第一个技能，开始追踪吧!';
    }
    
    if (service.hasPracticedToday) {
      final streak = service.currentStreak;
      if (streak > 1) {
        return '今日已打卡! 已连续$streak天，继续保持!';
      }
      return '今日已打卡! 明天继续加油!';
    }
    
    final danger = service.skillsNeedingAttention.length;
    if (danger > 0) {
      return '你有$danger个技能正在生锈，快去练习吧!';
    }
    
    return '别让你的技能生锈';
  }

  Widget _buildStreakAndQuickActions(SkillService service) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkSurfaceColor : Colors.white;
    final shadowAlpha = isDark ? 0.2 : 0.03;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // 连续打卡
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: shadowAlpha),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: service.currentStreak > 0
                          ? const LinearGradient(
                              colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
                            )
                          : null,
                      color: service.currentStreak > 0 ? null : (isDark ? Colors.white24 : Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      color: service.currentStreak > 0 ? Colors.white : (isDark ? Colors.white54 : Colors.grey.shade400),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${service.currentStreak}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: service.currentStreak > 0 
                              ? const Color(0xFFFF6B6B) 
                              : AppTheme.textHint,
                        ),
                      ),
                      Text(
                        '连续打卡',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textHint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 今日状态
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: shadowAlpha),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: service.hasPracticedToday
                          ? const LinearGradient(
                              colors: [Color(0xFF6BCB77), Color(0xFF8FD99A)],
                            )
                          : null,
                      color: service.hasPracticedToday ? null : (isDark ? Colors.white24 : Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      service.hasPracticedToday 
                          ? Icons.check_circle_rounded 
                          : Icons.radio_button_unchecked_rounded,
                      color: service.hasPracticedToday ? Colors.white : (isDark ? Colors.white54 : Colors.grey.shade400),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.hasPracticedToday ? '已完成' : '未打卡',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: service.hasPracticedToday 
                              ? const Color(0xFF6BCB77) 
                              : AppTheme.textHint,
                        ),
                      ),
                      Text(
                        '今日练习',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textHint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: 350.ms).fadeIn().slideY(begin: 0.1, end: 0);
  }

  /// 可折叠的「今日推荐」区块，默认收起
  Widget _buildCollapsibleDailyRecommendation(SkillService service) {
    final recommendations = service.dailyRecommendations;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkSurfaceColor : Colors.white;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _dailyRecommendationExpanded = !_dailyRecommendationExpanded),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_rounded,
                      color: AppTheme.accentColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '今日推荐',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '共${recommendations.length}项',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textHint,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _dailyRecommendationExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: AppTheme.textHint,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: _dailyRecommendationExpanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: recommendations.asMap().entries.map((entry) {
                        final index = entry.key;
                        final skill = entry.value;
                        return _buildRecommendationCard(skill, index);
                      }).toList(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyRecommendation(SkillService service) {
    final recommendations = service.dailyRecommendations;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_rounded, color: AppTheme.accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                '今日推荐',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '最需要练习的技能',
                style: TextStyle(fontSize: 11, color: AppTheme.textHint),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recommendations.asMap().entries.map((entry) {
            final index = entry.key;
            final skill = entry.value;
            return _buildRecommendationCard(skill, index);
          }),
        ],
      ),
    ).animate(delay: 380.ms).fadeIn();
  }

  Widget _buildRecommendationCard(Skill skill, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showPracticeDialog(skill),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  skill.category.color.withValues(alpha: 0.1),
                  skill.category.color.withValues(alpha: 0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: skill.category.color.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: skill.category.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    skill.category.icon,
                    color: skill.category.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skill.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${skill.lastPracticeText} - ${skill.status.displayName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: skill.status.color,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: skill.category.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '去练习',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: 400 + index * 60))
      .fadeIn()
      .slideX(begin: 0.1, end: 0);
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    bool isWarning = false,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: isWarning ? AppTheme.warningColor : Colors.white,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isWarning ? AppTheme.warningColor : Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  /// 可折叠的「需要关注」区块，默认收起
  Widget _buildCollapsibleAttentionSection(SkillService skillService) {
    final attentionSkills = skillService.skillsNeedingAttention.take(5).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkSurfaceColor : Colors.white;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _attentionSectionExpanded = !_attentionSectionExpanded),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_active_rounded,
                      color: AppTheme.warningColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '需要关注',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${attentionSkills.length}个技能',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textHint,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _attentionSectionExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: AppTheme.textHint,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: _attentionSectionExpanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(right: 20),
                        itemCount: attentionSkills.length,
                        itemBuilder: (context, index) {
                          final skill = attentionSkills[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: SkillMiniCard(
                              skill: skill,
                              onTap: () => _navigateToSkillDetail(skill),
                              onPracticeTap: () => _showPracticeDialog(skill),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildAttentionSection(SkillService skillService) {
    final attentionSkills = skillService.skillsNeedingAttention.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(
                Icons.notifications_active_rounded,
                color: AppTheme.warningColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '需要关注',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${attentionSkills.length}个技能',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textHint,
                ),
              ),
            ],
          ),
        ).animate(delay: 450.ms).fadeIn(),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: attentionSkills.length,
            itemBuilder: (context, index) {
              final skill = attentionSkills[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SkillMiniCard(
                  skill: skill,
                  onTap: () => _navigateToSkillDetail(skill),
                  onPracticeTap: () => _showPracticeDialog(skill),
                ),
              ).animate(delay: Duration(milliseconds: 480 + index * 50))
                .fadeIn()
                .slideX(begin: 0.2, end: 0);
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildFilterTabs(SkillService skillService) {
    final filters = ['全部', '需要关注', '状态良好'];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '我的技能',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              // 筛选按钮
              Builder(
                builder: (context) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  final tabBg = isDark ? AppTheme.darkSurfaceColor : Colors.white;
                  return Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: tabBg,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isDark ? null : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      children: List.generate(filters.length, (index) {
                        final isSelected = _selectedFilter == index;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedFilter = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              filters[index],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.white : AppTheme.textHint,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    ).animate(delay: 500.ms).fadeIn();
  }

  Widget _buildSkillList(SkillService skillService) {
    List<Skill> filteredSkills;
    
    switch (_selectedFilter) {
      case 1: // 需要关注
        filteredSkills = skillService.skills.where((s) => 
          s.status == SkillStatus.rusty || 
          s.status == SkillStatus.declining || 
          s.status == SkillStatus.critical
        ).toList();
        break;
      case 2: // 状态良好
        filteredSkills = skillService.skills.where((s) => 
          s.status == SkillStatus.excellent || 
          s.status == SkillStatus.good
        ).toList();
        break;
      default: // 全部
        filteredSkills = skillService.skills;
    }

    if (filteredSkills.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _selectedFilter == 0 
                        ? Icons.add_circle_outline_rounded 
                        : Icons.search_off_rounded,
                    size: 48,
                    color: AppTheme.primaryColor.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _selectedFilter == 0 
                      ? '还没有添加技能'
                      : '没有符合条件的技能',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                if (_selectedFilter == 0)
                  Text(
                    '点击右上角「+」添加你的第一个技能\n开始追踪你的技能衰退',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textHint,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final skill = filteredSkills[index];
          return SkillCard(
            skill: skill,
            animationDelay: 550 + index * 50,
            onTap: () => _navigateToSkillDetail(skill),
          );
        },
        childCount: filteredSkills.length,
      ),
    );
  }

  void _navigateToAddSkill() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddSkillScreen()),
    );
  }

  void _navigateToSkillDetail(Skill skill) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SkillDetailScreen(skillId: skill.id)),
    );
  }

  void _showPracticeDialog(Skill skill) {
    // 跳转到练习准备页面（全新沉浸式练习流程）
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticePrepareScreen(skill: skill),
      ),
    );
  }
}
