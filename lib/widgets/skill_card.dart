import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../config/theme.dart';
import '../models/skill.dart';

class SkillCard extends StatelessWidget {
  final Skill skill;
  final VoidCallback? onTap;
  final int animationDelay;

  const SkillCard({
    super.key,
    required this.skill,
    this.onTap,
    this.animationDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: skill.category.color.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // 熟练度环形图
            CircularPercentIndicator(
              radius: 36,
              lineWidth: 6,
              percent: skill.currentProficiency / 100,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    skill.category.icon,
                    color: skill.category.color,
                    size: 24,
                  ),
                ],
              ),
              progressColor: skill.category.color,
              backgroundColor: skill.category.color.withValues(alpha: 0.15),
              circularStrokeCap: CircularStrokeCap.round,
            ),
            const SizedBox(width: 16),
            
            // 技能信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          skill.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      // 状态标签
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: skill.status.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              skill.status.icon,
                              size: 14,
                              color: skill.status.color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              skill.status.displayName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: skill.status.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    skill.category.displayName,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textHint,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // 底部信息
                  Row(
                    children: [
                      // 熟练度数值
                      _buildInfoChip(
                        icon: Icons.speed_rounded,
                        label: '${skill.currentProficiency.toInt()}%',
                        color: skill.category.color,
                      ),
                      const SizedBox(width: 12),
                      // 上次练习
                      _buildInfoChip(
                        icon: Icons.access_time_rounded,
                        label: skill.lastPracticeText,
                        color: skill.needsReminder 
                            ? AppTheme.warningColor 
                            : AppTheme.textHint,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // 箭头
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textHint,
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: animationDelay))
      .fadeIn(duration: 400.ms)
      .slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// 小型技能卡片（用于提醒列表）
class SkillMiniCard extends StatelessWidget {
  final Skill skill;
  final VoidCallback? onTap;
  final VoidCallback? onPracticeTap;

  const SkillMiniCard({
    super.key,
    required this.skill,
    this.onTap,
    this.onPracticeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            skill.category.color.withValues(alpha: 0.15),
            skill.category.color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: skill.category.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: skill.category.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  skill.category.icon,
                  size: 20,
                  color: skill.category.color,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: skill.status.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${skill.currentProficiency.toInt()}%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            skill.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${skill.daysSinceLastPractice}天未练习',
            style: TextStyle(
              fontSize: 12,
              color: skill.needsReminder ? AppTheme.dangerColor : AppTheme.textHint,
              fontWeight: skill.needsReminder ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onPracticeTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: skill.category.color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  '去练习',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
