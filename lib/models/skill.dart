import 'package:flutter/material.dart';

/// 技能类型枚举
enum SkillCategory {
  music,      // 音乐类：乐器、唱歌
  language,   // 语言类：外语、编程语言
  sports,     // 运动类：健身、球类
  art,        // 艺术类：画画、摄影
  cooking,    // 烹饪类
  tech,       // 技术类：编程、设计软件
  other,      // 其他
}

extension SkillCategoryExtension on SkillCategory {
  String get displayName {
    switch (this) {
      case SkillCategory.music:
        return '音乐';
      case SkillCategory.language:
        return '语言';
      case SkillCategory.sports:
        return '运动';
      case SkillCategory.art:
        return '艺术';
      case SkillCategory.cooking:
        return '烹饪';
      case SkillCategory.tech:
        return '技术';
      case SkillCategory.other:
        return '其他';
    }
  }

  IconData get icon {
    switch (this) {
      case SkillCategory.music:
        return Icons.music_note_rounded;
      case SkillCategory.language:
        return Icons.translate_rounded;
      case SkillCategory.sports:
        return Icons.fitness_center_rounded;
      case SkillCategory.art:
        return Icons.palette_rounded;
      case SkillCategory.cooking:
        return Icons.restaurant_rounded;
      case SkillCategory.tech:
        return Icons.code_rounded;
      case SkillCategory.other:
        return Icons.category_rounded;
    }
  }

  Color get color {
    switch (this) {
      case SkillCategory.music:
        return const Color(0xFFFF6B9D);
      case SkillCategory.language:
        return const Color(0xFF7ED6DF);
      case SkillCategory.sports:
        return const Color(0xFF6BCB77);
      case SkillCategory.art:
        return const Color(0xFFFFB347);
      case SkillCategory.cooking:
        return const Color(0xFFFF6B6B);
      case SkillCategory.tech:
        return const Color(0xFF9B89B3);
      case SkillCategory.other:
        return const Color(0xFF74B9FF);
    }
  }

  /// 衰退系数：越高衰退越快
  double get decayFactor {
    switch (this) {
      case SkillCategory.music:
        return 0.8;  // 身体记忆，衰退慢
      case SkillCategory.language:
        return 1.3;  // 知识记忆，衰退快
      case SkillCategory.sports:
        return 0.7;  // 身体记忆，衰退最慢
      case SkillCategory.art:
        return 1.0;  // 混合类型
      case SkillCategory.cooking:
        return 0.9;  // 动手技能
      case SkillCategory.tech:
        return 1.2;  // 知识类，衰退较快
      case SkillCategory.other:
        return 1.0;
    }
  }
}

/// 技能状态枚举
enum SkillStatus {
  excellent,   // 优秀：熟练度 > 80%
  good,        // 良好：60-80%
  rusty,       // 生锈中：40-60%
  declining,   // 衰退中：20-40%
  critical,    // 严重衰退：< 20%
}

extension SkillStatusExtension on SkillStatus {
  String get displayName {
    switch (this) {
      case SkillStatus.excellent:
        return '状态极佳';
      case SkillStatus.good:
        return '良好';
      case SkillStatus.rusty:
        return '有点生锈';
      case SkillStatus.declining:
        return '衰退中';
      case SkillStatus.critical:
        return '严重衰退';
    }
  }

  Color get color {
    switch (this) {
      case SkillStatus.excellent:
        return const Color(0xFF6BCB77);
      case SkillStatus.good:
        return const Color(0xFF7ED6DF);
      case SkillStatus.rusty:
        return const Color(0xFFFFB347);
      case SkillStatus.declining:
        return const Color(0xFFFF8C42);
      case SkillStatus.critical:
        return const Color(0xFFFF6B6B);
    }
  }

  IconData get icon {
    switch (this) {
      case SkillStatus.excellent:
        return Icons.star_rounded;
      case SkillStatus.good:
        return Icons.thumb_up_rounded;
      case SkillStatus.rusty:
        return Icons.warning_amber_rounded;
      case SkillStatus.declining:
        return Icons.trending_down_rounded;
      case SkillStatus.critical:
        return Icons.error_rounded;
    }
  }
}

/// 技能模型
class Skill {
  final String id;
  final String name;
  final SkillCategory category;
  final String? description;
  final double peakProficiency;     // 巅峰熟练度 (0-100)
  final double currentProficiency;  // 当前熟练度 (0-100)
  final DateTime createdAt;
  final DateTime lastPracticeAt;
  final int targetPracticePerWeek;  // 每周目标练习次数
  final int practiceMinutes;        // 建议每次练习时长（分钟）
  final List<PracticeRecord> practiceHistory;

  const Skill({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    this.peakProficiency = 50,
    this.currentProficiency = 50,
    required this.createdAt,
    required this.lastPracticeAt,
    this.targetPracticePerWeek = 2,
    this.practiceMinutes = 30,
    this.practiceHistory = const [],
  });

