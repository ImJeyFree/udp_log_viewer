// ignore_for_file: file_names, constant_identifier_names, avoid_print, camel_case_types, unused_element, library_private_types_in_public_api, non_constant_identifier_names

import 'package:shared_preferences/shared_preferences.dart';

import 'dart:io';
import 'dart:async';
import 'dart:convert';

/// UDP 로그를 외부 수신기로 전송하기 위한 정적 유틸리티입니다.
///
/// 기본 대상은 로컬 UDP Log Viewer(`127.0.0.1:8888`)이며,
/// 설정값은 shared_preferences에 저장해 다음 실행 때 다시 불러올 수 있습니다.
class UdpLogger {
  /// 저장된 설정이 없을 때 사용할 기본 수신 호스트입니다.
  static const String _defaultHost = '127.0.0.1';

  /// 저장된 설정이 없을 때 사용할 기본 수신 포트입니다.
  static const int _defaultPort = 8888;

  /// 현재 로그를 보낼 대상 호스트입니다.
  static String _host = _defaultHost;

  /// 현재 로그를 보낼 대상 포트입니다.
  static int _port = _defaultPort;

  /// 로그 전송 기능의 활성화 여부입니다.
  static bool _enabled = false;

  /// UDP 전송에 사용하는 로컬 소켓입니다. 전송 전용이라 임의 포트에 바인딩합니다.
  static RawDatagramSocket? _socket;

  /// UDP 로거 활성화/비활성화
  ///
  /// 값을 바꿀 때마다 설정을 저장하고, 활성 상태에 맞춰 소켓을 열거나 닫습니다.
  static bool get enabled => _enabled;
  static set enabled(bool value) {
    _enabled = value;
    saveConfig();
    if (value) {
      _initializeSocket();
    } else {
      _disposeSocket();
    }
  }

  /// 로그를 보낼 대상 호스트 설정
  ///
  /// 활성화된 상태에서 변경하면 기존 소켓을 닫고 다시 초기화합니다.
  static String get host => _host;
  static set host(String value) {
    print('UdpLogger.host: $value');
    _host = value;
    saveConfig();
    if (_enabled) {
      _disposeSocket();
      _initializeSocket();
    }
  }

  /// 로그를 보낼 대상 포트 설정
  ///
  /// 활성화된 상태에서 변경하면 기존 소켓을 닫고 다시 초기화합니다.
  static int get port => _port;
  static set port(int value) {
    print('UdpLogger.port: $value');
    _port = value;
    saveConfig();
    if (_enabled) {
      _disposeSocket();
      _initializeSocket();
    }
  }

  /// 소켓 초기화
  ///
  /// 송신용 소켓이므로 특정 수신 포트가 아닌 임의의 로컬 포트(`0`)에 바인딩합니다.
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
  ///
  /// 비활성화하거나 대상 설정을 바꿀 때 호출합니다.
  static void _disposeSocket() {
    _socket?.close();
    _socket = null;
  }

  /// 로그 전송
  ///
  /// 로거가 비활성화되어 있거나 소켓 초기화가 실패한 경우 조용히 반환합니다.
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
  ///
  /// 메시지 앞에 현재 시각의 `HH:mm:ss` 값을 붙여 전송합니다.
  static void sendLogWithTimestamp(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final logMessage = '[$timestamp] $message';
    sendLog(logMessage);
  }

  /// 현재 호스트, 포트, 활성화 상태를 로컬 저장소에 저장합니다.
  static Future<void> saveConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('udp_logger_host', _host);
      await prefs.setInt('udp_logger_port', _port);
      await prefs.setBool('udp_logger_enabled', _enabled);
    } catch (e) {
      print('UDP Logger 설정 저장 실패: $e');
    }
  }

  /// 저장된 UDP 로거 설정을 읽고, 활성화 상태라면 소켓도 함께 준비합니다.
  static Future<void> readConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _host = prefs.getString('udp_logger_host') ?? _defaultHost;
      _port = prefs.getInt('udp_logger_port') ?? _defaultPort;
      _enabled = prefs.getBool('udp_logger_enabled') ?? false;

      if (_enabled) {
        _initializeSocket();
      }

      print('UDP Logger 설정 읽기 완료');
      print('  호스트: $_host ($_defaultHost)');
      print('  포트: $_port ($_defaultPort)');
      print('  활성화: $_enabled');
    } catch (e) {
      print('UDP Logger 설정 읽기 실패: $e');
      // 기본값 사용
      _host = _defaultHost;
      _port = _defaultPort;
      _enabled = false;
    }
  }

  /// 설정 정보 출력
  static void printStatus() {
    print('UDP Logger 상태:');
    print('  활성화: $_enabled');
    print('  호스트: $_host ($_defaultHost)');
    print('  포트: $_port ($_defaultPort)');
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
