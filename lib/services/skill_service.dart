import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/skill.dart';
import '../models/achievement.dart';

class SkillService extends ChangeNotifier {
  List<Skill> _skills = [];
  List<Achievement> _achievements = [];
  bool _isLoading = false;
  final _uuid = const Uuid();
  
  // 连续打卡
  int _currentStreak = 0;
  int _longestStreak = 0;
  DateTime? _lastPracticeDate;  // 最后一次打卡的日期（只看日期，不看时间）

  // 力挽狂澜成就标记：是否曾将严重衰退技能恢复到良好或以上
  bool _hasRescued = false;

  List<Skill> get skills => _skills;
  List<Achievement> get achievements => _achievements;
  bool get isLoading => _isLoading;
  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  
  /// 获取已解锁的成就
  List<Achievement> get unlockedAchievements =>
      _achievements.where((a) => a.isUnlocked).toList();

  /// 获取未解锁的成就
  List<Achievement> get lockedAchievements =>
      _achievements.where((a) => !a.isUnlocked).toList();

  /// 今天是否已打卡
  bool get hasPracticedToday {
    if (_lastPracticeDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(
      _lastPracticeDate!.year, 
      _lastPracticeDate!.month, 
      _lastPracticeDate!.day,
    );
    return today.isAtSameMomentAs(lastDate);
  }
  
  /// 获取需要提醒的技能
  List<Skill> get skillsNeedingAttention {
    return _skills.where((s) => s.needsReminder).toList()
      ..sort((a, b) => b.daysSinceLastPractice.compareTo(a.daysSinceLastPractice));
  }

  /// 获取按状态分组的技能
  Map<SkillStatus, List<Skill>> get skillsByStatus {
    final map = <SkillStatus, List<Skill>>{};
    for (final status in SkillStatus.values) {
      map[status] = _skills.where((s) => s.status == status).toList();
    }
    return map;
  }

  /// 获取今日推荐练习的技能（最多3个）
  List<Skill> get dailyRecommendations {
    if (_skills.isEmpty) return [];
    
    // 按优先级排序：衰退严重 > 临近目标提醒 > 长时间未练习
    final sorted = List<Skill>.from(_skills);
    sorted.sort((a, b) {
      // 状态越差优先级越高
      final statusA = a.status.index;
      final statusB = b.status.index;
      if (statusA != statusB) return statusB.compareTo(statusA);
      
      // 相同状态下，越久没练越优先
      return b.daysSinceLastPractice.compareTo(a.daysSinceLastPractice);
    });
    
    return sorted.take(3).toList();
  }

  /// 获取各分类的平均熟练度（用于雷达图）
  Map<SkillCategory, double> get categoryProficiency {
    final map = <SkillCategory, double>{};
    for (final category in SkillCategory.values) {
      final categorySkills = _skills.where((s) => s.category == category).toList();
      if (categorySkills.isEmpty) {
        map[category] = 0;
      } else {
        map[category] = categorySkills.fold<double>(
          0, (sum, s) => sum + s.currentProficiency) / categorySkills.length;
      }
    }
    return map;
  }

  /// 获取所有打卡日期（用于热力图）
  Map<DateTime, int> get practiceHeatMap {
    final map = <DateTime, int>{};
    for (final skill in _skills) {
      for (final record in skill.practiceHistory) {
        final date = DateTime(record.date.year, record.date.month, record.date.day);
        map[date] = (map[date] ?? 0) + 1;
      }
    }
    return map;
  }

  /// 获取统计数据
  Map<String, dynamic> get statistics {
    if (_skills.isEmpty) {
      return {
        'totalSkills': 0,
        'averageProficiency': 0.0,
        'skillsInDanger': 0,
        'totalPracticeMinutes': 0,
        'totalPracticeCount': 0,
        'currentStreak': _currentStreak,
        'longestStreak': _longestStreak,
      };
    }

    final totalProficiency = _skills.fold<double>(
      0, (sum, skill) => sum + skill.currentProficiency);
    
    final skillsInDanger = _skills.where(
      (s) => s.status == SkillStatus.declining || s.status == SkillStatus.critical
    ).length;

    final totalPracticeMinutes = _skills.fold<int>(
      0, (sum, skill) => sum + skill.practiceHistory.fold<int>(
        0, (s, r) => s + r.durationMinutes));

    final totalPracticeCount = _skills.fold<int>(
      0, (sum, skill) => sum + skill.practiceHistory.length);

    return {
      'totalSkills': _skills.length,
      'averageProficiency': totalProficiency / _skills.length,
      'skillsInDanger': skillsInDanger,
      'totalPracticeMinutes': totalPracticeMinutes,
      'totalPracticeCount': totalPracticeCount,
      'currentStreak': _currentStreak,
      'longestStreak': _longestStreak,
    };
  }

  SkillService() {
    _loadAll();
  }

  Future<void> _loadAll() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadSkills();
      await _loadStreakData();
      _initAchievements();
      await _loadAchievementProgress();
      _updateAllAchievements();
    } catch (e) {
      debugPrint('Error loading data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 从本地存储加载技能
  Future<void> _loadSkills() async {
      final prefs = await SharedPreferences.getInstance();
      final skillsJson = prefs.getString('skills');
      
      if (skillsJson != null) {
        final List<dynamic> decoded = json.decode(skillsJson);
        _skills = decoded.map((e) => Skill.fromJson(e)).toList();
        
        // 更新所有技能的衰退
        _updateAllSkillsDecay();
      } else {
        // 添加示例技能
        _skills = _getSampleSkills();
        await _saveSkills();
      }
  }

  /// 加载连续打卡数据
  Future<void> _loadStreakData() async {
    final prefs = await SharedPreferences.getInstance();
    _currentStreak = prefs.getInt('currentStreak') ?? 0;
    _longestStreak = prefs.getInt('longestStreak') ?? 0;
    _hasRescued = prefs.getBool('hasRescued') ?? false;
    final lastDateStr = prefs.getString('lastPracticeDate');
    if (lastDateStr != null) {
      _lastPracticeDate = DateTime.parse(lastDateStr);
    }
    
    // 检查连续打卡是否已断
    _checkStreakContinuity();
  }

  /// 保存连续打卡数据
  Future<void> _saveStreakData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentStreak', _currentStreak);
    await prefs.setInt('longestStreak', _longestStreak);
    await prefs.setBool('hasRescued', _hasRescued);
    if (_lastPracticeDate != null) {
      await prefs.setString('lastPracticeDate', _lastPracticeDate!.toIso8601String());
    }
  }

  /// 检查连续打卡是否中断
  void _checkStreakContinuity() {
    if (_lastPracticeDate == null) {
      _currentStreak = 0;
      return;
    }
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(
      _lastPracticeDate!.year, 
      _lastPracticeDate!.month, 
      _lastPracticeDate!.day,
    );
    
    final diff = today.difference(lastDate).inDays;
    if (diff > 1) {
      // 超过1天未打卡，连续打卡中断
      _currentStreak = 0;
    }
  }

  /// 更新连续打卡
  void _updateStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (_lastPracticeDate == null) {
      _currentStreak = 1;
      _lastPracticeDate = now;
    } else {
      final lastDate = DateTime(
        _lastPracticeDate!.year, 
        _lastPracticeDate!.month, 
        _lastPracticeDate!.day,
      );
      
      final diff = today.difference(lastDate).inDays;
      
      if (diff == 0) {
        // 今天已经打过卡了，不重复计算
        return;
      } else if (diff == 1) {
        // 连续打卡
        _currentStreak++;
      } else {
        // 中断了，重新开始
        _currentStreak = 1;
      }
      
      _lastPracticeDate = now;
    }
    
    if (_currentStreak > _longestStreak) {
      _longestStreak = _currentStreak;
    }
  }

