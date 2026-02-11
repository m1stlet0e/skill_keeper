import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/skill.dart';
import '../../services/skill_service.dart';

class AddSkillScreen extends StatefulWidget {
  const AddSkillScreen({super.key});

  @override
  State<AddSkillScreen> createState() => _AddSkillScreenState();
}

class _AddSkillScreenState extends State<AddSkillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  
  SkillCategory _selectedCategory = SkillCategory.other;
  double _initialProficiency = 50;
  int _targetPracticePerWeek = 2;
  int _practiceMinutes = 30;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradientFor(context),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 顶部导航
              Padding(
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
                      '添加新技能',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),
              
              // 表单内容
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 技能名称
                        _buildSectionTitle('技能名称'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            hintText: '例如: 吉他、日语、Python...',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '请输入技能名称';
                            }
                            return null;
                          },
                        ).animate(delay: 100.ms).fadeIn().slideX(begin: 0.1, end: 0),
                        
                        const SizedBox(height: 24),
                        
                        // 技能分类
                        _buildSectionTitle('技能分类'),
                        const SizedBox(height: 12),
                        _buildCategorySelector().animate(delay: 200.ms).fadeIn(),
                        
                        const SizedBox(height: 24),
                        
                        // 当前熟练度
                        _buildSectionTitle('当前熟练度'),
                        const SizedBox(height: 8),
                        _buildProficiencySlider().animate(delay: 300.ms).fadeIn(),
                        
                        const SizedBox(height: 24),
                        
                        // 练习目标
                        _buildSectionTitle('每周练习目标'),
                        const SizedBox(height: 12),
                        _buildPracticeTargetSelector().animate(delay: 400.ms).fadeIn(),
                        
                        const SizedBox(height: 24),
                        
                        // 每次练习时长
                        _buildSectionTitle('每次练习时长'),
                        const SizedBox(height: 12),
                        _buildDurationSelector().animate(delay: 500.ms).fadeIn(),
                        
                        const SizedBox(height: 24),
                        
                        // 描述（可选）
                        _buildSectionTitle('描述 (可选)'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descController,
                          decoration: const InputDecoration(
                            hintText: '简单描述一下这个技能...',
                          ),
                          maxLines: 3,
                        ).animate(delay: 600.ms).fadeIn(),
                        
                        const SizedBox(height: 40),
                        
                        // 提交按钮
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveSkill,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                '添加技能',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ).animate(delay: 700.ms).fadeIn().slideY(begin: 0.2, end: 0),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: SkillCategory.values.map((category) {
        final isSelected = _selectedCategory == category;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = category),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? category.color 
                  : category.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected 
                    ? category.color 
                    : category.color.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  category.icon,
                  size: 20,
                  color: isSelected ? Colors.white : category.color,
                ),
                const SizedBox(width: 8),
                Text(
                  category.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : category.color,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProficiencySlider() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '完全不会',
                style: TextStyle(fontSize: 12, color: AppTheme.textHint),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedCategory.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_initialProficiency.toInt()}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _selectedCategory.color,
                  ),
                ),
              ),
              Text(
                '非常熟练',
                style: TextStyle(fontSize: 12, color: AppTheme.textHint),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _selectedCategory.color,
              inactiveTrackColor: _selectedCategory.color.withValues(alpha: 0.2),
              thumbColor: _selectedCategory.color,
              overlayColor: _selectedCategory.color.withValues(alpha: 0.2),
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: _initialProficiency,
              min: 10,
              max: 100,
              divisions: 18,
              onChanged: (value) => setState(() => _initialProficiency = value),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getProficiencyDescription(),
            style: TextStyle(
              color: _selectedCategory.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getProficiencyDescription() {
    if (_initialProficiency < 20) return '刚开始学习';
    if (_initialProficiency < 40) return '入门水平';
    if (_initialProficiency < 60) return '有一定基础';
    if (_initialProficiency < 80) return '比较熟练';
    return '非常精通';
  }

  Widget _buildPracticeTargetSelector() {
    final targets = [1, 2, 3, 4, 5, 7];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedBg = isDark ? AppTheme.darkSurfaceColor : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.grey.shade200;

    // 单行横向滚动，紧凑芯片，减少纵向占用
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: targets.map((target) {
          final isSelected = _targetPracticePerWeek == target;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _targetPracticePerWeek = target),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : unselectedBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : borderColor,
                    ),
                  ),
                  child: Text(
                    target == 7 ? '每天' : '$target次/周',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDurationSelector() {
    final durations = [10, 20, 30, 45, 60, 90];
    
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: durations.map((duration) {
        final isSelected = _practiceMinutes == duration;
        return GestureDetector(
          onTap: () => setState(() => _practiceMinutes = duration),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? AppTheme.primaryColor 
                    : Colors.grey.shade200,
              ),
            ),
            child: Text(
              '$duration分钟',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _saveSkill() {
    if (!_formKey.currentState!.validate()) return;

    final skillService = context.read<SkillService>();
    skillService.addSkill(
      name: _nameController.text.trim(),
      category: _selectedCategory,
      description: _descController.text.trim().isEmpty 
          ? null 
          : _descController.text.trim(),
      initialProficiency: _initialProficiency,
      targetPracticePerWeek: _targetPracticePerWeek,
      practiceMinutes: _practiceMinutes,
    );

    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已添加技能: ${_nameController.text}'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
