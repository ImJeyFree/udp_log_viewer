import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:udp_log_viewer/app.dart';

void main() {
  testWidgets('Log viewer shows initial stopped state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const UdpLogViewerApp());

    expect(find.text('UDP Log Viewer'), findsOneWidget);
    expect(find.text('Server stopped'), findsOneWidget);
    expect(find.text('8888'), findsWidgets);
    expect(find.text('No logs yet'), findsOneWidget);
    expect(find.text('Start server to receive UDP packets.'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.clear_all), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });
}
