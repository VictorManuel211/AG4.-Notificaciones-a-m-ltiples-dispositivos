import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("Inicio de sesión cancelado.");
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        print("Usuario autenticado: ${user.displayName}");

        // Obtener el token FCM para notificaciones
        String? token = await _firebaseMessaging.getToken();
        print("FCM Token: $token");

        // Verificar si el usuario ya existe en Firestore
        final userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          // Si el usuario no existe, guardarlo con todos sus datos
          await _firestore.collection('users').doc(user.uid).set({
            'name': user.displayName ?? "Usuario Desconocido",
            'email': user.email ?? "Sin Email",
            'photoUrl': user.photoURL ?? "",
            'token': token, // Guardar token de notificación
            'uid': user.uid,
          });
        } else {
          // Si el usuario ya existe, solo actualizar el token
          await _firestore.collection('users').doc(user.uid).update({
            'token': token,
          });
        }

        // Navegar a HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        print("Error: usuario no autenticado.");
      }
    } catch (e) {
      print("Error al iniciar sesión con Google: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Iniciar Sesión")),
      body: Center(
        child: ElevatedButton.icon(
          icon: Icon(Icons.login),
          label: Text("Iniciar sesión con Google"),
          onPressed: _signInWithGoogle,
        ),
      ),
    );
  }
}





