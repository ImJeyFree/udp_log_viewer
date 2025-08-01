// ignore_for_file: file_names, constant_identifier_names, avoid_print, camel_case_types, unused_element, library_private_types_in_public_api, non_constant_identifier_names

import 'package:flutter/material.dart';

import 'dart:io';
import 'dart:async';
import 'dart:convert';

void main() {
  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const LogViewerApp());
}

class LogViewerApp extends StatelessWidget {
  const LogViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UDP Log Viewer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LogViewerHomePage(),
    );
  }
}

class LogViewerHomePage extends StatefulWidget {
  const LogViewerHomePage({super.key});

  @override
  State<LogViewerHomePage> createState() => _LogViewerHomePageState();
}

class _LogViewerHomePageState extends State<LogViewerHomePage> {
  final List<LogEntry> _logs = [];
  final ScrollController _scrollController = ScrollController();
  RawDatagramSocket? _socket;
  bool _isServerRunning = false;
  int _port = 8888;
  String _status = '서버가 중지되었습니다';
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _stopServer();
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    // 암호화 키 생성

    _autoScrollTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_scrollController.hasClients && _logs.isNotEmpty) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startServer() async {
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _port);
      setState(() {
        _isServerRunning = true;
        _status = '서버가 포트 $_port에서 실행 중입니다';
      });

      _socket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
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

  void _stopServer() {
    _socket?.close();
    _socket = null;
    setState(() {
      _isServerRunning = false;
      _status = '서버가 중지되었습니다';
    });
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

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
        title: const Text('UDP Log Viewer'),
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
          // 상태 표시줄
          Container(
            padding: const EdgeInsets.all(14),
            color: _isServerRunning
                ? Colors.green.shade100
                : Colors.red.shade100,
            child: Row(
              children: [
                Icon(
                  _isServerRunning ? Icons.circle : Icons.circle_outlined,
                  color: _isServerRunning ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _status,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text('포트: $_port'),
              ],
            ),
          ),

          // 로그 목록
          Expanded(
            child: _logs.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, size: 64, color: Colors.grey),
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
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        child: ListTile(
                          title: Text(
                            log.message,
                            style: const TextStyle(fontFamily: 'D2Coding'),
                          ),
                          subtitle: Text(
                            '${log.timestamp.toString().substring(11, 19)} | ${log.sender}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          leading: const Icon(Icons.message),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _clearLogs,
            tooltip: '로그 지우기',
            heroTag: 'clear',
            child: const Icon(Icons.clear_all),
          ),
          const SizedBox(width: 16),
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

class LogEntry {
  final String message;
  final DateTime timestamp;
  final String sender;

  LogEntry({
    required this.message,
    required this.timestamp,
    required this.sender,
  });
}
