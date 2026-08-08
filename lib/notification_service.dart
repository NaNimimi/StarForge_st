import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Map<String, dynamic> decodeNotificationPayload(Object? payload) {
  if (payload is Map) return Map<String, dynamic>.from(payload);
  final text = payload?.toString().trim() ?? '';
  if (text.isEmpty) return const {};
  try {
    final decoded = jsonDecode(text);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  } on FormatException {
    // Older senders may provide a route string instead of JSON.
  }
  return {'route': text};
}

/// Native notification bridge used by Firebase foreground and data messages.
class DeviceNotificationService {
  DeviceNotificationService._();

  static final DeviceNotificationService instance =
      DeviceNotificationService._();

  // Must match infrastructure/push/fcm_client.py in the backend.
  static const channelId = 'starforge_messages';
  static const _channelName = 'StarForge family';
  static const _channelDescription =
      'Messages, attendance, assignments, payments and school alerts';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final StreamController<Map<String, dynamic>> _tapController =
      StreamController<Map<String, dynamic>>.broadcast();
  Map<String, dynamic>? _pendingTapPayload;
  bool _initialized = false;

  Stream<Map<String, dynamic>> get notificationTaps => _tapController.stream;

  Map<String, dynamic>? takePendingTapPayload() {
    final payload = _pendingTapPayload;
    _pendingTapPayload = null;
    return payload;
  }

  void ingestRemoteTap(Map<String, dynamic> payload) => _recordTap(payload);

  void _recordTap(Map<String, dynamic> payload) {
    final normalized = payload.isEmpty
        ? <String, dynamic>{'route': 'notifications'}
        : Map<String, dynamic>.from(payload);
    _pendingTapPayload = normalized;
    _tapController.add(normalized);
  }

  Future<void> initialize() async {
    if (_initialized) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        _recordTap(decodeNotificationPayload(response.payload));
      },
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      _recordTap(
        decodeNotificationPayload(launchDetails?.notificationResponse?.payload),
      );
    }
    _initialized = true;
  }

  Future<void> requestPermission() async {
    await initialize();
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic> payload = const {},
  }) async {
    await initialize();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.message,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    await _plugin.show(id, title, body, details, payload: jsonEncode(payload));
  }
}
