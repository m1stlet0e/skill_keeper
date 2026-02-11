import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/skill.dart';
import '../../models/practice_session.dart';
import '../../services/skill_service.dart';
import '../practice/practice_prepare_screen.dart';

class SkillDetailScreen extends StatefulWidget {
  final String skillId;

  const SkillDetailScreen({super.key, required this.skillId});

  @override
  State<SkillDetailScreen> createState() => _SkillDetailScreenState();
}

class _SkillDetailScreenState extends State<SkillDetailScreen> {
  int _selectedDays = 30;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SkillService>(
        builder: (context, skillService, child) {
          final skill = skillService.getSkillById(widget.skillId);
          
          if (skill == null) {
            return const Center(child: Text('技能不存在'));
          }

          return Container(
            decoration: BoxDecoration(
              gradient: AppTheme.backgroundGradientFor(context),
            ),
            child: SafeArea(
              child: CustomScrollView(
                slivers: [
                  // 顶部导航
                  SliverToBoxAdapter(
                    child: _buildAppBar(skill),
                  ),
                  
                  // 技能头部信息
                  SliverToBoxAdapter(
                    child: _buildSkillHeader(skill),
                  ),
                  
                  // 熟练度曲线图
                  SliverToBoxAdapter(
                    child: _buildProficiencyChart(skillService, skill),
                  ),
                  
                  // 统计数据
                  SliverToBoxAdapter(
                    child: _buildStatistics(skill),
                  ),
                  
                  // 练习记录标题
                  SliverToBoxAdapter(
                    child: _buildPracticeHistoryTitle(skill),
                  ),
                  
                  // 练习记录列表
                  _buildPracticeHistoryList(skill),
                  
                  // 底部间距
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: Consumer<SkillService>(
        builder: (context, skillService, child) {
          final skill = skillService.getSkillById(widget.skillId);
          if (skill == null) return const SizedBox();
          
          return FloatingActionButton.extended(
            onPressed: () => _showPracticeDialog(skill),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('开始练习'),
            backgroundColor: skill.category.color,
          ).animate().scale(delay: 500.ms, duration: 300.ms);
        },
      ),
    );
  }

  Widget _buildAppBar(Skill skill) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final btnBg = isDark ? AppTheme.darkSurfaceColor : Colors.white;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: btnBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _showEditSheet(skill),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: btnBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showDeleteDialog(skill),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: btnBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: AppTheme.dangerColor,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildSkillHeader(Skill skill) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkSurfaceColor : Colors.white;
    final shadowColor = isDark ? Colors.black.withValues(alpha: 0.25) : skill.category.color.withValues(alpha: 0.2);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // 熟练度环形图
                CircularPercentIndicator(
                  radius: 50,
                  lineWidth: 8,
                  percent: skill.currentProficiency / 100,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${skill.currentProficiency.toInt()}%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: skill.category.color,
                        ),
                      ),
                    ],
                  ),
                  progressColor: skill.category.color,
                  backgroundColor: skill.category.color.withValues(alpha: 0.15),
                  circularStrokeCap: CircularStrokeCap.round,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            skill.category.icon,
                            color: skill.category.color,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            skill.category.displayName,
                            style: TextStyle(
                              color: skill.category.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        skill.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (skill.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          skill.description!,
                          style: TextStyle(color: AppTheme.textHint),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // 状态标签
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: skill.status.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    skill.status.icon,
                    color: skill.status.color,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    skill.status.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: skill.status.color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '- 上次练习${skill.lastPracticeText}',
                    style: TextStyle(
                      color: skill.status.color.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildProficiencyChart(SkillService skillService, Skill skill) {
    final history = skillService.getProficiencyHistory(widget.skillId, days: _selectedDays);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkSurfaceColor : Colors.white;
    final selectorBg = isDark ? Colors.white12 : Colors.grey.shade100;
    final gridLineColor = isDark ? Colors.white12 : Colors.grey.shade200;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '熟练度变化',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: selectorBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [7, 30, 90].map((days) {
                      final isSelected = _selectedDays == days;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedDays = days),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? skill.category.color : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            days == 7 ? '7天' : days == 30 ? '30天' : '90天',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : AppTheme.textHint,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: gridLineColor,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        reservedSize: 35,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textHint,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: _selectedDays == 7 ? 1 : _selectedDays == 30 ? 7 : 15,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= history.length) return const SizedBox();
                          final date = history[value.toInt()]['date'] as DateTime;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('M/d').format(date),
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.textHint,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (history.length - 1).toDouble(),
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: history.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value['proficiency'] as double);
                      }).toList(),
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: skill.category.color,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: skill.category.color.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: 200.ms).fadeIn();
  }

