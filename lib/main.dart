// ignore_for_file: file_names, constant_identifier_names, avoid_print, camel_case_types, unused_element, library_private_types_in_public_api, non_constant_identifier_names

import 'package:flutter/material.dart';

import 'dart:io';
import 'dart:async';
import 'dart:convert';

void main() {
  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MaterialApp(
      title: 'UDP Log Viewer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LogViewerApp(),
    ),
  );
}

/// UDP 메시지를 수신해서 콘솔 스타일의 화면에 보여주는 메인 화면입니다.
class LogViewerApp extends StatefulWidget {
  const LogViewerApp({super.key});

  @override
  State<LogViewerApp> createState() => _LogViewerAppState();
}

class _LogViewerAppState extends State<LogViewerApp> {
  /// 화면에 표시할 수신 로그 목록입니다. 오래된 로그는 1000개 제한에 맞춰 제거합니다.
  final List<LogEntry> _logs = [];

  /// 새 로그가 들어왔을 때 로그 목록을 아래로 이동시키기 위한 컨트롤러입니다.
  final ScrollController _scrollController = ScrollController();

  /// 현재 열려 있는 UDP 수신 소켓입니다. 서버가 중지되면 null로 되돌립니다.
  RawDatagramSocket? _socket;

  /// 시작/중지 버튼과 상태 배지를 갱신하기 위한 서버 실행 상태입니다.
  bool _isServerRunning = false;

  /// UDP 서버가 바인딩할 포트입니다.
  int _port = 8888;

  /// AppBar에 표시할 서버 상태 메시지입니다.
  String _status = '서버가 중지되었습니다';

  /// 로그가 계속 들어올 때 화면 하단을 유지하기 위한 주기 타이머입니다.
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void dispose() {
    // dispose 중에는 setState를 호출하지 않고 리소스만 정리합니다.
    _socket?.close();
    _socket = null;
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  /// 로그 목록을 1초마다 맨 아래로 이동시켜 최신 로그를 볼 수 있게 합니다.
  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_scrollController.hasClients && _logs.isNotEmpty) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease,
        );
      }
    });
  }

  /// 지정된 포트에서 UDP 서버를 시작하고 들어오는 datagram을 로그로 추가합니다.
  Future<void> _startServer() async {
    try {
      // 모든 IPv4 인터페이스에서 UDP 패킷을 받을 수 있도록 바인딩합니다.
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _port);
      setState(() {
        _isServerRunning = true;
        _status = '서버가 포트 $_port에서 실행 중입니다';
      });

      _socket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          // read 이벤트마다 큐에 쌓인 datagram을 하나씩 꺼냅니다.
          final datagram = _socket!.receive();
          if (datagram != null) {
            // UTF-8 인코딩으로 한글 처리
            String message;
            try {
              message = utf8.decode(datagram.data, allowMalformed: true);
            } catch (e) {
              // UTF-8 디코딩 실패 시 기본 방식 사용
              message = String.fromCharCodes(datagram.data);
            }

            final timestamp = DateTime.now();
            final sender = '${datagram.address.address}:${datagram.port}';

            setState(() {
              // 송신자 주소와 메시지를 함께 보관해 화면 표시와 추후 확장에 사용합니다.
              _logs.add(
                LogEntry(
                  message: message,
                  timestamp: timestamp,
                  sender: sender,
                ),
              );

              // 로그가 너무 많아지면 오래된 것부터 제거
              if (_logs.length > 1000) {
                _logs.removeRange(0, _logs.length - 1000);
              }
            });
          }
        }
      });
    } catch (e) {
      setState(() {
        _status = '서버 시작 실패: $e';
      });
    }
  }

  /// UDP 소켓을 닫고 화면 상태를 중지 상태로 되돌립니다.
  void _stopServer() {
    _socket?.close();
    _socket = null;
    setState(() {
      _isServerRunning = false;
      _status = '서버가 중지되었습니다';
    });
  }

  /// 현재 화면에 쌓인 로그만 삭제합니다. 서버 실행 상태에는 영향을 주지 않습니다.
  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  /// 포트 변경 다이얼로그를 열고, 서버 실행 중이면 새 포트로 재시작합니다.
  void _changePort() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('포트 변경'),
        content: TextField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '포트 번호',
            hintText: '8888',
          ),
          onSubmitted: (value) {
            final newPort = int.tryParse(value);
            // UDP/TCP 포트의 유효 범위는 1부터 65535까지입니다.
            if (newPort != null && newPort > 0 && newPort < 65536) {
              setState(() {
                _port = newPort;
              });
              Navigator.of(context).pop();
              if (_isServerRunning) {
                _stopServer();
                _startServer();
              }
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('UDP Log Viewer'),
            const SizedBox(width: 8),
            // 서버 실행 여부와 상태 메시지를 보여주는 배지입니다.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isServerRunning
                    ? Colors.green.shade100
                    : Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isServerRunning ? Colors.green : Colors.red,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isServerRunning ? Icons.circle : Icons.circle_outlined,
                    size: 10,
                    color: _isServerRunning ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _isServerRunning
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 현재 수신 포트를 작게 표시합니다.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.network_check, size: 10, color: Colors.blue),
                  const SizedBox(width: 2),
                  Text(
                    '$_port',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _changePort,
            tooltip: '포트 설정',
          ),
        ],
      ),
      body: Column(
        children: [
          // 로그 목록
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(0),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _logs.isEmpty
                  // 로그가 없을 때는 사용자가 다음 행동을 알 수 있도록 빈 상태를 표시합니다.
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            '로그가 없습니다',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          Text(
                            '서버를 시작하고 UDP 메시지를 받아보세요',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  // 로그가 있으면 콘솔처럼 한 줄씩 이어 붙여 표시합니다.
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];

                        return Text(
                          '[${log.sender}]-${log.message}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 14,
                            fontFamily: 'D2Coding',
                            height: 1.1,
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 수신된 로그를 모두 지우는 버튼입니다.
          FloatingActionButton(
            onPressed: _clearLogs,
            tooltip: '로그 지우기',
            heroTag: 'clear',
            child: const Icon(Icons.clear_all),
          ),
          const SizedBox(width: 16),
          // UDP 서버의 시작/중지를 토글하는 버튼입니다.
          FloatingActionButton(
            onPressed: _isServerRunning ? _stopServer : _startServer,
            tooltip: _isServerRunning ? '서버 중지' : '서버 시작',
            heroTag: 'server',
            backgroundColor: _isServerRunning ? Colors.red : Colors.green,
            child: Icon(_isServerRunning ? Icons.stop : Icons.play_arrow),
          ),
        ],
      ),
    );
  }
}

/// 수신한 UDP 메시지 한 건을 표현하는 데이터 모델입니다.
class LogEntry {
  /// 수신한 메시지 본문입니다.
  final String message;

  /// 메시지를 앱이 수신한 시각입니다.
  final DateTime timestamp;

  /// 송신자의 IP와 포트를 합친 문자열입니다.
  final String sender;

  LogEntry({
    required this.message,
    required this.timestamp,
    required this.sender,
  });
}
