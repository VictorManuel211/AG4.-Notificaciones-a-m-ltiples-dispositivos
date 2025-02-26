import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'message_screen.dart';

// 🔹 Manejo de notificaciones cuando la app está en segundo plano o cerrada
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📩 Notificación recibida en segundo plano: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Registrar el handler de notificaciones en segundo plano
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _setupFirebaseMessaging();
  }

  /// 🔹 Configura Firebase Messaging y guarda el token
  void _setupFirebaseMessaging() async {
    try {
      // 🔹 Solicitar permisos en iOS
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print("✅ Permiso de notificación concedido");
      } else {
        print("❌ Permiso de notificación denegado");
      }

      // 🔹 Obtener y guardar el token FCM
      String? token = await _firebaseMessaging.getToken();
      print("📲 Token de notificación: $token");
      await _saveTokenToDatabase(token);

      // 🔹 Manejo de notificaciones en primer plano
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("📥 Notificación recibida en primer plano: ${message.notification?.title}");
        _showNotificationDialog(message);
      });

      // 🔹 Manejo de notificaciones cuando se toca la notificación
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print("🔔 Notificación tocada: ${message.notification?.title}");
        _handleMessageTap(message);
      });
    } catch (e) {
      print("⚠️ Error en configuración de notificaciones: $e");
    }
  }

  /// 🔹 Guarda el token en Firestore si el usuario está autenticado
  Future<void> _saveTokenToDatabase(String? token) async {
    final User? user = _auth.currentUser;
    if (user != null && token != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'token': token,
      });
      print("✅ Token guardado en Firestore");
    }
  }

  /// 🔹 Muestra un diálogo emergente con la notificación
  void _showNotificationDialog(RemoteMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message.notification?.title ?? "Notificación"),
        content: Text(message.notification?.body ?? "Sin contenido"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  /// 🔹 Maneja la navegación cuando el usuario toca una notificación
  void _handleMessageTap(RemoteMessage message) {
    final String? senderId = message.data['senderId']; // Debes enviar `senderId` en la notificación

    if (senderId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessageScreen(
            receiverId: senderId,
            receiverName: "Usuario", // Puedes obtener el nombre de Firestore si lo deseas
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Notificaciones Push',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginScreen(),
    );
  }
}







