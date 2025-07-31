import socket
import time
import sys

def send_udp_message(message, host='localhost', port=8888):
    """UDP 메시지를 전송하는 함수"""
    try:
        # UDP 소켓 생성
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        
        # 메시지 전송 (UTF-8 인코딩 명시)
        sock.sendto(message.encode('utf-8'), (host, port))
        print(f"메시지 전송 완료: {message}")
        
        # 소켓 닫기
        sock.close()
        return True
        
    except Exception as e:
        print(f"오류 발생: {e}")
        return False

def main():
    print("=== UDP Log Viewer 테스트 (Host: 127.0.0.1) ===")
    print("Flutter 앱에서 서버를 시작한 후 Enter를 눌러주세요...")
    input()
    
    # 테스트 메시지들
    test_messages = [
        "Hello UDP Log Viewer!",
        "테스트 메시지 1",
        "UDP 서버가 정상 작동합니다",
        "로그 뷰어 테스트 중...",
        "안녕하세요! 이것은 테스트 메시지입니다.",
        "한글 테스트: 안녕하세요 반갑습니다",
        "특수문자 테스트: !@#$%^&*()",
        "현재 시간: " + time.strftime("%Y-%m-%d %H:%M:%S"),
        "Flutter UDP 서버 테스트 완료!",
        "한글 인코딩 테스트: 가나다라마바사",
        "한글 문장 테스트: 오늘 날씨가 좋네요",
    ]
    
    print("\n메시지를 전송합니다...")
    
    for i, message in enumerate(test_messages, 1):
        print(f"\n[{i}/{len(test_messages)}] 전송 중...")
        send_udp_message(message)
        time.sleep(1)  # 1초 대기
    
    print("\n=== 테스트 완료 ===")
    print("Flutter 앱에서 로그가 표시되는지 확인해주세요!")

if __name__ == "__main__":
    main() 
