import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/report_model.dart';
import '../widgets/report_details_dialog.dart';
import 'app_navigation_service.dart';

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
    FirebaseMessaging.onMessageOpenedApp.listen(_openReportFromMessage);

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

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      unawaited(_openReportFromMessage(initialMessage));
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

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        unawaited(_openReportById(response.payload));
      },
    );
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

  static Future<void> _openReportFromMessage(RemoteMessage message) {
    return _openReportById(message.data['report_id']);
  }

  static Future<void> _openReportById(String? reportId) async {
    if (reportId == null || reportId.isEmpty) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .get();
      if (!snapshot.exists || snapshot.data() == null) return;

      final report = Report.fromFirestore(snapshot.data()!, snapshot.id);
      final canOpenReport = await _waitForReportNavigation();
      if (!canOpenReport) return;

      _showReportDetails(report);
    } catch (error) {
      debugPrint('Unable to open report notification: $error');
    }
  }

  static void _showReportDetails(Report report) {
    final context = AppNavigationService.context;
    if (context == null) return;

    ReportDetailsDialog.show(context, report);
  }

  static Future<bool> _waitForReportNavigation() async {
    for (var attempt = 0; attempt < 12; attempt += 1) {
      if (AppNavigationService.context != null) break;
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }

    if (AppNavigationService.context == null) return false;
    return AppNavigationService.waitForMainWrapper();
  }

  static Future<void> _saveToken(String token) async {
    final user = _auth.currentUser;
    if (user == null || token.isEmpty) return;

    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final tokenRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('fcm_tokens')
        .doc(_tokenDocumentId(token));
    final snapshot = await tokenRef.get();

    await tokenRef.set({
      'token': token,
      'platform': defaultTargetPlatform.name,
      ..._notificationPreferenceFields(userSnapshot.data()),
      if (!snapshot.exists) 'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Map<String, Object?> _notificationPreferenceFields(
    Map<String, dynamic>? userData,
  ) {
    final preference =
        userData?['notification_preference'] as String? ?? 'all_reports';

    if (preference == 'nearby_only') {
      final latitude = userData?['notification_latitude'];
      final longitude = userData?['notification_longitude'];
      final radiusKm = userData?['notification_radius_km'];

      return {
        'notification_preference': preference,
        if (latitude is num) 'notification_latitude': latitude,
        if (longitude is num) 'notification_longitude': longitude,
        if (radiusKm is num) 'notification_radius_km': radiusKm,
        if (latitude is! num) 'notification_latitude': FieldValue.delete(),
        if (longitude is! num) 'notification_longitude': FieldValue.delete(),
        if (radiusKm is! num) 'notification_radius_km': FieldValue.delete(),
      };
    }

    return {
      'notification_preference': preference,
      'notification_latitude': FieldValue.delete(),
      'notification_longitude': FieldValue.delete(),
      'notification_radius_km': FieldValue.delete(),
    };
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