  /// 初始化成就列表
  void _initAchievements() {
    _achievements = AchievementDefinitions.all;
  }

  /// 加载成就进度
  Future<void> _loadAchievementProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = prefs.getString('achievementProgress');
    
    if (progressJson != null) {
      final Map<String, dynamic> decoded = json.decode(progressJson);
      _achievements = _achievements.map((a) {
        if (decoded.containsKey(a.id)) {
          final data = decoded[a.id];
          return a.copyWith(
            isUnlocked: data['isUnlocked'] ?? false,
            unlockedAt: data['unlockedAt'] != null 
                ? DateTime.parse(data['unlockedAt']) 
                : null,
            currentProgress: data['currentProgress'] ?? 0,
          );
        }
        return a;
      }).toList();
    }
  }

  /// 保存成就进度
  Future<void> _saveAchievementProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, dynamic>{};
    for (final a in _achievements) {
      map[a.id] = a.toJson();
    }
    await prefs.setString('achievementProgress', json.encode(map));
  }

  /// 更新所有成就
  void _updateAllAchievements() {
    final stats = statistics;
    final now = DateTime.now();
    
    _achievements = _achievements.map((a) {
      if (a.isUnlocked) return a; // 已解锁不需要更新
      
      int progress = 0;
      bool unlocked = false;
      
      switch (a.id) {
        // 连续打卡类
        case 'streak_3':
        case 'streak_7':
        case 'streak_30':
        case 'streak_100':
        case 'streak_365':
          progress = _currentStreak;
          unlocked = _currentStreak >= a.targetValue;
          break;
          
        // 练习次数类
        case 'practice_10':
        case 'practice_50':
        case 'practice_100':
          progress = stats['totalPracticeCount'] as int;
          unlocked = progress >= a.targetValue;
          break;
          
        // 单次练习时长
        case 'time_60':
          // 检查是否有单次>=60分钟的练习
          int maxSingle = 0;
          for (final skill in _skills) {
            for (final r in skill.practiceHistory) {
              if (r.durationMinutes > maxSingle) maxSingle = r.durationMinutes;
            }
          }
          progress = maxSingle;
          unlocked = maxSingle >= 60;
          break;
          
        // 累计练习时长
        case 'total_time_600':
        case 'total_time_6000':
          progress = stats['totalPracticeMinutes'] as int;
          unlocked = progress >= a.targetValue;
          break;
          
        // 技能数量
        case 'skill_3':
        case 'skill_5':
        case 'skill_10':
          progress = _skills.length;
          unlocked = _skills.length >= a.targetValue;
          break;
          
        // 精通类
        case 'mastery_80':
          final maxProf = _skills.isEmpty ? 0.0 : 
              _skills.map((s) => s.currentProficiency).reduce((a, b) => a > b ? a : b);
          progress = maxProf.toInt();
          unlocked = maxProf >= 80;
          break;
        case 'mastery_95':
          final maxProf95 = _skills.isEmpty ? 0.0 :
              _skills.map((s) => s.currentProficiency).reduce((a, b) => a > b ? a : b);
          progress = maxProf95.toInt();
          unlocked = maxProf95 >= 95;
          break;
          
        // 分类覆盖
        case 'category_all':
          final coveredCategories = _skills.map((s) => s.category).toSet().length;
          progress = coveredCategories;
          unlocked = coveredCategories >= SkillCategory.values.length;
          break;
          
        // 特殊成就
        case 'night_owl':
          // 检查是否有凌晨0-5点的练习
          for (final skill in _skills) {
            for (final r in skill.practiceHistory) {
              if (r.date.hour >= 0 && r.date.hour < 5) {
                progress = 1;
                unlocked = true;
                break;
              }
            }
            if (unlocked) break;
          }
          break;
        case 'early_bird':
          // 检查是否有5-7点的练习
          for (final skill in _skills) {
            for (final r in skill.practiceHistory) {
              if (r.date.hour >= 5 && r.date.hour < 7) {
                progress = 1;
                unlocked = true;
                break;
              }
            }
            if (unlocked) break;
          }
          break;

        // 力挽狂澜
        case 'rescue':
          if (_hasRescued) {
            progress = 1;
            unlocked = true;
          }
          break;

        // 心流成就
        case 'flow_first':
          // 检查是否有任何练习达到了心流状态(index >= 2)
          for (final skill in _skills) {
            for (final r in skill.practiceHistory) {
              if (r.highestFlowState >= 2) {
                progress = 1;
                unlocked = true;
                break;
              }
            }
            if (unlocked) break;
          }
          break;
        case 'deep_flow_first':
          // 检查是否有任何练习达到了深度心流(index == 3)
          for (final skill in _skills) {
            for (final r in skill.practiceHistory) {
              if (r.highestFlowState >= 3) {
                progress = 1;
                unlocked = true;
                break;
              }
            }
            if (unlocked) break;
          }
          break;
        case 'flow_30min':
          // 最长单次心流分钟数 >= 30
          int maxFlowMin = 0;
          for (final skill in _skills) {
            for (final r in skill.practiceHistory) {
              if (r.maxFlowMinutes > maxFlowMin) maxFlowMin = r.maxFlowMinutes;
            }
          }
          progress = maxFlowMin;
          unlocked = maxFlowMin >= 30;
          break;
        case 'flow_60min':
          // 最长单次心流分钟数 >= 60
          int maxFlowMin60 = 0;
          for (final skill in _skills) {
            for (final r in skill.practiceHistory) {
              if (r.maxFlowMinutes > maxFlowMin60) maxFlowMin60 = r.maxFlowMinutes;
            }
          }
          progress = maxFlowMin60;
          unlocked = maxFlowMin60 >= 60;
          break;
      }
      
      return a.copyWith(
        currentProgress: progress,
        isUnlocked: unlocked,
        unlockedAt: unlocked ? now : null,
      );
    }).toList();
  }

  /// 检查是否有新解锁的成就，返回新解锁的列表
  List<Achievement> checkNewAchievements() {
    final beforeUnlocked = _achievements
        .where((a) => a.isUnlocked).map((a) => a.id).toSet();
    
    _updateAllAchievements();
    
    final newlyUnlocked = _achievements
        .where((a) => a.isUnlocked && !beforeUnlocked.contains(a.id))
        .toList();
    
    if (newlyUnlocked.isNotEmpty) {
      _saveAchievementProgress();
    }
    
    return newlyUnlocked;
  }

  /// 保存技能到本地存储
  Future<void> _saveSkills() async {
    final prefs = await SharedPreferences.getInstance();
    final skillsJson = json.encode(_skills.map((e) => e.toJson()).toList());
    await prefs.setString('skills', skillsJson);
  }

  /// 更新所有技能的衰退值
  void _updateAllSkillsDecay() {
    _skills = _skills.map((skill) => _calculateDecay(skill)).toList();
  }

  /// 计算技能衰退
  Skill _calculateDecay(Skill skill) {
    final daysSinceLastPractice = skill.daysSinceLastPractice;
    
    if (daysSinceLastPractice <= 0) {
      return skill;
    }

    const baseDecayRate = 0.3;
    
    double timeMultiplier;
    if (daysSinceLastPractice <= 7) {
      timeMultiplier = 0.5;
    } else if (daysSinceLastPractice <= 30) {
      timeMultiplier = 1.0;
    } else if (daysSinceLastPractice <= 90) {
      timeMultiplier = 1.5;
    } else {
      timeMultiplier = 0.5;
    }

    final totalDecay = baseDecayRate * skill.category.decayFactor * 
                       timeMultiplier * daysSinceLastPractice;
    
    final newProficiency = (skill.currentProficiency - totalDecay).clamp(10.0, 100.0);
    
    return skill.copyWith(currentProficiency: newProficiency);
  }

  /// 添加新技能
  Future<void> addSkill({
    required String name,
    required SkillCategory category,
    String? description,
    double initialProficiency = 50,
    int targetPracticePerWeek = 2,
    int practiceMinutes = 30,
  }) async {
    final now = DateTime.now();
    final newSkill = Skill(
      id: _uuid.v4(),
      name: name,
      category: category,
      description: description,
      peakProficiency: initialProficiency,
      currentProficiency: initialProficiency,
      createdAt: now,
      lastPracticeAt: now,
      targetPracticePerWeek: targetPracticePerWeek,
      practiceMinutes: practiceMinutes,
    );

    _skills.add(newSkill);
    await _saveSkills();
    
    // 检查成就
    checkNewAchievements();
    
    notifyListeners();
  }

  /// 更新技能
  Future<void> updateSkill(Skill updatedSkill) async {
    final index = _skills.indexWhere((s) => s.id == updatedSkill.id);
    if (index != -1) {
      _skills[index] = updatedSkill;
      await _saveSkills();
      notifyListeners();
    }
  }

  /// 删除技能
  Future<void> deleteSkill(String skillId) async {
    _skills.removeWhere((s) => s.id == skillId);
    await _saveSkills();
    notifyListeners();
  }

  /// 清除所有数据
  Future<void> clearAllData() async {
    _skills.clear();
    _achievements = AchievementDefinitions.all;
    _currentStreak = 0;
    _longestStreak = 0;
    _lastPracticeDate = null;
    _hasRescued = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('skills');
    await prefs.remove('currentStreak');
    await prefs.remove('longestStreak');
    await prefs.remove('lastPracticeDate');
    await prefs.remove('hasRescued');
    await prefs.remove('achievements');
    notifyListeners();
  }

  /// 记录练习
  Future<List<Achievement>> recordPractice({
    required String skillId,
    required int durationMinutes,
    String? note,
  }) async {
    final index = _skills.indexWhere((s) => s.id == skillId);
    if (index == -1) return [];

    final skill = _skills[index];
    
    // 记录练习前的状态（用于"力挽狂澜"成就）
    final statusBefore = skill.status;
    
    // 计算练习后的熟练度提升
    final baseImprovement = (durationMinutes / skill.practiceMinutes) * 5;
    final diminishingFactor = 1 - (skill.currentProficiency / 150);
    final improvement = baseImprovement * diminishingFactor;
    
    final newProficiency = (skill.currentProficiency + improvement).clamp(0.0, 100.0);
    final newPeakProficiency = newProficiency > skill.peakProficiency 
        ? newProficiency 
        : skill.peakProficiency;

    final record = PracticeRecord(
      id: _uuid.v4(),
      date: DateTime.now(),
      durationMinutes: durationMinutes,
      note: note,
      proficiencyAfter: newProficiency,
    );

    final updatedHistory = [...skill.practiceHistory, record];
    final updatedSkill = skill.copyWith(
      currentProficiency: newProficiency,
      peakProficiency: newPeakProficiency,
      lastPracticeAt: DateTime.now(),
      practiceHistory: updatedHistory,
    );

    _skills[index] = updatedSkill;
    
    // 更新连续打卡
    _updateStreak();
    
    await _saveSkills();
    await _saveStreakData();
    
    // 检查"力挽狂澜"成就：从严重衰退恢复到良好或以上
    if (statusBefore == SkillStatus.critical &&
        (updatedSkill.status == SkillStatus.good ||
         updatedSkill.status == SkillStatus.excellent)) {
      _hasRescued = true;
    }
    
    // 检查成就
    final newAchievements = checkNewAchievements();
    
    notifyListeners();
    
    return newAchievements;
  }

  /// 带心流数据的练习记录（从专注计时页面调用）
  Future<List<Achievement>> recordPracticeWithFlow({
    required String skillId,
    required int durationMinutes,
    String? note,
    int highestFlowState = 0,
    int maxFlowMinutes = 0,
    int mood = -1,
    String? practiceGoal,
    double flowMultiplier = 1.0,
  }) async {
    final index = _skills.indexWhere((s) => s.id == skillId);
    if (index == -1) return [];

    final skill = _skills[index];
    final statusBefore = skill.status;

    // 计算练习后的熟练度提升（含心流加成）
    final baseImprovement = (durationMinutes / skill.practiceMinutes) * 5;
    final diminishingFactor = 1 - (skill.currentProficiency / 150);
    final improvement = baseImprovement * diminishingFactor * flowMultiplier;

    final newProficiency = (skill.currentProficiency + improvement).clamp(0.0, 100.0);
    final newPeakProficiency = newProficiency > skill.peakProficiency
        ? newProficiency
        : skill.peakProficiency;

    final record = PracticeRecord(
      id: _uuid.v4(),
      date: DateTime.now(),
      durationMinutes: durationMinutes,
      note: note,
      proficiencyAfter: newProficiency,
      highestFlowState: highestFlowState,
      maxFlowMinutes: maxFlowMinutes,
      mood: mood,
      practiceGoal: practiceGoal,
      flowMultiplier: flowMultiplier,
    );

    final updatedHistory = [...skill.practiceHistory, record];
    final updatedSkill = skill.copyWith(
      currentProficiency: newProficiency,
      peakProficiency: newPeakProficiency,
      lastPracticeAt: DateTime.now(),
      practiceHistory: updatedHistory,
    );

    _skills[index] = updatedSkill;

    // 检查"力挽狂澜"成就：从严重衰退恢复到良好或以上
    if (statusBefore == SkillStatus.critical &&
        (updatedSkill.status == SkillStatus.good ||
         updatedSkill.status == SkillStatus.excellent)) {
      _hasRescued = true;
    }

    // 更新连续打卡
    _updateStreak();

    await _saveSkills();
    await _saveStreakData();

    // 检查成就
    final newAchievements = checkNewAchievements();

    notifyListeners();

    return newAchievements;
  }

  /// 根据ID获取技能
  Skill? getSkillById(String skillId) {
    try {
      return _skills.firstWhere((s) => s.id == skillId);
    } catch (e) {
      return null;
    }
  }

  /// 获取技能的熟练度历史（用于图表）
  List<Map<String, dynamic>> getProficiencyHistory(String skillId, {int days = 30}) {
    final skill = _skills.firstWhere((s) => s.id == skillId);
    final history = <Map<String, dynamic>>[];
    
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    
    final recordsByDate = <DateTime, PracticeRecord>{};
    for (final record in skill.practiceHistory) {
      final date = DateTime(record.date.year, record.date.month, record.date.day);
      if (date.isAfter(startDate) || date.isAtSameMomentAs(startDate)) {
        recordsByDate[date] = record;
      }
    }

    double proficiency = skill.peakProficiency;
    for (int i = days; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = DateTime(date.year, date.month, date.day);
      
      if (recordsByDate.containsKey(dateKey)) {
        proficiency = recordsByDate[dateKey]!.proficiencyAfter;
      } else {
        proficiency = (proficiency - 0.3 * skill.category.decayFactor).clamp(10.0, 100.0);
      }
      
      history.add({
        'date': date,
        'proficiency': proficiency,
      });
    }

    return history;
  }

  /// 获取最近N天每天的总练习时长
  Map<DateTime, int> getDailyPracticeMinutes({int days = 30}) {
    final map = <DateTime, int>{};
    final now = DateTime.now();

    for (int i = days; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      map[date] = 0;
    }

    for (final skill in _skills) {
      for (final record in skill.practiceHistory) {
        final date = DateTime(record.date.year, record.date.month, record.date.day);
        if (map.containsKey(date)) {
          map[date] = map[date]! + record.durationMinutes;
        }
      }
    }

    return map;
  }

  /// 最近 8 周每周的心流时长（分钟），[本周, 上周, ..., 8周前]
  List<int> getWeeklyFlowMinutes() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // 本周一 00:00
    final currentWeekStart = today.subtract(Duration(days: now.weekday - 1));
    final weekStarts = List.generate(8, (i) => currentWeekStart.subtract(Duration(days: 7 * i)));
    final totals = List.filled(8, 0);

    for (final skill in _skills) {
      for (final record in skill.practiceHistory) {
        final d = record.date;
        final recordDay = DateTime(d.year, d.month, d.day);
        final recordWeekStart = recordDay.subtract(Duration(days: d.weekday - 1));
        for (int i = 0; i < 8; i++) {
          if (recordWeekStart == weekStarts[i]) {
            totals[i] += record.maxFlowMinutes;
            break;
          }
        }
      }
    }
    return totals;
  }

  /// 获取示例技能
  List<Skill> _getSampleSkills() {
    final now = DateTime.now();
    return [
      Skill(
        id: _uuid.v4(),
        name: '吉他',
        category: SkillCategory.music,
        description: '木吉他弹唱',
        peakProficiency: 75,
        currentProficiency: 58,
        createdAt: now.subtract(const Duration(days: 180)),
        lastPracticeAt: now.subtract(const Duration(days: 23)),
        targetPracticePerWeek: 3,
        practiceMinutes: 30,
      ),
      Skill(
        id: _uuid.v4(),
        name: '日语',
        category: SkillCategory.language,
        description: 'N3水平',
        peakProficiency: 65,
        currentProficiency: 35,
        createdAt: now.subtract(const Duration(days: 365)),
        lastPracticeAt: now.subtract(const Duration(days: 67)),
        targetPracticePerWeek: 4,
        practiceMinutes: 20,
      ),
      Skill(
        id: _uuid.v4(),
        name: 'Python',
        category: SkillCategory.tech,
        description: '数据分析、爬虫',
        peakProficiency: 80,
        currentProficiency: 72,
        createdAt: now.subtract(const Duration(days: 300)),
        lastPracticeAt: now.subtract(const Duration(days: 5)),
        targetPracticePerWeek: 2,
        practiceMinutes: 60,
      ),
      Skill(
        id: _uuid.v4(),
        name: '素描',
        category: SkillCategory.art,
        description: '铅笔素描',
        peakProficiency: 55,
        currentProficiency: 42,
        createdAt: now.subtract(const Duration(days: 200)),
        lastPracticeAt: now.subtract(const Duration(days: 45)),
        targetPracticePerWeek: 2,
        practiceMinutes: 45,
      ),
    ];
  }
}