  Widget _buildStatistics(Skill skill) {
    final totalPracticeMinutes = skill.practiceHistory.fold<int>(
      0, (sum, record) => sum + record.durationMinutes);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.trending_up_rounded,
              label: '巅峰熟练度',
              value: '${skill.peakProficiency.toInt()}%',
              color: AppTheme.successColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.timer_rounded,
              label: '总练习时长',
              value: '$totalPracticeMinutes分钟',
              color: AppTheme.infoColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.calendar_today_rounded,
              label: '练习次数',
              value: '${skill.practiceHistory.length}次',
              color: AppTheme.warningColor,
            ),
          ),
        ],
      ),
    ).animate(delay: 300.ms).fadeIn();
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkSurfaceColor : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeHistoryTitle(Skill skill) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Text(
            '练习记录',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          Text(
            '共${skill.practiceHistory.length}次',
            style: TextStyle(
              color: AppTheme.textHint,
            ),
          ),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn();
  }

  Widget _buildPracticeHistoryList(Skill skill) {
    if (skill.practiceHistory.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 48,
                  color: AppTheme.textHint.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  '还没有练习记录\n点击下方按钮开始练习',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textHint),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final sortedHistory = skill.practiceHistory.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final record = sortedHistory[index];
            return _buildPracticeRecordItem(skill, record, index);
          },
          childCount: sortedHistory.length,
        ),
      ),
    );
  }

  static String _moodLabel(int mood) {
    if (mood < 0) return '';
    const labels = ['困难', '一般', '还行', '顺畅', '超棒'];
    return mood < labels.length ? labels[mood] : '';
  }

  Widget _buildPracticeRecordItem(Skill skill, PracticeRecord record, int index) {
    final dateFormat = DateFormat('M月d日 HH:mm');
    final flowState = record.highestFlowState >= 0 && record.highestFlowState <= 3
        ? FlowState.values[record.highestFlowState]
        : null;
    final moodText = _moodLabel(record.mood);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkSurfaceColor
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: skill.category.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.check_circle_rounded,
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
                  '练习了${record.durationMinutes}分钟',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateFormat.format(record.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textHint,
                  ),
                ),
                if (flowState != null && flowState.index >= 2) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(flowState.icon, size: 12, color: const Color(0xFF533483)),
                      const SizedBox(width: 4),
                      Text(
                        '${flowState.displayName}${record.flowMultiplier > 1.0 ? " · ${record.flowMultiplier.toStringAsFixed(1)}x" : ""}',
                        style: TextStyle(
                          fontSize: 11,
                          color: const Color(0xFF533483),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                if (moodText.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '心情: $moodText',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
                if (record.note != null && record.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    record.note!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${record.proficiencyAfter.toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.successColor,
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: 450 + index * 50)).fadeIn().slideX(begin: 0.1, end: 0);
  }

  void _showPracticeDialog(Skill skill) {
    // 跳转到练习准备页面（全新沉浸式练习流程）
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticePrepareScreen(skill: skill),
      ),
    );
  }

  void _showEditSheet(Skill skill) {
    final nameController = TextEditingController(text: skill.name);
    final descController = TextEditingController(text: skill.description ?? '');
    var selectedCategory = skill.category;
    var targetPerWeek = skill.targetPracticePerWeek;
    var practiceMin = skill.practiceMinutes;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppTheme.darkSurfaceColor : Colors.white;
    final handleColor = isDark ? Colors.white24 : Colors.grey.shade300;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: handleColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '编辑技能',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 名称
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: '技能名称',
                      hintText: '例如: 吉他、Python、素描...',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 描述
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: '描述 (可选)',
                      hintText: '简短描述...',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 分类
                  const Text('分类', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: SkillCategory.values.map((cat) {
                      final isSelected = selectedCategory == cat;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedCategory = cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? cat.color : cat.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(cat.icon, size: 16, color: isSelected ? Colors.white : cat.color),
                              const SizedBox(width: 4),
                              Text(
                                cat.displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : cat.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // 每周目标 & 单次时长
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('每周目标', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: targetPerWeek > 1
                                      ? () => setModalState(() => targetPerWeek--)
                                      : null,
                                  icon: const Icon(Icons.remove_circle_outline_rounded),
                                  iconSize: 20,
                                ),
                                Text(
                                  '$targetPerWeek 次/周',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                IconButton(
                                  onPressed: targetPerWeek < 7
                                      ? () => setModalState(() => targetPerWeek++)
                                      : null,
                                  icon: const Icon(Icons.add_circle_outline_rounded),
                                  iconSize: 20,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('单次时长', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: practiceMin > 10
                                      ? () => setModalState(() => practiceMin -= 5)
                                      : null,
                                  icon: const Icon(Icons.remove_circle_outline_rounded),
                                  iconSize: 20,
                                ),
                                Text(
                                  '$practiceMin 分钟',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                IconButton(
                                  onPressed: practiceMin < 120
                                      ? () => setModalState(() => practiceMin += 5)
                                      : null,
                                  icon: const Icon(Icons.add_circle_outline_rounded),
                                  iconSize: 20,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 保存按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;

                        final updated = skill.copyWith(
                          name: name,
                          description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                          category: selectedCategory,
                          targetPracticePerWeek: targetPerWeek,
                          practiceMinutes: practiceMin,
                        );

                        context.read<SkillService>().updateSkill(updated);
                        Navigator.pop(ctx);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('技能信息已更新'),
                            backgroundColor: AppTheme.successColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedCategory.color,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        '保存修改',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteDialog(Skill skill) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('删除技能'),
        content: Text('确定要删除"${skill.name}"吗? 所有练习记录也将被删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final skillService = context.read<SkillService>();
              skillService.deleteSkill(skill.id);
              Navigator.pop(context); // 关闭对话框
              Navigator.pop(context); // 返回首页
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('已删除技能: ${skill.name}'),
                  backgroundColor: AppTheme.dangerColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            child: Text(
              '删除',
              style: TextStyle(color: AppTheme.dangerColor),
            ),
          ),
        ],
      ),
    );
  }
}
