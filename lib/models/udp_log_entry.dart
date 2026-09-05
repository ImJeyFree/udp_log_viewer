class UdpLogEntry {
  final String message;
  final DateTime timestamp;
  final String sender;

  const UdpLogEntry({
    required this.message,
    required this.timestamp,
    required this.sender,
  });
}
