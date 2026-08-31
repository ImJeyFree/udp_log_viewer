import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:udp_log_viewer/main.dart';

void main() {
  testWidgets('Log viewer shows initial stopped state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const LogViewerApp(),
      ),
    );

    expect(find.text('UDP Log Viewer'), findsOneWidget);
    expect(find.text('서버가 중지되었습니다'), findsOneWidget);
    expect(find.text('8888'), findsOneWidget);
    expect(find.text('로그가 없습니다'), findsOneWidget);
    expect(find.text('서버를 시작하고 UDP 메시지를 받아보세요'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.clear_all), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
