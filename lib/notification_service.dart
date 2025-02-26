import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

class NotificationService {
  static const String projectId = "almacenamiento-dca5b"; // 🔥 Reemplaza con tu ID de Firebase

  static Future<void> sendPushNotification(String token, String message) async {
    try {
      // 🔹 Cargar credenciales del archivo JSON
      final serviceAccount = await rootBundle.loadString('assets/almacenamiento-dca5b-firebase-adminsdk-fbsvc-882c13fe97.json');
      final credentials = ServiceAccountCredentials.fromJson(serviceAccount);

      // 🔹 Obtener cliente autenticado
      final client = await clientViaServiceAccount(
        credentials,
        ['https://www.googleapis.com/auth/firebase.messaging'],
      );

      // 🔹 URL de la API FCM v1
      final String url = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      // 🔹 Construir la notificación con datos adicionales
      final Map<String, dynamic> notification = {
        'message': {
          'token': token,
          'notification': {
            'title': 'Nuevo mensaje 📩',
            'body': message,
          },
          'data': {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK', // 🔥 Permite manejar notificaciones en foreground
            'type': 'chat',
          },
          'android': {
            'priority': 'high',
            'notification': {
              'sound': 'default',
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            }
          },
          'apns': {
            'headers': {
              'apns-priority': '10', // 🔥 Prioridad para iOS
            },
            'payload': {
              'aps': {
                'sound': 'default',
              },
            },
          },
        },
      };

      // 🔹 Enviar la solicitud a Firebase
      final response = await client.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(notification),
      );

      if (response.statusCode == 200) {
        print("✅ Notificación enviada con éxito.");
      } else {
        print("❌ Error en FCM: ${response.statusCode} - ${response.body}");
      }

      client.close(); // 🔥 Cierra el cliente después de usarlo
    } catch (e) {
      print("❌ Error enviando notificación: $e");
    }
  }
}

