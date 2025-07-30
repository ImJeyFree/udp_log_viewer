// ignore_for_file: file_names, constant_identifier_names, avoid_print, camel_case_types, unused_element, library_private_types_in_public_api, non_constant_identifier_names

import 'dart:io';
import 'dart:async';
import 'dart:convert';

class UdpLogger {
  static const String _defaultHost = '127.0.0.1';
  static const int _defaultPort = 8888;

  static String _host = _defaultHost;
  static int _port = _defaultPort;
  static bool _enabled = false;
  static RawDatagramSocket? _socket;

  /// UDP 로거 활성화/비활성화
  static bool get enabled => _enabled;
  static set enabled(bool value) {
    _enabled = value;
    if (value) {
      _initializeSocket();
    } else {
      _disposeSocket();
    }
  }

  /// 호스트 설정
  static String get host => _host;
  static set host(String value) {
    _host = value;
    if (_enabled) {
      _disposeSocket();
      _initializeSocket();
    }
  }

  /// 포트 설정
  static int get port => _port;
  static set port(int value) {
    _port = value;
    if (_enabled) {
      _disposeSocket();
      _initializeSocket();
    }
  }

  /// 소켓 초기화
  static Future<void> _initializeSocket() async {
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      print('UDP Logger: 소켓 초기화 완료 - $_host:$_port');
    } catch (e) {
      print('UDP Logger: 소켓 초기화 실패 - $e');
      _enabled = false;
    }
  }

  /// 소켓 해제
  static void _disposeSocket() {
    _socket?.close();
    _socket = null;
  }

  /// 로그 전송
  static void sendLog(String message) {
    if (!_enabled || _socket == null) return;

    try {
      final bytes = utf8.encode(message);
      _socket!.send(bytes, InternetAddress(_host), _port);
    } catch (e) {
      print('UDP Logger: 로그 전송 실패 - $e');
    }
  }

  /// 로그 전송 (타임스탬프 포함)
  static void sendLogWithTimestamp(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final logMessage = '[$timestamp] $message';
    sendLog(logMessage);
  }

  /// 설정 정보 출력
  static void printStatus() {
    print('UDP Logger 상태:');
    print('  활성화: $_enabled');
    print('  호스트: $_host');
    print('  포트: $_port');
    print('  소켓: ${_socket != null ? "연결됨" : "연결 안됨"}');
  }

  /// 연결 테스트
  static Future<bool> testConnection() async {
    if (!_enabled) return false;

    try {
      final testMessage = 'UDP Logger 연결 테스트 - ${DateTime.now()}';
      sendLog(testMessage);
      return true;
    } catch (e) {
      print('UDP Logger: 연결 테스트 실패 - $e');
      return false;
    }
  }
}
