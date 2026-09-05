import argparse
import socket
import time


DEFAULT_MESSAGES = [
    "Hello UDP Log Viewer!",
    "테스트 메시지 1",
    "UDP 서버가 정상 작동합니다",
    "로그 뷰어 테스트 중...",
    "안녕하세요! 이것은 테스트 메시지입니다.",
    "한글 테스트: 안녕하세요 반갑습니다",
    "특수문자 테스트: !@#$%^&*()",
    f"현재 시간: {time.strftime('%Y-%m-%d %H:%M:%S')}",
    "Flutter UDP 서버 테스트 완료!",
    "한글 인코딩 테스트: 가나다라마바사",
    "한글 문장 테스트: 오늘 날씨가 좋네요",
]


def _candidate_hosts():
    candidates = []
    seen = set()

    def add(ip, source):
        if not ip or ip in seen:
            return
        seen.add(ip)
        candidates.append((ip, source))

    add("127.0.0.1", "루프백")

    try:
        for host_ip in socket.gethostbyname_ex(socket.gethostname())[2]:
            add(host_ip, "호스트명")
    except Exception:
        pass

    try:
        temp = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        temp.connect(("8.8.8.8", 80))
        add(temp.getsockname()[0], "기본 경로")
        temp.close()
    except Exception:
        pass

    return candidates


def _pick_default_host(candidates):
    for ip, source in candidates:
        if source == "기본 경로" and (
            ip.startswith("172.") or ip.startswith("192.168.") or ip.startswith("10.")
        ):
            return ip

    private = [
        ip for ip, _ in candidates if
        (ip.startswith("172.") or ip.startswith("192.168.") or ip.startswith("10."))
    ]
    if private:
        return private[0]
    if candidates:
        return candidates[0][0]
    return "127.0.0.1"


def send_udp_message(message, host, port):
    """UDP 메시지를 전송한다."""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        payload = message.encode("utf-8")
        sock.sendto(payload, (host, port))
        sock.close()
        return True
    except Exception as e:
        print(f"오류 발생: {e}")
        return False


def main():
    candidates = _candidate_hosts()

    parser = argparse.ArgumentParser(description="UDP Log Viewer 테스트 스크립트")
    parser.add_argument(
        "--host",
        default="auto",
        help="수신 대상 IP (기본: auto -> 이 머신 후보 IP 중 우선 순위 선택)",
    )
    parser.add_argument("--port", type=int, default=9000, help="UDP 포트 (기본: 9000)")
    parser.add_argument(
        "--count",
        type=int,
        default=len(DEFAULT_MESSAGES),
        help="전송할 메시지 개수(기본: 샘플 메시지 개수)",
    )
    parser.add_argument(
        "--interval",
        type=float,
        default=1.0,
        help="메시지 간격(초, 기본 1.0)",
    )
    parser.add_argument(
        "--message",
        action="append",
        help="전송할 메시지 (옵션, 여러 번 전달 가능)",
    )
    args = parser.parse_args()

    if args.host == "auto":
        host = _pick_default_host(candidates)
    else:
        host = args.host

    print("=== UDP Log Viewer 테스트 ===")
    print("수신 IP 후보(이 머신 기준):")
    for index, (ip, source) in enumerate(candidates, 1):
        print(f"  {index}. {ip} ({source})")
    print(f"선택된 대상: {host}")
    print(f"포트: {args.port}")
    print("Flutter 앱에서 서버를 시작한 뒤 Enter 키를 누르세요.")
    input()

    messages = args.message if args.message else DEFAULT_MESSAGES
    count = max(1, min(args.count, len(messages)))

    print("\n메시지를 전송합니다...")
    for i in range(count):
        message = messages[i]
        ok = send_udp_message(message, host, args.port)
        if ok:
            print(f"[{i + 1}/{count}] 전송 완료: {message}")
        else:
            print(f"[{i + 1}/{count}] 전송 실패: {message}")
        time.sleep(args.interval)

    print("\n=== 테스트 완료 ===")
    print("Flutter 앱 로그 목록에서 메시지를 확인해 주세요.")


if __name__ == "__main__":
    main()
