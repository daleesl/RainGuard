import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

enum NotificationTokenResult {
  enabled,
  denied,
  notSignedIn,
  tokenUnavailable,
  failed,
}

class NotificationTokenService {
  NotificationTokenService._();

  static final _messaging = FirebaseMessaging.instance;
  static final _auth = FirebaseAuth.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static const _communityReportChannel = AndroidNotificationChannel(
    'community_reports',
    'RainGuard alerts',
    description: 'Community rain and flood safety alerts',
    importance: Importance.high,
  );
  static StreamSubscription<User?>? _authSubscription;
  static StreamSubscription<String>? _tokenRefreshSubscription;
  static StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _messaging.setAutoInitEnabled(true);
    await _initializeLocalNotifications();

    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen(
      _showForegroundNotification,
    );

    _authSubscription = _auth.authStateChanges().listen((user) {
      if (user != null) {
        unawaited(registerCurrentDevice());
      }
    });

    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) {
      unawaited(_saveToken(token));
    });

    if (_auth.currentUser != null) {
      await registerCurrentDevice();
    }
  }

  static Future<NotificationTokenResult> registerCurrentDevice() async {
    final user = _auth.currentUser;
    if (user == null) return NotificationTokenResult.notSignedIn;

    final settings = await _requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return NotificationTokenResult.denied;
    }

    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        return NotificationTokenResult.tokenUnavailable;
      }
      await _saveToken(token);
      return NotificationTokenResult.enabled;
    } catch (error) {
      debugPrint('Unable to register notification token: $error');
      return NotificationTokenResult.failed;
    }
  }

  static Future<bool> hasNotificationPermission() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  static Future<bool> isCurrentDeviceRegistered() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return false;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('fcm_tokens')
          .doc(_tokenDocumentId(token))
          .get();
      return snapshot.exists;
    } catch (error) {
      debugPrint('Unable to check notification token: $error');
      return false;
    }
  }

  static Future<void> deleteCurrentToken() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('fcm_tokens')
          .doc(_tokenDocumentId(token))
          .delete();
    } catch (error) {
      debugPrint('Unable to delete notification token: $error');
    }
  }

  static Future<NotificationSettings> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    return settings;
  }

  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      'ic_stat_rainguard',
    );
    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(settings: initializationSettings);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_communityReportChannel);
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final title =
        message.notification?.title ??
        message.data['title'] ??
        'RainGuard alert';
    final body =
        message.notification?.body ??
        message.data['body'] ??
        'New community report posted.';

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _communityReportChannel.id,
          _communityReportChannel.name,
          channelDescription: _communityReportChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF0B6BD3),
          icon: 'ic_stat_rainguard',
          groupKey: 'rainguard_community_reports',
          ticker: 'RainGuard community report',
          visibility: NotificationVisibility.public,
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: title,
            summaryText: 'RainGuard community alert',
          ),
        ),
      ),
      payload: message.data['report_id'],
    );
  }

  static Future<void> _saveToken(String token) async {
    final user = _auth.currentUser;
    if (user == null || token.isEmpty) return;

    final tokenRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('fcm_tokens')
        .doc(_tokenDocumentId(token));
    final snapshot = await tokenRef.get();

    await tokenRef.set({
      'token': token,
      'platform': defaultTargetPlatform.name,
      if (!snapshot.exists) 'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static String _tokenDocumentId(String token) {
    return base64Url.encode(utf8.encode(token)).replaceAll('=', '');
  }

  static Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _tokenRefreshSubscription?.cancel();
    await _foregroundMessageSubscription?.cancel();
    _authSubscription = null;
    _tokenRefreshSubscription = null;
    _foregroundMessageSubscription = null;
    _initialized = false;
  }
}
