import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart'; // 📌 Importa el servicio de notificaciones

class MessageScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  MessageScreen({required this.receiverId, required this.receiverName});

  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final String currentUserId = _auth.currentUser?.uid ?? '';
    final String message = _messageController.text.trim();

    // Guardar mensaje en Firestore
    await _firestore.collection('messages').add({
      'senderId': currentUserId,
      'receiverId': widget.receiverId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Obtener el token del receptor
    var receiverDoc = await _firestore.collection('users').doc(widget.receiverId).get();
    String? receiverToken = receiverDoc['token'];

    if (receiverToken != null) {
      print("Enviando notificación a: $receiverToken");
      await NotificationService.sendPushNotification(receiverToken, message);
    }

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = _auth.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: Text("Chat con ${widget.receiverName}")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _firestore
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var messages = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  return (data['senderId'] == currentUserId && data['receiverId'] == widget.receiverId) ||
                      (data['receiverId'] == currentUserId && data['senderId'] == widget.receiverId);
                }).toList();

                if (messages.isEmpty) {
                  return Center(child: Text("No hay mensajes disponibles."));
                }

                return ListView(
                  reverse: true,
                  children: messages.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == currentUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(data['message']),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(hintText: "Escribe un mensaje..."),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}








