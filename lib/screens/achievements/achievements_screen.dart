import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/achievement.dart';
import '../../services/skill_service.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

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

              final unlocked = service.unlockedAchievements;
              final locked = service.lockedAchievements;
              final total = service.achievements.length;

              return CustomScrollView(
                slivers: [
                  // 标题
                  SliverToBoxAdapter(child: _buildHeader(context, unlocked.length, total)),
                  
                  // 进度总览
                  SliverToBoxAdapter(child: _buildProgressOverview(context, unlocked.length, total)),
                  
                  // 已解锁
                  if (unlocked.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _buildSectionTitle(context, '已解锁', unlocked.length),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _AchievementBadge(
                            achievement: unlocked[index],
                            isUnlocked: true,
                            animationDelay: 400 + index * 60,
                          ),
                          childCount: unlocked.length,
                        ),
                      ),
                    ),
                  ],
                  
                  // 未解锁
                  if (locked.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _buildSectionTitle(context, '待解锁', locked.length),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _AchievementBadge(
                            achievement: locked[index],
                            isUnlocked: false,
                            animationDelay: 500 + index * 40,
                          ),
                          childCount: locked.length,
                        ),
                      ),
                    ),
                  ],
                  
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int unlocked, int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '成就殿堂',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
          const SizedBox(height: 4),
          Text(
            '收集徽章，见证你的成长',
            style: Theme.of(context).textTheme.bodyMedium,
          ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildProgressOverview(BuildContext context, int unlocked, int total) {
    final progress = total > 0 ? unlocked / total : 0.0;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF9B89B3), Color(0xFFB8A9C9)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9B89B3).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // 进度环
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          color: Colors.white,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$unlocked / $total',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '已解锁成就',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getMotivationText(progress),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1, end: 0);
  }

  String _getMotivationText(double progress) {
    if (progress == 0) return '开始你的成就之旅吧!';
    if (progress < 0.25) return '不错的开始，继续加油!';
    if (progress < 0.5) return '你已经解锁了不少成就!';
    if (progress < 0.75) return '太厉害了，成就达人!';
    if (progress < 1) return '就差最后几个了!';
    return '恭喜你，全部达成!';
  }

  Widget _buildSectionTitle(BuildContext context, String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final Achievement achievement;
  final bool isUnlocked;
  final int animationDelay;

  const _AchievementBadge({
    required this.achievement,
    required this.isUnlocked,
    this.animationDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isUnlocked ? Border.all(
            color: achievement.rarity.color.withValues(alpha: 0.3),
            width: 2,
          ) : null,
          boxShadow: isUnlocked ? [
            BoxShadow(
              color: achievement.rarity.color.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 徽章图标
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: isUnlocked
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: achievement.rarity.gradientColors,
                      )
                    : null,
                color: isUnlocked ? null : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isUnlocked ? achievement.icon : Icons.lock_rounded,
                color: isUnlocked ? Colors.white : Colors.grey.shade400,
                size: 26,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isUnlocked ? AppTheme.textPrimary : AppTheme.textHint,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // 稀有度 / 进度
            if (isUnlocked)
              Text(
                achievement.rarity.displayName,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: achievement.rarity.color,
                ),
              )
            else
              // 进度条
              Column(
                children: [
                  const SizedBox(height: 2),
                  SizedBox(
                    width: 60,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: achievement.progressPercent,
                        backgroundColor: Colors.grey.shade200,
                        color: AppTheme.primaryColor.withValues(alpha: 0.5),
                        minHeight: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${achievement.currentProgress}/${achievement.targetValue}',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppTheme.textHint,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: animationDelay))
      .fadeIn(duration: 300.ms)
      .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 300.ms);
  }

  void _showDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 大徽章
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: isUnlocked
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: achievement.rarity.gradientColors,
                        )
                      : null,
                  color: isUnlocked ? null : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: isUnlocked ? [
                    BoxShadow(
                      color: achievement.rarity.color.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ] : null,
                ),
                child: Icon(
                  isUnlocked ? achievement.icon : Icons.lock_rounded,
                  color: isUnlocked ? Colors.white : Colors.grey.shade400,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              
              // 稀有度标签
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: achievement.rarity.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  achievement.rarity.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: achievement.rarity.color,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              Text(
                achievement.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                achievement.description,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // 进度
              if (!isUnlocked) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${achievement.currentProgress}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      ' / ${achievement.targetValue}',
                      style: TextStyle(
                        fontSize: 24,
                        color: AppTheme.textHint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: achievement.progressPercent,
                      backgroundColor: Colors.grey.shade200,
                      color: AppTheme.primaryColor,
                      minHeight: 8,
                    ),
                  ),
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.successColor,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '已达成',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('关闭'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
