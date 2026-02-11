import 'package:flutter/material.dart';

/// 成就类型
enum AchievementType {
  streak,       // 连续打卡
  practice,     // 练习相关
  skill,        // 技能相关
  mastery,      // 精通相关
  explorer,     // 探索相关
  special,      // 特殊成就
}

extension AchievementTypeExtension on AchievementType {
  String get displayName {
    switch (this) {
      case AchievementType.streak:
        return '坚持不懈';
      case AchievementType.practice:
        return '勤学苦练';
      case AchievementType.skill:
        return '博学多才';
      case AchievementType.mastery:
        return '登峰造极';
      case AchievementType.explorer:
        return '探索之路';
      case AchievementType.special:
        return '特殊成就';
    }
  }

  Color get color {
    switch (this) {
      case AchievementType.streak:
        return const Color(0xFFFF6B6B);
      case AchievementType.practice:
        return const Color(0xFF7ED6DF);
      case AchievementType.skill:
        return const Color(0xFF6BCB77);
      case AchievementType.mastery:
        return const Color(0xFFFFB347);
      case AchievementType.explorer:
        return const Color(0xFF9B89B3);
      case AchievementType.special:
        return const Color(0xFFFF6B9D);
    }
  }
}

/// 成就稀有度
enum AchievementRarity {
  common,      // 普通
  rare,        // 稀有
  epic,        // 史诗
  legendary,   // 传说
}

extension AchievementRarityExtension on AchievementRarity {
  String get displayName {
    switch (this) {
      case AchievementRarity.common:
        return '普通';
      case AchievementRarity.rare:
        return '稀有';
      case AchievementRarity.epic:
        return '史诗';
      case AchievementRarity.legendary:
        return '传说';
    }
  }

  Color get color {
    switch (this) {
      case AchievementRarity.common:
        return const Color(0xFF95A5A6);
      case AchievementRarity.rare:
        return const Color(0xFF3498DB);
      case AchievementRarity.epic:
        return const Color(0xFF9B59B6);
      case AchievementRarity.legendary:
        return const Color(0xFFE67E22);
    }
  }

  List<Color> get gradientColors {
    switch (this) {
      case AchievementRarity.common:
        return [const Color(0xFF95A5A6), const Color(0xFFBDC3C7)];
      case AchievementRarity.rare:
        return [const Color(0xFF2980B9), const Color(0xFF3498DB)];
      case AchievementRarity.epic:
        return [const Color(0xFF8E44AD), const Color(0xFF9B59B6)];
      case AchievementRarity.legendary:
        return [const Color(0xFFE67E22), const Color(0xFFF39C12)];
    }
  }
}

/// 成就定义
class Achievement {
  final String id;
  final String name;
  final String description;
  final String iconName;        // 使用字符串标识图标
  final AchievementType type;
  final AchievementRarity rarity;
  final int targetValue;        // 达成目标值
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int currentProgress;    // 当前进度

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.type,
    required this.rarity,
    required this.targetValue,
    this.isUnlocked = false,
    this.unlockedAt,
    this.currentProgress = 0,
  });

  double get progressPercent {
    if (targetValue == 0) return 0;
    return (currentProgress / targetValue).clamp(0.0, 1.0);
  }

  IconData get icon {
    switch (iconName) {
      case 'local_fire_department':
        return Icons.local_fire_department_rounded;
      case 'bolt':
        return Icons.bolt_rounded;
      case 'rocket_launch':
        return Icons.rocket_launch_rounded;
      case 'military_tech':
        return Icons.military_tech_rounded;
      case 'emoji_events':
        return Icons.emoji_events_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'stars':
        return Icons.stars_rounded;
      case 'diamond':
        return Icons.diamond_rounded;
      case 'timer':
        return Icons.timer_rounded;
      case 'calendar_month':
        return Icons.calendar_month_rounded;
      case 'auto_awesome':
        return Icons.auto_awesome_rounded;
      case 'workspace_premium':
        return Icons.workspace_premium_rounded;
      case 'diversity_3':
        return Icons.diversity_3_rounded;
      case 'psychology':
        return Icons.psychology_rounded;
      case 'nightlight':
        return Icons.nightlight_rounded;
      case 'wb_sunny':
        return Icons.wb_sunny_rounded;
      case 'all_inclusive':
        return Icons.all_inclusive_rounded;
      case 'self_improvement':
        return Icons.self_improvement_rounded;
      case 'water_drop':
        return Icons.water_drop_rounded;
      case 'spa':
        return Icons.spa_rounded;
      case 'waves':
        return Icons.waves_rounded;
      case 'center_focus_strong':
        return Icons.center_focus_strong_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }

  Achievement copyWith({
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? currentProgress,
  }) {
    return Achievement(
      id: id,
      name: name,
      description: description,
      iconName: iconName,
      type: type,
      rarity: rarity,
      targetValue: targetValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      currentProgress: currentProgress ?? this.currentProgress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'currentProgress': currentProgress,
    };
  }
}

