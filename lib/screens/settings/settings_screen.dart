import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/skill_service.dart';
import '../../services/theme_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // === 账号 ===
          _buildSectionTitle(context, '账号'),
          const SizedBox(height: 8),
          Consumer<AuthService>(
            builder: (context, auth, _) => _buildSettingsCard(
              context,
              children: [
                _buildSettingsItem(
                  context,
                  icon: Icons.person_rounded,
                  iconColor: AppTheme.primaryColor,
                  title: auth.user?.displayName ?? '未登录',
                  subtitle: auth.isLoggedIn ? '已登录' : '登录后同步数据',
                  showArrow: false,
                ),
                if (auth.isLoggedIn) ...[
                  const Divider(height: 1, indent: 56),
                  _buildSettingsItem(
                    context,
                    icon: Icons.logout_rounded,
                    iconColor: AppTheme.textSecondary,
                    title: '退出登录',
                    subtitle: '切换账号或使用体验账号',
                    onTap: () => _showLogoutConfirm(context, auth),
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 24),

          // === 外观 ===
          _buildSectionTitle(context, '外观'),
          const SizedBox(height: 8),
          Consumer<ThemeService>(
            builder: (context, themeService, _) => _buildSettingsCard(
              context,
              children: [
                _buildThemeSwitch(context, themeService),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 24),

          // === 练习提醒 ===
          _buildSectionTitle(context, '练习提醒'),
          const SizedBox(height: 8),
          Consumer<NotificationService>(
            builder: (context, noti, _) => _buildSettingsCard(
              context,
              children: [
                _buildReminderSwitch(context, noti),
                if (noti.reminderEnabled) ...[
                  const Divider(height: 1, indent: 56),
                  _buildReminderTimeRow(context, noti),
                ],
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 24),

          // === 数据管理 ===
          _buildSectionTitle(context, '数据管理'),
          const SizedBox(height: 8),
          _buildSettingsCard(
            context,
            children: [
              _buildSettingsItem(
                context,
                icon: Icons.delete_outline_rounded,
                iconColor: AppTheme.dangerColor,
                title: '清除所有数据',
                subtitle: '删除所有技能、练习记录和成就',
                onTap: () => _showClearDataDialog(context),
              ),
            ],
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 24),

          // === 数据与存储 ===
          _buildSectionTitle(context, '数据与存储'),
          const SizedBox(height: 8),
          _buildSettingsCard(
            context,
            children: [
              _buildSettingsItem(
                context,
                icon: Icons.phone_android_rounded,
                iconColor: AppTheme.infoColor,
                title: '数据保存说明',
                subtitle: '登录状态、深色模式、技能与练习数据均保存在本机，会永久保留；卸载应用或清除应用数据会丢失。',
                showArrow: false,
              ),
            ],
          ).animate(delay: 50.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 24),

          // === 关于 ===
          _buildSectionTitle(context, '关于'),
          const SizedBox(height: 8),
          _buildSettingsCard(
            context,
            children: [
              _buildSettingsItem(
                context,
                icon: Icons.info_outline_rounded,
                iconColor: AppTheme.primaryColor,
                title: 'SkillKeeper',
                subtitle: '版本 1.0.0',
                showArrow: false,
              ),
              const Divider(height: 1, indent: 56),
              _buildSettingsItem(
                context,
                icon: Icons.science_outlined,
                iconColor: AppTheme.infoColor,
                title: '技能衰退说明',
                subtitle: '受遗忘曲线与技能保持研究启发',
                onTap: () => _showDecayExplanationDialog(context),
              ),
              const Divider(height: 1, indent: 56),
              _buildSettingsItem(
                context,
                icon: Icons.code_rounded,
                iconColor: AppTheme.secondaryColor,
                title: '技术栈',
                subtitle: 'Flutter + Provider + SharedPreferences',
                showArrow: false,
              ),
              const Divider(height: 1, indent: 56),
              _buildSettingsItem(
                context,
                icon: Icons.favorite_outline_rounded,
                iconColor: Colors.redAccent,
                title: '理念',
                subtitle: '技能如同金属，不打磨就会生锈',
                showArrow: false,
              ),
            ],
          ).animate(delay: 100.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 24),

          // === 统计概览 ===
          _buildSectionTitle(context, '数据概览'),
          const SizedBox(height: 8),
          Consumer<SkillService>(
            builder: (context, service, _) {
              final stats = service.statistics;
              return _buildSettingsCard(
                context,
                children: [
                  _buildInfoItem(
                    context,
                    icon: Icons.auto_awesome_rounded,
                    label: '技能数量',
                    value: '${service.skills.length}',
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildInfoItem(
                    context,
                    icon: Icons.history_rounded,
                    label: '总练习次数',
                    value: '${stats['totalPracticeCount']}',
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildInfoItem(
                    context,
                    icon: Icons.timer_outlined,
                    label: '总练习时长',
                    value: _formatMinutes(stats['totalPracticeMinutes'] as int),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildInfoItem(
                    context,
                    icon: Icons.emoji_events_outlined,
                    label: '已解锁成就',
                    value: '${service.unlockedAchievements.length} / ${service.achievements.length}',
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildInfoItem(
                    context,
                    icon: Icons.local_fire_department_rounded,
                    label: '最长连续打卡',
                    value: '${service.longestStreak} 天',
                  ),
                ],
              );
            },
          ).animate(delay: 200.ms).fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, {required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool showArrow = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textHint,
                        ),
                  ),
                ],
              ),
            ),
            if (showArrow)
              const Icon(Icons.chevron_right_rounded, color: AppTheme.textHint, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
          ),
        ],
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '$minutes 分钟';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '$h 小时';
    return '$h 小时 $m 分钟';
  }

  Widget _buildThemeSwitch(BuildContext context, ThemeService themeService) {
    return InkWell(
      onTap: () => themeService.toggleDark(),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                themeService.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '深色模式',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    themeService.isDark ? '当前：深色' : '当前：浅色',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textHint,
                        ),
                  ),
                ],
              ),
            ),
            Switch(
              value: themeService.isDark,
              onChanged: (_) => themeService.toggleDark(),
              activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.5),
              activeThumbColor: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderSwitch(BuildContext context, NotificationService noti) {
    return InkWell(
      onTap: () async {
        final ok = await noti.setReminderEnabled(!noti.reminderEnabled);
        if (context.mounted && !ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('需要允许通知权限才能开启练习提醒'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.notifications_active_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '练习提醒',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    noti.reminderEnabled
                        ? '每天 ${noti.reminderTimeStr} 提醒'
                        : '每日固定时间提醒，技能防锈',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textHint,
                        ),
                  ),
                ],
              ),
            ),
            Switch(
              value: noti.reminderEnabled,
              onChanged: (v) async {
                final ok = await noti.setReminderEnabled(v);
                if (context.mounted && !ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('需要允许通知权限才能开启练习提醒'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
              activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.5),
              activeThumbColor: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderTimeRow(BuildContext context, NotificationService noti) {
    return InkWell(
      onTap: () => _showReminderTimePicker(context, noti),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const SizedBox(width: 36, height: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '提醒时间',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
              ),
            ),
            Text(
              noti.reminderTimeStr,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.access_time_rounded, size: 20, color: AppTheme.textHint),
          ],
        ),
      ),
    );
  }

  Future<void> _showReminderTimePicker(
      BuildContext context, NotificationService noti) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: noti.reminderHour, minute: noti.reminderMinute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null && context.mounted) {
      await noti.setReminderTime(time.hour, time.minute);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已设为每天 ${noti.reminderTimeStr} 提醒'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showDecayExplanationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.science_outlined, color: AppTheme.infoColor),
            SizedBox(width: 8),
            Text('技能衰退说明'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '本应用的技能衰退模型受艾宾浩斯遗忘曲线（Ebbinghaus forgetting curve）及技能保持（skill retention）研究启发。'
                '长期不练习会导致熟练度下降，本应用用「衰退」来量化这一过程。',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                '不同分类的衰退系数为设计取值，用于区分：'
                '身体记忆型（如运动、音乐）衰退较慢，知识记忆型（如语言、技术）衰退较快。'
                '具体公式与系数仅供参考，旨在帮助你优先安排「快要生锈」的技能。',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                '衰退在每日首次打开 App 时按「当天」统一计算并保存，同一天内多次打开不会重复扣减。',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textHint,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirm(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('退出登录'),
        content: const Text('退出后需重新登录，本地数据会保留。确定退出？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              auth.logout();
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
            },
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.dangerColor),
            SizedBox(width: 8),
            Text('确认清除'),
          ],
        ),
        content: const Text(
          '此操作将删除所有技能、练习记录和成就数据，且不可恢复。确定要继续吗?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final service = ctx.read<SkillService>();
              await service.clearAllData();
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('所有数据已清除'),
                  backgroundColor: AppTheme.successColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerColor,
            ),
            child: const Text('确认清除'),
          ),
        ],
      ),
    );
  }
}
