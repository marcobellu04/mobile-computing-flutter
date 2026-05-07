class Message {
  final String senderEmail;
  final String receiverEmail;
  final String text;
  final DateTime timestamp;
  final String? senderName;
  final String? receiverName;
  bool isRead; // 1. Aggiunto campo per lo stato di lettura

  Message({
    required this.senderEmail,
    required this.receiverEmail,
    required this.text,
    required this.timestamp,
    this.senderName,
    this.receiverName,
    this.isRead = false, // 2. Default a false (nuovo messaggio = non letto)
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      senderEmail: map['senderEmail'] as String,
      receiverEmail: map['receiverEmail'] as String,
      text: map['text'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      senderName: map['senderName'] as String?,
      receiverName: map['receiverName'] as String?,
      // 3. Recupero lo stato dal database/pref, se nullo metto false
      isRead: map['isRead'] as bool? ?? false, 
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
      'isRead': isRead, // 4. Salvo lo stato nel JSON
    };
  }
}