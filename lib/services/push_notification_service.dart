import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class PushNotificationService {
  PushNotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _providedMessaging = messaging,
       _providedFirestore = firestore,
       _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging? _providedMessaging;
  final FirebaseFirestore? _providedFirestore;
  final FlutterLocalNotificationsPlugin _localNotifications;
  FirebaseMessaging get _messaging =>
      _providedMessaging ?? FirebaseMessaging.instance;
  FirebaseFirestore get _firestore =>
      _providedFirestore ?? FirebaseFirestore.instance;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<String>? _tokenSubscription;
  String? _uid;
  String? _token;
  bool _initialized = false;

  static bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<void> registerBackgroundHandler() async {
    if (_isSupportedPlatform) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }
  }

  Future<void> initialize(String uid) async {
    if (!_isSupportedPlatform || uid.isEmpty) return;
    if (_uid == uid && _initialized) return;
    if (Firebase.apps.isEmpty) {
      debugPrint('FCM no se inicializa porque Firebase aún no está listo.');
      return;
    }

    await _cancelSubscriptions();
    if (_uid != null && _uid != uid) await _deleteToken();
    _uid = uid;
    _token = null;
    _initialized = false;

    try {
      final permission = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (permission.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('FCM: el usuario denegó los permisos de notificación.');
        return;
      }

      await _localNotifications.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidNotifications = _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        await androidNotifications?.createNotificationChannel(
          const AndroidNotificationChannel(
            'queue_alerts',
            'Alertas de turnos',
            description: 'Avisos sobre el avance de tu turno',
            importance: Importance.max,
          ),
        );
        await androidNotifications?.requestNotificationsPermission();
      } else {
        String? apnsToken;
        for (var attempt = 0; attempt < 5 && apnsToken == null; attempt++) {
          apnsToken = await _messaging.getAPNSToken();
          if (apnsToken == null) {
            await Future<void>.delayed(const Duration(seconds: 1));
          }
        }
        if (apnsToken == null) {
          debugPrint('FCM no obtuvo un token APNs para este dispositivo.');
          return;
        }
      }

      _foregroundSubscription = FirebaseMessaging.onMessage.listen(
        _showForegroundNotification,
        onError: (Object error) => debugPrint('FCM (primer plano): $error'),
      );
      _tokenSubscription = _messaging.onTokenRefresh.listen(
        (token) => unawaited(
          _saveToken(token).catchError((Object error, StackTrace stackTrace) {
            debugPrint('No se pudo guardar el token FCM: $error\n$stackTrace');
          }),
        ),
        onError: (Object error) =>
            debugPrint('FCM (actualización del token): $error'),
      );
      final token = await _messaging.getToken();
      if (token == null) {
        debugPrint('FCM no proporcionó un token para este dispositivo.');
      } else {
        await _saveToken(token);
      }
      _initialized = true;
    } catch (error, stackTrace) {
      debugPrint('No se pudo inicializar FCM: $error\n$stackTrace');
    }
  }

  Future<void> _saveToken(String token) async {
    final uid = _uid;
    if (uid == null) return;
    final oldToken = _token;
    final tokenRef = _tokenDocument(uid, token);
    await tokenRef.set({
      'token': token,
      'platform': defaultTargetPlatform.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (oldToken != null && oldToken != token) {
      await _tokenDocument(uid, oldToken).delete();
    }
    _token = token;
  }

  DocumentReference<Map<String, dynamic>> _tokenDocument(
    String uid,
    String token,
  ) {
    final tokenId = sha256.convert(utf8.encode(token)).toString();
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('pushTokens')
        .doc(tokenId);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _localNotifications.show(
      id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title: notification.title ?? 'Clínica Dental',
      body: notification.body ?? '',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'queue_alerts',
          'Alertas de turnos',
          channelDescription: 'Avisos sobre el avance de tu turno',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> _cancelSubscriptions() async {
    await _foregroundSubscription?.cancel();
    await _tokenSubscription?.cancel();
    _foregroundSubscription = null;
    _tokenSubscription = null;
  }

  Future<void> _deleteToken() async {
    final uid = _uid;
    final token = _token;
    if (uid != null && token != null) {
      await _tokenDocument(uid, token).delete();
    }
  }

  Future<void> dispose() async {
    await _cancelSubscriptions();
    await _deleteToken();
    _uid = null;
    _token = null;
    _initialized = false;
  }
}
