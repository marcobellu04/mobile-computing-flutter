class Message {
  final String senderEmail;
  final String receiverEmail;
  final String text;
  final DateTime timestamp;

  Message({
    required this.senderEmail,
    required this.receiverEmail,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'senderEmail': senderEmail,
    'receiverEmail': receiverEmail,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
  };

  factory Message.fromMap(Map<String, dynamic> map) => Message(
    senderEmail: map['senderEmail'],
    receiverEmail: map['receiverEmail'],
    text: map['text'],
    timestamp: DateTime.parse(map['timestamp']),
  );
}
