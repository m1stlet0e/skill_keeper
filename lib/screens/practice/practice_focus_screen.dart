import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/skill.dart';
import '../../models/practice_session.dart';
import '../../widgets/flow_background.dart';
import 'practice_review_screen.dart';

class PracticeFocusScreen extends StatefulWidget {
  final Skill skill;
  final PracticeMode mode;
  final int? targetSeconds;
  final int? pomodoroRounds;
  final String? goal;

  const PracticeFocusScreen({
    super.key,
    required this.skill,
    required this.mode,
    this.targetSeconds,
    this.pomodoroRounds,
    this.goal,
  });

  @override
  State<PracticeFocusScreen> createState() => _PracticeFocusScreenState();
}

class _PracticeFocusScreenState extends State<PracticeFocusScreen>
    with TickerProviderStateMixin {
  // 计时
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isPaused = false;
  bool _isFinished = false;
  
  // 心流
  FlowState _currentFlowState = FlowState.warmup;
  int _continuousFocusSeconds = 0; // 连续专注秒数（暂停会重置一级）
  int _maxFlowSeconds = 0;         // 最长连续心流秒数
  int _pauseCount = 0;
  
  // 各阶段累计秒数
  int _warmupSeconds = 0;
  int _focusSeconds = 0;
  int _flowSeconds = 0;
  int _deepFlowSeconds = 0;
  
  // 番茄钟
  int _currentPomodoroRound = 1;
  bool _isBreakTime = false;
  int _pomodoroPhaseSeconds = 0; // 当前番茄钟阶段已过秒数

  // 动画
  late AnimationController _flowTransitionController;
  FlowState _previousFlowState = FlowState.warmup;

  @override
  void initState() {
    super.initState();
    _flowTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // 沉浸式状态栏
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _flowTransitionController.dispose();
    // 恢复状态栏
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused || _isFinished) return;
      
      setState(() {
        _elapsedSeconds++;
        
        if (_isBreakTime) {
          // 番茄钟休息阶段
          _pomodoroPhaseSeconds++;
          if (_pomodoroPhaseSeconds >= 300) { // 5分钟休息
            _isBreakTime = false;
            _pomodoroPhaseSeconds = 0;
            _currentPomodoroRound++;
            if (_currentPomodoroRound > (widget.pomodoroRounds ?? 2)) {
              _finishPractice();
              return;
            }
            HapticFeedback.mediumImpact();
          }
          return;
        }
        
        // 更新专注时间
        _continuousFocusSeconds++;
        _pomodoroPhaseSeconds++;
        
        // 更新心流状态
        _updateFlowState();
        
        // 记录各阶段时间
        switch (_currentFlowState) {
          case FlowState.warmup:
            _warmupSeconds++;
            break;
          case FlowState.focus:
            _focusSeconds++;
            break;
          case FlowState.flow:
            _flowSeconds++;
            // 更新最长心流
            final currentFlowDuration = _flowSeconds + _deepFlowSeconds;
            if (currentFlowDuration > _maxFlowSeconds) {
              _maxFlowSeconds = currentFlowDuration;
            }
            break;
          case FlowState.deepFlow:
            _deepFlowSeconds++;
            final currentFlowDuration2 = _flowSeconds + _deepFlowSeconds;
            if (currentFlowDuration2 > _maxFlowSeconds) {
              _maxFlowSeconds = currentFlowDuration2;
            }
            break;
        }
        
        // 番茄钟模式：检查是否该休息了
        if (widget.mode == PracticeMode.pomodoro) {
          if (_pomodoroPhaseSeconds >= 1500) { // 25分钟
            if (_currentPomodoroRound < (widget.pomodoroRounds ?? 2)) {
              _isBreakTime = true;
              _pomodoroPhaseSeconds = 0;
              HapticFeedback.heavyImpact();
            } else {
              _finishPractice();
            }
          }
        }
        
        // 倒计时模式：检查是否结束
        if (widget.mode == PracticeMode.countdown) {
          if (_elapsedSeconds >= (widget.targetSeconds ?? 1800)) {
            _finishPractice();
          }
        }
      });
    });
  }

  void _updateFlowState() {
    final minutes = _continuousFocusSeconds ~/ 60;
    FlowState newState;
    
    if (minutes >= 30) {
      newState = FlowState.deepFlow;
    } else if (minutes >= 15) {
      newState = FlowState.flow;
    } else if (minutes >= 5) {
      newState = FlowState.focus;
    } else {
      newState = FlowState.warmup;
    }
    
    if (newState != _currentFlowState) {
      _previousFlowState = _currentFlowState;
      _currentFlowState = newState;
      _flowTransitionController.forward(from: 0);
      
      // 触觉反馈
      if (newState.index > _previousFlowState.index) {
        HapticFeedback.mediumImpact();
      }
    }
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _pauseCount++;
        // 暂停时心流回退一级
        if (_currentFlowState.index > 0) {
          _previousFlowState = _currentFlowState;
          _currentFlowState = FlowState.values[_currentFlowState.index - 1];
          _continuousFocusSeconds = _currentFlowState.requiredMinutes * 60;
        } else {
          _continuousFocusSeconds = 0;
        }
      }
    });
    HapticFeedback.lightImpact();
  }

  void _finishPractice() {
    _isFinished = true;
    _timer?.cancel();
    HapticFeedback.heavyImpact();
    
    _navigateToReview();
  }

  void _showEndConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('结束练习?'),
        content: Text(
          '你已经专注了${_formatTime(_elapsedSeconds)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('继续练习'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _finishPractice();
            },
            child: Text(
              '结束',
              style: TextStyle(color: Colors.red.shade400),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToReview() {
    final sessionData = PracticeSessionData(
      totalSeconds: _elapsedSeconds,
      maxFlowSeconds: _maxFlowSeconds,
      highestFlowState: _getHighestFlowState(),
      mode: widget.mode,
      goal: widget.goal,
      pauseCount: _pauseCount,
      warmupSeconds: _warmupSeconds,
      focusSeconds: _focusSeconds,
      flowSeconds: _flowSeconds,
      deepFlowSeconds: _deepFlowSeconds,
    );

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PracticeReviewScreen(
          skill: widget.skill,
          sessionData: sessionData,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  FlowState _getHighestFlowState() {
    if (_deepFlowSeconds > 0) return FlowState.deepFlow;
    if (_flowSeconds > 0) return FlowState.flow;
    if (_focusSeconds > 0) return FlowState.focus;
    return FlowState.warmup;
  }

  String _formatTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showEndConfirmDialog();
        }
      },
      child: Scaffold(
        body: FlowBackground(
          flowState: _currentFlowState,
          themeColor: widget.skill.category.color,
          child: SafeArea(
            child: Column(
              children: [
                // 顶部信息
                _buildTopBar(),
                
                const Spacer(flex: 2),
                
                // 心流状态指示器
                _buildFlowIndicator(),
                
                const SizedBox(height: 32),
                
                // 计时器
                _buildTimer(),
                
                // 番茄钟信息
                if (widget.mode == PracticeMode.pomodoro)
                  _buildPomodoroInfo(),
                
                // 目标
                if (widget.goal != null)
                  _buildGoal(),
                
                const Spacer(flex: 3),
                
                // 控制按钮
                _buildControls(),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // 技能名
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.skill.category.icon,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.skill.name,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // 模式标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              widget.mode.displayName,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildFlowIndicator() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      child: Column(
        key: ValueKey(_currentFlowState),
        children: [
          // 心流图标
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _currentFlowState.icon,
              color: Colors.white.withValues(alpha: 0.9),
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _currentFlowState.displayName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _currentFlowState.subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          if (_currentFlowState.multiplier > 1.0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_currentFlowState.multiplier}x 加成',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimer() {
    String displayTime;
    
    if (widget.mode == PracticeMode.countdown) {
      // 倒计时显示剩余时间
      final remaining = (widget.targetSeconds ?? 1800) - _elapsedSeconds;
      displayTime = _formatTime(remaining.clamp(0, 999999));
    } else if (widget.mode == PracticeMode.pomodoro) {
      // 番茄钟显示当前阶段剩余
      final phaseTotal = _isBreakTime ? 300 : 1500;
      final remaining = phaseTotal - _pomodoroPhaseSeconds;
      displayTime = _formatTime(remaining.clamp(0, 999999));
    } else {
      // 自由模式显示已用时间
      displayTime = _formatTime(_elapsedSeconds);
    }

    return Column(
      children: [
        Text(
          displayTime,
          style: TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.w200,
            color: Colors.white.withValues(alpha: _isPaused ? 0.4 : 0.95),
            fontFeatures: const [FontFeature.tabularFigures()],
            letterSpacing: 4,
          ),
        ),
        if (_isPaused)
          Text(
            '已暂停',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.5),
              letterSpacing: 2,
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
            .fadeIn(duration: 800.ms)
            .fadeOut(duration: 800.ms),
      ],
    );
  }

  Widget _buildPomodoroInfo() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 轮次指示器
          ...List.generate(widget.pomodoroRounds ?? 2, (index) {
            final isCurrentRound = index + 1 == _currentPomodoroRound;
            final isCompleted = index + 1 < _currentPomodoroRound;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                width: isCurrentRound ? 28 : 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.white.withValues(alpha: 0.6)
                      : isCurrentRound
                          ? Colors.white.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            );
          }),
          const SizedBox(width: 12),
          Text(
            _isBreakTime ? '休息中' : '第$_currentPomodoroRound轮',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoal() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 20, 40, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.flag_rounded,
              size: 16,
              color: Colors.white.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.goal!,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 结束按钮
        GestureDetector(
          onTap: _showEndConfirmDialog,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(
              Icons.stop_rounded,
              color: Colors.white.withValues(alpha: 0.7),
              size: 28,
            ),
          ),
        ),
        
        const SizedBox(width: 32),
        
        // 暂停/继续按钮
        GestureDetector(
          onTap: _togglePause,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: _isPaused ? 0.25 : 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(
              _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
        
        const SizedBox(width: 32),
        
        // 占位（保持对称）
        const SizedBox(width: 56, height: 56),
      ],
    ).animate(delay: 300.ms).fadeIn();
  }
}
