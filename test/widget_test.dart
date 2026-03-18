import 'package:flutter_test/flutter_test.dart';

import 'package:ciq_planner/app.dart';

void main() {
  testWidgets('home page shows the main entry points', (tester) async {
    await tester.pumpWidget(const PlanBookApp());

    expect(find.text('CIQ NoteBook'), findsOneWidget);
    expect(find.text('今日任务'), findsOneWidget);
    expect(find.text('长期计划'), findsOneWidget);
  });
}
