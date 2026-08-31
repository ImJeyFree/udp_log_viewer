# UDP Log Viewer

Flutter로 만든 간단한 UDP 로그 수신 뷰어입니다. 지정한 포트에서 UDP 메시지를 받아 검은 콘솔 형태의 화면에 실시간으로 표시합니다.

## 주요 기능

- UDP 서버 시작/중지
- 기본 포트 `8888` 사용
- 실행 중 포트 변경
- UTF-8 메시지 수신 및 한글 표시
- 송신자 IP/포트 표시
- 최근 로그 최대 1000개 유지
- 로그 목록 자동 스크롤
- 로그 전체 삭제
- D2Coding 폰트를 사용한 콘솔형 로그 화면

## 프로젝트 구조

```text
lib/
  main.dart              # UDP 수신 뷰어 UI와 서버 실행 로직
  utils/
    udp_logger.dart      # 다른 Flutter 코드에서 UDP 로그를 전송할 때 사용할 수 있는 유틸

test_udp.py              # 수동 UDP 메시지 전송 테스트 스크립트
fonts/                   # D2Coding 폰트
bundle/                  # Windows 빌드 산출물
```

## 실행 방법

Flutter 의존성을 설치합니다.

```bash
flutter pub get
```

앱을 실행합니다.

```bash
flutter run
```

Windows 데스크톱으로 실행하려면 다음처럼 실행할 수 있습니다.

```bash
flutter run -d windows
```

앱이 실행되면 오른쪽 아래의 재생 버튼을 눌러 UDP 서버를 시작합니다.

## UDP 메시지 테스트

앱에서 서버를 시작한 뒤, 별도 터미널에서 테스트 스크립트를 실행합니다.

```bash
python test_udp.py
```

기본 전송 대상은 `localhost:8888`입니다. 스크립트는 영어, 한글, 특수문자가 포함된 메시지를 1초 간격으로 전송합니다.

간단히 직접 전송하려면 Python에서 아래처럼 보낼 수 있습니다.

```python
import socket

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.sendto("테스트 로그".encode("utf-8"), ("127.0.0.1", 8888))
sock.close()
```

## UDP Logger 유틸

`lib/utils/udp_logger.dart`의 `UdpLogger`는 앱 내부 또는 다른 Flutter 코드에서 UDP 로그를 송신할 때 사용할 수 있는 정적 유틸입니다.

```dart
await UdpLogger.readConfig();
UdpLogger.enabled = true;
UdpLogger.host = '127.0.0.1';
UdpLogger.port = 8888;
UdpLogger.sendLogWithTimestamp('hello from app');
```

설정값은 `shared_preferences`에 저장됩니다.

## 현재 구현 메모

- 메인 앱은 UDP 수신 기능만 사용하며, `UdpLogger` 유틸은 현재 `main.dart`에서 직접 연결되어 있지 않습니다.
- 수신한 로그에는 `timestamp`가 저장되지만 화면에는 아직 표시하지 않습니다.
- 로그가 1000개를 넘으면 오래된 로그부터 삭제합니다.
- 자동 스크롤은 1초마다 하단으로 이동합니다.
- Android 릴리스 빌드에서 UDP 통신을 사용하려면 `android/app/src/main/AndroidManifest.xml`에 `INTERNET` 권한을 추가하는 것이 좋습니다.
- macOS 릴리스 빌드에서 UDP 서버 기능을 사용하려면 `macos/Runner/Release.entitlements`에 네트워크 서버 권한을 추가하는 것이 좋습니다.

## 검증

앱 코드만 정적 분석하려면 다음 명령을 사용합니다.

```bash
flutter analyze lib
```

현재 기본 widget test는 Flutter 템플릿의 counter 테스트가 남아 있어 실제 앱 구조와 맞지 않습니다. 전체 테스트를 사용하려면 `test/widget_test.dart`를 `LogViewerApp` 기준으로 갱신해야 합니다.
