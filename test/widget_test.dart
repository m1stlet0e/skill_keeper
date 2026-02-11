import 'package:flutter_test/flutter_test.dart';
import 'package:skill_keeper/main.dart';

void main() {
  testWidgets('App should render without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const SkillKeeperApp());
    
    // 验证首页标题显示
    expect(find.text('技能库'), findsOneWidget);
  });
}
