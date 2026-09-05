// ignore_for_file: avoid_print, no_leading_underscores_for_local_identifiers

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../models/udp_log_entry.dart';

class UdpLogHomePage extends StatefulWidget {
  const UdpLogHomePage({super.key});

  @override
  State<UdpLogHomePage> createState() => _UdpLogHomePageState();
}

class _UdpLogHomePageState extends State<UdpLogHomePage> {
  final List<UdpLogEntry> _logs = [];
  final ScrollController _scrollController = ScrollController();
  RawDatagramSocket? _socket;
  late final TextEditingController _portController;
  bool _isServerRunning = false;
  int _port = 8888;
  String _server = '0.0.0.0';
  String _status = 'Server stopped';
  Timer? _autoScrollTimer;

  @override
  void initState() {
    _portController = TextEditingController(text: '$_port');
    super.initState();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _portController.dispose();
    _socket?.close();
    _socket = null;
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  int? _parsePort(String value) {
    final parsed = int.tryParse(value);
    if (parsed == null || parsed <= 0 || parsed >= 65536) {
      return null;
    }
    return parsed;
  }

  void _applyPort({required bool restartIfRunning}) {
    final parsed = _parsePort(_portController.text);
    if (parsed == null) {
      _portController.text = '$_port';
      return;
    }

    if (parsed == _port) {
      return;
    }

    setState(() {
      _port = parsed;
      _portController.text = '$_port';
    });

    if (restartIfRunning && _isServerRunning) {
      _stopServer();
      _startServer();
    }
  }

  void _toggleServer() {
    final parsed = _parsePort(_portController.text);
    if (parsed == null) {
      _portController.text = '$_port';
      return;
    }

    if (parsed != _port) {
      setState(() {
        _port = parsed;
        _portController.text = '$_port';
      });
    }

    if (_isServerRunning) {
      _stopServer();
      return;
    }

    _startServer();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_scrollController.hasClients && _logs.isNotEmpty) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease,
        );
      }
    });
  }

  Future<void> _startServer() async {
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _port);
      final serverAddress = await _getActiveServerAddress();
      setState(() {
        _isServerRunning = true;
        _server = serverAddress;
        _status = '$_server : $_port Listening';
      });

      _socket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket!.receive();
          if (datagram != null) {
            String message;
            try {
              message = utf8.decode(datagram.data, allowMalformed: true);
            } catch (e) {
              message = String.fromCharCodes(datagram.data);
            }

            final timestamp = DateTime.now();
            final sender = '${datagram.address.address}:${datagram.port}';

            if (!mounted) {
              return;
            }

            setState(() {
              _logs.add(
                UdpLogEntry(
                  message: message,
                  timestamp: timestamp,
                  sender: sender,
                ),
              );
              if (_logs.length > 1000) {
                _logs.removeRange(0, _logs.length - 1000);
              }
            });
          }
        }
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = 'Failed to start server: $e';
      });
    }
  }

  Future<String> _getActiveServerAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to query server ip: $e');
    }

    return '0.0.0.0';
  }

  void _stopServer() {
    _socket?.close();
    _socket = null;
    if (!mounted) {
      return;
    }
    setState(() {
      _isServerRunning = false;
      _status = 'Server stopped';
    });
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  void _changePort() {
    _applyPort(restartIfRunning: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('UDP Log Viewer'),
              const SizedBox(width: 8),
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
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
                    const Icon(
                      Icons.network_check,
                      size: 10,
                      color: Colors.blue,
                    ),
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
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('UDP 포트', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 6),
                SizedBox(
                  width: 72,
                  child: TextField(
                    controller: _portController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    onSubmitted: (_) =>
                        _applyPort(restartIfRunning: _isServerRunning),
                    decoration: InputDecoration(
                      isDense: true,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  onPressed: _toggleServer,
                  child: Text(_isServerRunning ? '중지' : '시작'),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _changePort,
            tooltip: 'Port settings',
          ),
        ],
      ),
      body: Column(
        children: [
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
                            'No logs yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          Text(
                            'Start server to receive UDP packets.',
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
                        return Text(
                          '[${log.sender}] ${log.message}',
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
          FloatingActionButton(
            onPressed: _clearLogs,
            tooltip: 'Clear logs',
            heroTag: 'clear',
            child: const Icon(Icons.clear_all),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            onPressed: _isServerRunning ? _stopServer : _startServer,
            tooltip: _isServerRunning ? 'Stop server' : 'Start server',
            heroTag: 'server',
            backgroundColor: _isServerRunning ? Colors.red : Colors.green,
            child: Icon(_isServerRunning ? Icons.stop : Icons.play_arrow),
          ),
        ],
      ),
    );
  }
}
