import 'package:flutter/material.dart';

import 'pages/udp_log_viewer_page.dart';

class UdpLogViewerApp extends StatelessWidget {
  const UdpLogViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UDP Log Viewer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const UdpLogViewerPage(),
    );
  }
}
