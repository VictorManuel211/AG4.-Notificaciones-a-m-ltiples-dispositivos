import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'login_screen.dart';
import 'message_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    requestNotificationPermissions();
    updateUserToken();
    handleForegroundNotifications();
  }

  /// 📌 Pide permisos para recibir notificaciones en iOS
  Future<void> requestNotificationPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print("❌ Permiso de notificación denegado");
    }
  }

  /// 📌 Actualiza el token del usuario en Firestore
  Future<void> updateUserToken() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'token': token,
        });
        print("✅ Token actualizado: $token");
      }
    }
  }

  /// 📌 Maneja notificaciones recibidas cuando la app está en foreground
  void handleForegroundNotifications() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 Notificación recibida en foreground: ${message.notification?.title}");

      if (message.notification != null) {
        // Muestra un diálogo con la notificación
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(message.notification!.title ?? "Notificación"),
            content: Text(message.notification!.body ?? "Tienes un nuevo mensaje"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;
    if (user == null) {
      return LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Usuarios"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final users = snapshot.data!.docs.where((doc) => doc.id != user.uid).toList();

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var userDoc = users[index];
              var userData = userDoc.data() as Map<String, dynamic>;

              String name = userData.containsKey('name') ? userData['name'] : "Usuario Desconocido";
              String email = userData.containsKey('email') ? userData['email'] : "Sin Email";
              String photoUrl = userData.containsKey('photoUrl') ? userData['photoUrl'] : "";

              return ListTile(
                title: Text(name),
                subtitle: Text(email),
                leading: photoUrl.isNotEmpty
                    ? CircleAvatar(backgroundImage: NetworkImage(photoUrl))
                    : CircleAvatar(child: Icon(Icons.person)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MessageScreen(
                        receiverId: userDoc.id,
                        receiverName: name,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}