  /// 计算技能状态
  SkillStatus get status {
    final ratio = currentProficiency / 100;
    if (ratio > 0.8) return SkillStatus.excellent;
    if (ratio > 0.6) return SkillStatus.good;
    if (ratio > 0.4) return SkillStatus.rusty;
    if (ratio > 0.2) return SkillStatus.declining;
    return SkillStatus.critical;
  }

  /// 计算距离上次练习的天数
  int get daysSinceLastPractice {
    return DateTime.now().difference(lastPracticeAt).inDays;
  }

  /// 格式化距离上次练习的时间
  String get lastPracticeText {
    final days = daysSinceLastPractice;
    if (days == 0) return '今天';
    if (days == 1) return '昨天';
    if (days < 7) return '$days天前';
    if (days < 30) return '${days ~/ 7}周前';
    if (days < 365) return '${days ~/ 30}个月前';
    return '${days ~/ 365}年前';
  }

  /// 计算每周衰退率
  double get weeklyDecayRate {
    return 2.0 * category.decayFactor;
  }

  /// 是否需要练习提醒
  bool get needsReminder {
    final daysSinceTarget = 7 ~/ targetPracticePerWeek;
    return daysSinceLastPractice >= daysSinceTarget;
  }

  Skill copyWith({
    String? id,
    String? name,
    SkillCategory? category,
    String? description,
    double? peakProficiency,
    double? currentProficiency,
    DateTime? createdAt,
    DateTime? lastPracticeAt,
    int? targetPracticePerWeek,
    int? practiceMinutes,
    List<PracticeRecord>? practiceHistory,
  }) {
    return Skill(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      peakProficiency: peakProficiency ?? this.peakProficiency,
      currentProficiency: currentProficiency ?? this.currentProficiency,
      createdAt: createdAt ?? this.createdAt,
      lastPracticeAt: lastPracticeAt ?? this.lastPracticeAt,
      targetPracticePerWeek: targetPracticePerWeek ?? this.targetPracticePerWeek,
      practiceMinutes: practiceMinutes ?? this.practiceMinutes,
      practiceHistory: practiceHistory ?? this.practiceHistory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.index,
      'description': description,
      'peakProficiency': peakProficiency,
      'currentProficiency': currentProficiency,
      'createdAt': createdAt.toIso8601String(),
      'lastPracticeAt': lastPracticeAt.toIso8601String(),
      'targetPracticePerWeek': targetPracticePerWeek,
      'practiceMinutes': practiceMinutes,
      'practiceHistory': practiceHistory.map((e) => e.toJson()).toList(),
    };
  }

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: json['id'],
      name: json['name'],
      category: SkillCategory.values[json['category']],
      description: json['description'],
      peakProficiency: (json['peakProficiency'] as num).toDouble(),
      currentProficiency: (json['currentProficiency'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      lastPracticeAt: DateTime.parse(json['lastPracticeAt']),
      targetPracticePerWeek: json['targetPracticePerWeek'] ?? 2,
      practiceMinutes: json['practiceMinutes'] ?? 30,
      practiceHistory: (json['practiceHistory'] as List?)
          ?.map((e) => PracticeRecord.fromJson(e))
          .toList() ?? [],
    );
  }
}

/// 练习记录
class PracticeRecord {
  final String id;
  final DateTime date;
  final int durationMinutes;
  final String? note;
  final double proficiencyAfter;  // 练习后的熟练度
  final int highestFlowState;     // 最高心流状态 0-3
  final int maxFlowMinutes;       // 最长连续心流时长(分钟)
  final int mood;                 // 练习心情 0-4 (-1表示未记录)
  final String? practiceGoal;     // 练习目标
  final double flowMultiplier;    // 心流加成倍率

  const PracticeRecord({
    required this.id,
    required this.date,
    required this.durationMinutes,
    this.note,
    required this.proficiencyAfter,
    this.highestFlowState = 0,
    this.maxFlowMinutes = 0,
    this.mood = -1,
    this.practiceGoal,
    this.flowMultiplier = 1.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'durationMinutes': durationMinutes,
      'note': note,
      'proficiencyAfter': proficiencyAfter,
      'highestFlowState': highestFlowState,
      'maxFlowMinutes': maxFlowMinutes,
      'mood': mood,
      'practiceGoal': practiceGoal,
      'flowMultiplier': flowMultiplier,
    };
  }

  factory PracticeRecord.fromJson(Map<String, dynamic> json) {
    return PracticeRecord(
      id: json['id'],
      date: DateTime.parse(json['date']),
      durationMinutes: json['durationMinutes'],
      note: json['note'],
      proficiencyAfter: (json['proficiencyAfter'] as num).toDouble(),
      highestFlowState: json['highestFlowState'] ?? 0,
      maxFlowMinutes: json['maxFlowMinutes'] ?? 0,
      mood: json['mood'] ?? -1,
      practiceGoal: json['practiceGoal'],
      flowMultiplier: (json['flowMultiplier'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
