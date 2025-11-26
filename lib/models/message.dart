class Message {
  final String senderEmail;
  final String receiverEmail;
  final String text;
  final DateTime timestamp;
  final String? senderName;
  final String? receiverName;

  Message({
    required this.senderEmail,
    required this.receiverEmail,
    required this.text,
    required this.timestamp,
    this.senderName,
    this.receiverName,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      senderEmail: map['senderEmail'] as String,
      receiverEmail: map['receiverEmail'] as String,
      text: map['text'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      senderName: map['senderName'] as String?,       // nuovo campo opzionale
      receiverName: map['receiverName'] as String?,   // nuovo campo opzionale
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderEmail': senderEmail,
      'receiverEmail': receiverEmail,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'senderName': senderName,
      'receiverName': receiverName,
    };
  }
}
