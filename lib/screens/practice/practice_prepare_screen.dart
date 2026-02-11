import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../models/skill.dart';
import '../../models/practice_session.dart';
import 'practice_focus_screen.dart';

class PracticePrepareScreen extends StatefulWidget {
  final Skill skill;

  const PracticePrepareScreen({super.key, required this.skill});

  @override
  State<PracticePrepareScreen> createState() => _PracticePrepareScreenState();
}

class _PracticePrepareScreenState extends State<PracticePrepareScreen>
    with TickerProviderStateMixin {
  PracticeMode _selectedMode = PracticeMode.free;
  int _countdownMinutes = 30;
  int _pomodoroRounds = 2;
  final _goalController = TextEditingController();
  
  bool _showBreathingGuide = false;
  int _breathCount = 0;
  late AnimationController _breathAnimController;

  @override
  void initState() {
    super.initState();
    _countdownMinutes = widget.skill.practiceMinutes;
    _breathAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
  }

  @override
  void dispose() {
    _goalController.dispose();
    _breathAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showBreathingGuide) {
      return _buildBreathingGuide();
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradientFor(context),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 顶部导航
              _buildAppBar(),
              
              // 内容
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 技能信息卡片
                      _buildSkillInfoCard()
                          .animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
                      
                      const SizedBox(height: 28),
                      
                      // 练习模式选择
                      _buildSectionTitle('练习模式'),
                      const SizedBox(height: 12),
                      _buildModeSelector()
                          .animate(delay: 100.ms).fadeIn(),
                      
                      const SizedBox(height: 24),
                      
                      // 模式设置
                      if (_selectedMode == PracticeMode.countdown)
                        _buildCountdownSettings()
                            .animate(delay: 150.ms).fadeIn(),
                      if (_selectedMode == PracticeMode.pomodoro)
                        _buildPomodoroSettings()
                            .animate(delay: 150.ms).fadeIn(),
                      
                      if (_selectedMode != PracticeMode.free)
                        const SizedBox(height: 24),
                      
                      // 练习目标
                      _buildSectionTitle('本次目标 (可选)'),
                      const SizedBox(height: 8),
                      _buildGoalInput()
                          .animate(delay: 200.ms).fadeIn(),
                      
                      const SizedBox(height: 16),
                      
                      // 心流提示
                      _buildFlowTip()
                          .animate(delay: 250.ms).fadeIn(),
                      
                      const SizedBox(height: 40),
                      
                      // 开始按钮
                      _buildStartButton()
                          .animate(delay: 300.ms).fadeIn().slideY(begin: 0.2, end: 0),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkSurfaceColor
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '准备练习',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildSkillInfoCard() {
    final skill = widget.skill;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkSurfaceColor : Colors.white;
    final shadowColor = isDark ? Colors.black.withValues(alpha: 0.25) : skill.category.color.withValues(alpha: 0.15);

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: skill.category.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              skill.category.icon,
              color: skill.category.color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skill.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(skill.status.icon, size: 14, color: skill.status.color),
                    const SizedBox(width: 4),
                    Text(
                      '${skill.status.displayName} - ${skill.currentProficiency.toInt()}%',
                      style: TextStyle(
                        fontSize: 13,
                        color: skill.status.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '上次练习: ${skill.lastPracticeText}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textHint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildModeSelector() {
    return Column(
      children: PracticeMode.values.map((mode) {
        final isSelected = _selectedMode == mode;
        return GestureDetector(
          onTap: () => setState(() => _selectedMode = mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? widget.skill.category.color.withValues(alpha: 0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? widget.skill.category.color
                    : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? widget.skill.category.color
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    mode.icon,
                    color: isSelected ? Colors.white : AppTheme.textHint,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode.displayName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? widget.skill.category.color
                              : AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        mode.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: widget.skill.category.color,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCountdownSettings() {
    final durations = [15, 20, 30, 45, 60, 90];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('目标时长'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: durations.map((min) {
            final isSelected = _countdownMinutes == min;
            return GestureDetector(
              onTap: () => setState(() => _countdownMinutes = min),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? widget.skill.category.color
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? widget.skill.category.color
                        : Colors.grey.shade200,
                  ),
                ),
                child: Text(
                  '$min分钟',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPomodoroSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('番茄钟轮数'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          children: [1, 2, 3, 4].map((rounds) {
            final isSelected = _pomodoroRounds == rounds;
            final totalMin = rounds * 30; // 25+5
            return GestureDetector(
              onTap: () => setState(() => _pomodoroRounds = rounds),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? widget.skill.category.color
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? widget.skill.category.color
                        : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '$rounds轮',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      '约$totalMin分钟',
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.8)
                            : AppTheme.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGoalInput() {
    return TextField(
      controller: _goalController,
      decoration: InputDecoration(
        hintText: '例如: 把副歌部分弹顺、背完第三课单词...',
        hintStyle: TextStyle(color: AppTheme.textHint, fontSize: 14),
        prefixIcon: Icon(
          Icons.flag_rounded,
          color: widget.skill.category.color.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildFlowTip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF533483).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF533483).withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF533483).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.water_drop_rounded,
              color: Color(0xFF533483),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '心流提示',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF533483),
                  ),
                ),
                Text(
                  '连续专注15分钟以上可进入心流状态，心流状态下熟练度提升更快',
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFF533483).withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _startBreathingGuide,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.skill.category.color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 4,
          shadowColor: widget.skill.category.color.withValues(alpha: 0.4),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow_rounded, size: 28),
            SizedBox(width: 8),
            Text(
              '开始专注',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _startBreathingGuide() {
    setState(() {
      _showBreathingGuide = true;
      _breathCount = 0;
    });
    _runBreathingCycle();
  }

  Future<void> _runBreathingCycle() async {
    for (int i = 0; i < 3; i++) {
      if (!mounted) return;
      setState(() => _breathCount = i + 1);

      // 吸气
      _breathAnimController.forward();
      await Future.delayed(const Duration(milliseconds: 2000));
      if (!mounted) return;

      // 呼气
      _breathAnimController.reverse();
      await Future.delayed(const Duration(milliseconds: 2000));
      if (!mounted) return;
    }

    // 进入专注页面
    if (!mounted) return;
    _navigateToFocus();
  }

  Widget _buildBreathingGuide() {
    final texts = ['', '吸气...', '吸气...', '准备好了'];
    final displayText = _breathCount < texts.length ? texts[_breathCount] : '准备好了';

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 1000),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A1A2E),
              widget.skill.category.color.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 呼吸动画圆
              AnimatedBuilder(
                animation: _breathAnimController,
                builder: (context, child) {
                  final size = 120.0 + _breathAnimController.value * 60;
                  return Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.skill.category.color.withValues(
                        alpha: 0.2 + _breathAnimController.value * 0.15,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.skill.category.color.withValues(
                            alpha: 0.1 + _breathAnimController.value * 0.1,
                          ),
                          blurRadius: 40 + _breathAnimController.value * 20,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.skill.category.color.withValues(
                            alpha: 0.3 + _breathAnimController.value * 0.2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _breathCount > 0 ? '$_breathCount' : '',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  displayText,
                  key: ValueKey(displayText),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                    color: Colors.white.withValues(alpha: 0.9),
                    letterSpacing: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToFocus() {
    int? targetSeconds;
    if (_selectedMode == PracticeMode.countdown) {
      targetSeconds = _countdownMinutes * 60;
    } else if (_selectedMode == PracticeMode.pomodoro) {
      targetSeconds = _pomodoroRounds * 30 * 60; // 总时长(含休息)
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PracticeFocusScreen(
          skill: widget.skill,
          mode: _selectedMode,
          targetSeconds: targetSeconds,
          pomodoroRounds: _selectedMode == PracticeMode.pomodoro ? _pomodoroRounds : null,
          goal: _goalController.text.trim().isEmpty ? null : _goalController.text.trim(),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }
}