/// 所有成就定义
class AchievementDefinitions {
  static List<Achievement> get all => [
    // === 连续打卡类 ===
    const Achievement(
      id: 'streak_3',
      name: '初露锋芒',
      description: '连续打卡3天',
      iconName: 'local_fire_department',
      type: AchievementType.streak,
      rarity: AchievementRarity.common,
      targetValue: 3,
    ),
    const Achievement(
      id: 'streak_7',
      name: '一周战士',
      description: '连续打卡7天',
      iconName: 'bolt',
      type: AchievementType.streak,
      rarity: AchievementRarity.common,
      targetValue: 7,
    ),
    const Achievement(
      id: 'streak_30',
      name: '月度达人',
      description: '连续打卡30天',
      iconName: 'rocket_launch',
      type: AchievementType.streak,
      rarity: AchievementRarity.rare,
      targetValue: 30,
    ),
    const Achievement(
      id: 'streak_100',
      name: '百日不辍',
      description: '连续打卡100天',
      iconName: 'military_tech',
      type: AchievementType.streak,
      rarity: AchievementRarity.epic,
      targetValue: 100,
    ),
    const Achievement(
      id: 'streak_365',
      name: '全年无休',
      description: '连续打卡365天',
      iconName: 'all_inclusive',
      type: AchievementType.streak,
      rarity: AchievementRarity.legendary,
      targetValue: 365,
    ),

    // === 练习次数类 ===
    const Achievement(
      id: 'practice_10',
      name: '勤学好问',
      description: '累计练习10次',
      iconName: 'school',
      type: AchievementType.practice,
      rarity: AchievementRarity.common,
      targetValue: 10,
    ),
    const Achievement(
      id: 'practice_50',
      name: '半百修行',
      description: '累计练习50次',
      iconName: 'self_improvement',
      type: AchievementType.practice,
      rarity: AchievementRarity.rare,
      targetValue: 50,
    ),
    const Achievement(
      id: 'practice_100',
      name: '百炼成钢',
      description: '累计练习100次',
      iconName: 'diamond',
      type: AchievementType.practice,
      rarity: AchievementRarity.epic,
      targetValue: 100,
    ),

    // === 练习时长类 ===
    const Achievement(
      id: 'time_60',
      name: '一小时挑战',
      description: '单次练习60分钟',
      iconName: 'timer',
      type: AchievementType.practice,
      rarity: AchievementRarity.common,
      targetValue: 60,
    ),
    const Achievement(
      id: 'total_time_600',
      name: '十小时积累',
      description: '累计练习时长达600分钟',
      iconName: 'timer',
      type: AchievementType.practice,
      rarity: AchievementRarity.rare,
      targetValue: 600,
    ),
    const Achievement(
      id: 'total_time_6000',
      name: '百小时大师',
      description: '累计练习时长达6000分钟',
      iconName: 'timer',
      type: AchievementType.practice,
      rarity: AchievementRarity.legendary,
      targetValue: 6000,
    ),

    // === 技能数量类 ===
    const Achievement(
      id: 'skill_3',
      name: '三项全能',
      description: '同时追踪3个技能',
      iconName: 'diversity_3',
      type: AchievementType.skill,
      rarity: AchievementRarity.common,
      targetValue: 3,
    ),
    const Achievement(
      id: 'skill_5',
      name: '五花八门',
      description: '同时追踪5个技能',
      iconName: 'stars',
      type: AchievementType.skill,
      rarity: AchievementRarity.rare,
      targetValue: 5,
    ),
    const Achievement(
      id: 'skill_10',
      name: '技多不压身',
      description: '同时追踪10个技能',
      iconName: 'auto_awesome',
      type: AchievementType.skill,
      rarity: AchievementRarity.epic,
      targetValue: 10,
    ),

    // === 精通类 ===
    const Achievement(
      id: 'mastery_80',
      name: '炉火纯青',
      description: '任一技能熟练度达到80%',
      iconName: 'emoji_events',
      type: AchievementType.mastery,
      rarity: AchievementRarity.rare,
      targetValue: 80,
    ),
    const Achievement(
      id: 'mastery_95',
      name: '登峰造极',
      description: '任一技能熟练度达到95%',
      iconName: 'workspace_premium',
      type: AchievementType.mastery,
      rarity: AchievementRarity.legendary,
      targetValue: 95,
    ),

    // === 探索类 ===
    const Achievement(
      id: 'category_all',
      name: '全面发展',
      description: '每个分类都至少有1个技能',
      iconName: 'psychology',
      type: AchievementType.explorer,
      rarity: AchievementRarity.epic,
      targetValue: 7,
    ),

    // === 特殊类 ===
    const Achievement(
      id: 'rescue',
      name: '力挽狂澜',
      description: '将一个"严重衰退"的技能恢复到"良好"',
      iconName: 'rocket_launch',
      type: AchievementType.special,
      rarity: AchievementRarity.epic,
      targetValue: 1,
    ),
    const Achievement(
      id: 'night_owl',
      name: '夜猫子',
      description: '在凌晨0-5点练习',
      iconName: 'nightlight',
      type: AchievementType.special,
      rarity: AchievementRarity.rare,
      targetValue: 1,
    ),
    const Achievement(
      id: 'early_bird',
      name: '早起的鸟儿',
      description: '在早上5-7点练习',
      iconName: 'wb_sunny',
      type: AchievementType.special,
      rarity: AchievementRarity.rare,
      targetValue: 1,
    ),

    // === 心流类 ===
    const Achievement(
      id: 'flow_first',
      name: '初入心流',
      description: '首次进入心流状态',
      iconName: 'water_drop',
      type: AchievementType.special,
      rarity: AchievementRarity.rare,
      targetValue: 1,
    ),
    const Achievement(
      id: 'deep_flow_first',
      name: '深度沉浸',
      description: '首次进入深度心流状态',
      iconName: 'waves',
      type: AchievementType.special,
      rarity: AchievementRarity.epic,
      targetValue: 1,
    ),
    const Achievement(
      id: 'flow_30min',
      name: '心流半小时',
      description: '单次心流状态持续30分钟',
      iconName: 'spa',
      type: AchievementType.special,
      rarity: AchievementRarity.epic,
      targetValue: 30,
    ),
    const Achievement(
      id: 'flow_60min',
      name: '心流大师',
      description: '单次心流状态持续60分钟',
      iconName: 'center_focus_strong',
      type: AchievementType.special,
      rarity: AchievementRarity.legendary,
      targetValue: 60,
    ),
  ];
}
