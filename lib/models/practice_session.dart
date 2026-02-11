import 'package:flutter/material.dart';

/// 练习模式
enum PracticeMode {
  free,       // 自由模式 - 正计时
  countdown,  // 目标模式 - 倒计时
  pomodoro,   // 番茄钟模式
}

extension PracticeModeExtension on PracticeMode {
  String get displayName {
    switch (this) {
      case PracticeMode.free:
        return '自由模式';
      case PracticeMode.countdown:
        return '目标模式';
      case PracticeMode.pomodoro:
        return '番茄钟';
    }
  }

  String get description {
    switch (this) {
      case PracticeMode.free:
        return '不限时间，随心练习';
      case PracticeMode.countdown:
        return '设定目标时长，专注完成';
      case PracticeMode.pomodoro:
        return '25分钟专注 + 5分钟休息';
    }
  }

  IconData get icon {
    switch (this) {
      case PracticeMode.free:
        return Icons.all_inclusive_rounded;
      case PracticeMode.countdown:
        return Icons.timer_rounded;
      case PracticeMode.pomodoro:
        return Icons.spa_rounded;
    }
  }
}

/// 心流状态
enum FlowState {
  warmup,     // 预热 0-5分钟
  focus,      // 专注 5-15分钟
  flow,       // 心流 15-30分钟
  deepFlow,   // 深度心流 30分钟+
}

extension FlowStateExtension on FlowState {
  String get displayName {
    switch (this) {
      case FlowState.warmup:
        return '预热中';
      case FlowState.focus:
        return '专注中';
      case FlowState.flow:
        return '心流状态';
      case FlowState.deepFlow:
        return '深度心流';
    }
  }

  String get subtitle {
    switch (this) {
      case FlowState.warmup:
        return '正在进入状态...';
      case FlowState.focus:
        return '注意力逐渐集中';
      case FlowState.flow:
        return '完全沉浸其中';
      case FlowState.deepFlow:
        return '忘我的境界';
    }
  }

  IconData get icon {
    switch (this) {
      case FlowState.warmup:
        return Icons.wb_twilight_rounded;
      case FlowState.focus:
        return Icons.center_focus_strong_rounded;
      case FlowState.flow:
        return Icons.water_drop_rounded;
      case FlowState.deepFlow:
        return Icons.auto_awesome_rounded;
    }
  }

  /// 熟练度加成倍率
  double get multiplier {
    switch (this) {
      case FlowState.warmup:
        return 1.0;
      case FlowState.focus:
        return 1.0;
      case FlowState.flow:
        return 1.5;
      case FlowState.deepFlow:
        return 2.0;
    }
  }

  /// 达到该状态需要的连续专注分钟数
  int get requiredMinutes {
    switch (this) {
      case FlowState.warmup:
        return 0;
      case FlowState.focus:
        return 5;
      case FlowState.flow:
        return 15;
      case FlowState.deepFlow:
        return 30;
    }
  }

  /// 背景渐变色
  List<Color> get backgroundColors {
    switch (this) {
      case FlowState.warmup:
        return const [Color(0xFF1A1A2E), Color(0xFF16213E)];
      case FlowState.focus:
        return const [Color(0xFF16213E), Color(0xFF0F3460)];
      case FlowState.flow:
        return const [Color(0xFF0F3460), Color(0xFF533483)];
      case FlowState.deepFlow:
        return const [Color(0xFF2D1B69), Color(0xFF11998E)];
    }
  }
}

/// 练习会话数据（传递给回顾页面）
class PracticeSessionData {
  final int totalSeconds;             // 总练习秒数
  final int maxFlowSeconds;           // 最长连续心流秒数（flow+deepFlow）
  final FlowState highestFlowState;   // 达到的最高心流状态
  final PracticeMode mode;
  final String? goal;
  final int pauseCount;               // 暂停次数
  
  // 各阶段花费的秒数
  final int warmupSeconds;
  final int focusSeconds;
  final int flowSeconds;
  final int deepFlowSeconds;

  const PracticeSessionData({
    required this.totalSeconds,
    required this.maxFlowSeconds,
    required this.highestFlowState,
    required this.mode,
    this.goal,
    this.pauseCount = 0,
    this.warmupSeconds = 0,
    this.focusSeconds = 0,
    this.flowSeconds = 0,
    this.deepFlowSeconds = 0,
  });

  int get totalMinutes => totalSeconds ~/ 60;

  /// 计算综合心流加成倍率
  double get flowMultiplier {
    if (totalSeconds == 0) return 1.0;
    final weighted = warmupSeconds * FlowState.warmup.multiplier +
        focusSeconds * FlowState.focus.multiplier +
        flowSeconds * FlowState.flow.multiplier +
        deepFlowSeconds * FlowState.deepFlow.multiplier;
    return weighted / totalSeconds;
  }
}
