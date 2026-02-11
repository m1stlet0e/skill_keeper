import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/skill.dart';
import '../../models/achievement.dart';
import '../../models/practice_session.dart';
import '../../services/skill_service.dart';

class PracticeReviewScreen extends StatefulWidget {
  final Skill skill;
  final PracticeSessionData sessionData;

  const PracticeReviewScreen({
    super.key,
    required this.skill,
    required this.sessionData,
  });

  @override
  State<PracticeReviewScreen> createState() => _PracticeReviewScreenState();
}

class _PracticeReviewScreenState extends State<PracticeReviewScreen>
    with TickerProviderStateMixin {
  int _selectedMood = -1;
  final _noteController = TextEditingController();
  bool _isSaving = false;
  bool _saved = false;
  double _oldProficiency = 0;
  double _newProficiency = 0;
  List<Achievement> _newAchievements = [];

  late AnimationController _proficiencyAnimController;
  late Animation<double> _proficiencyAnim;

  @override
  void initState() {
    super.initState();
    _oldProficiency = widget.skill.currentProficiency;
    _proficiencyAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _proficiencyAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _proficiencyAnimController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    _proficiencyAnimController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '$h小时$m分钟';
    if (m > 0) return '$m分$s秒';
    return '$s秒';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _saved,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_saved) {
          _saveAndExit();
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.backgroundGradientFor(context),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        
                        // 完成标题
                        _buildCompletionHeader(),
                        
                        const SizedBox(height: 28),
                        
                        // 核心数据卡片
                        _buildDataCard(),
                        
                        const SizedBox(height: 20),
                        
                        // 心流分析
                        _buildFlowAnalysis(),
                        
                        const SizedBox(height: 20),
                        
                        // 熟练度变化（保存后显示）
                        if (_saved)
                          _buildProficiencyChange()
                              .animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
                        
                        if (_saved && _newAchievements.isNotEmpty)
                          _buildNewAchievements()
                              .animate(delay: 300.ms).fadeIn(duration: 600.ms),
                        
                        if (!_saved) ...[
                          const SizedBox(height: 20),
                          
                          // 心情选择
                          _buildMoodSelector(),
                          
                          const SizedBox(height: 20),
                          
                          // 备注
                          _buildNoteInput(),
                        ],
                        
                        const SizedBox(height: 32),
                        
                        // 操作按钮
                        _buildActionButtons(),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.skill.category.color,
                widget.skill.category.color.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.skill.category.color.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 40,
          ),
        ).animate().scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1, 1),
          duration: 600.ms,
          curve: Curves.elasticOut,
        ),
        const SizedBox(height: 20),
        Text(
          '练习完成!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2, end: 0),
        const SizedBox(height: 4),
        Text(
          widget.skill.name,
          style: TextStyle(
            fontSize: 15,
            color: AppTheme.textHint,
          ),
        ).animate(delay: 300.ms).fadeIn(),
      ],
    );
  }

  Widget _buildDataCard() {
    final session = widget.sessionData;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // 总时长（大字）
          Text(
            _formatDuration(session.totalSeconds),
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: widget.skill.category.color,
            ),
          ).animate(delay: 400.ms).fadeIn().scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1, 1),
          ),
          Text(
            '总练习时长',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textHint,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // 三列数据
          Row(
            children: [
              _buildDataItem(
                icon: Icons.water_drop_rounded,
                value: session.highestFlowState.displayName,
                label: '最高状态',
                color: const Color(0xFF533483),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.shade200,
              ),
              _buildDataItem(
                icon: Icons.timer_rounded,
                value: session.maxFlowSeconds > 0
                    ? _formatDuration(session.maxFlowSeconds)
                    : '-',
                label: '最长心流',
                color: const Color(0xFF11998E),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.shade200,
              ),
              _buildDataItem(
                icon: Icons.trending_up_rounded,
                value: '${session.flowMultiplier.toStringAsFixed(1)}x',
                label: '心流加成',
                color: const Color(0xFFFFB347),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildDataItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
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
      ),
    );
  }

  Widget _buildFlowAnalysis() {
    final session = widget.sessionData;
    final total = session.totalSeconds.toDouble();
    if (total == 0) return const SizedBox.shrink();

    final segments = [
      _FlowSegment('预热', session.warmupSeconds, const Color(0xFF1A1A2E)),
      _FlowSegment('专注', session.focusSeconds, const Color(0xFF0F3460)),
      _FlowSegment('心流', session.flowSeconds, const Color(0xFF533483)),
      _FlowSegment('深度心流', session.deepFlowSeconds, const Color(0xFF11998E)),
    ].where((s) => s.seconds > 0).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '心流分析',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // 条形图
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: segments.map((seg) {
                  return Expanded(
                    flex: seg.seconds,
                    child: Container(color: seg.color),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 图例
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: segments.map((seg) {
              final percent = (seg.seconds / total * 100).toInt();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: seg.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${seg.name} $percent%',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    ).animate(delay: 600.ms).fadeIn();
  }

  Widget _buildProficiencyChange() {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.skill.category.color.withValues(alpha: 0.1),
            widget.skill.category.color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.skill.category.color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          const Text(
            '熟练度变化',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _proficiencyAnim,
            builder: (context, child) {
              final current = _oldProficiency +
                  (_newProficiency - _oldProficiency) * _proficiencyAnim.value;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_oldProficiency.toInt()}%',
                    style: TextStyle(
                      fontSize: 20,
                      color: AppTheme.textHint,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: widget.skill.category.color,
                    ),
                  ),
                  Text(
                    '${current.toInt()}%',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: widget.skill.category.color,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            '+${(_newProficiency - _oldProficiency).toStringAsFixed(1)}% (含${widget.sessionData.flowMultiplier.toStringAsFixed(1)}x心流加成)',
            style: TextStyle(
              fontSize: 12,
              color: widget.skill.category.color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewAchievements() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFB347).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events_rounded, color: const Color(0xFFFFB347), size: 20),
              const SizedBox(width: 6),
              const Text(
                '新成就解锁!',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFB347),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_newAchievements.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: a.rarity.gradientColors),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(a.icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        a.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: a.rarity.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    a.rarity.displayName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: a.rarity.color,
                    ),
                  ),
                ),
              ],
            ),
          ))),
        ],
      ),
    );
  }

  Widget _buildMoodSelector() {
    final moods = [
      _MoodOption(0, Icons.sentiment_very_dissatisfied_rounded, '困难', const Color(0xFFFF6B6B)),
      _MoodOption(1, Icons.sentiment_dissatisfied_rounded, '一般', const Color(0xFFFF8C42)),
      _MoodOption(2, Icons.sentiment_neutral_rounded, '还行', const Color(0xFFFFB347)),
      _MoodOption(3, Icons.sentiment_satisfied_rounded, '顺畅', const Color(0xFF7ED6DF)),
      _MoodOption(4, Icons.sentiment_very_satisfied_rounded, '超棒', const Color(0xFF6BCB77)),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '今天练得怎么样?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: moods.map((mood) {
              final isSelected = _selectedMood == mood.value;
              return GestureDetector(
                onTap: () => setState(() => _selectedMood = mood.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? mood.color.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? mood.color
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        mood.icon,
                        size: 32,
                        color: isSelected ? mood.color : AppTheme.textHint,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mood.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? mood.color : AppTheme.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate(delay: 700.ms).fadeIn();
  }

  Widget _buildNoteInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '今日收获 (可选)',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              hintText: '记录一下今天的练习感受...',
              hintStyle: TextStyle(color: AppTheme.textHint),
            ),
            maxLines: 3,
          ),
        ],
      ),
    ).animate(delay: 800.ms).fadeIn();
  }

  Widget _buildActionButtons() {
    if (_saved) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.skill.category.color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
            '返回首页',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveAndExit,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.skill.category.color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                '保存记录',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    ).animate(delay: 900.ms).fadeIn().slideY(begin: 0.2, end: 0);
  }

  Future<void> _saveAndExit() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final service = context.read<SkillService>();
    final session = widget.sessionData;

    final achievements = await service.recordPracticeWithFlow(
      skillId: widget.skill.id,
      durationMinutes: session.totalMinutes > 0 ? session.totalMinutes : 1,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      highestFlowState: session.highestFlowState.index,
      maxFlowMinutes: session.maxFlowSeconds ~/ 60,
      mood: _selectedMood,
      practiceGoal: session.goal,
      flowMultiplier: session.flowMultiplier,
    );

    if (!mounted) return;

    // 获取更新后的熟练度
    final updatedSkill = service.getSkillById(widget.skill.id);
    setState(() {
      _isSaving = false;
      _saved = true;
      _newAchievements = achievements;
      _newProficiency = updatedSkill?.currentProficiency ?? _oldProficiency;
    });

    // 播放熟练度动画
    _proficiencyAnimController.forward();
  }
}

class _FlowSegment {
  final String name;
  final int seconds;
  final Color color;
  const _FlowSegment(this.name, this.seconds, this.color);
}

class _MoodOption {
  final int value;
  final IconData icon;
  final String label;
  final Color color;
  const _MoodOption(this.value, this.icon, this.label, this.color);
}
