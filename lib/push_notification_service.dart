import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'notification_service.dart';

typedef PushDeviceRegistrar =
    Future<Object?> Function(Map<String, Object?> body);

const MethodChannel _firebaseConfigChannel = MethodChannel(
  'com.starforge.starforge_student/firebase_config',
);

const _firebaseApiKey = String.fromEnvironment('STARFORGE_FIREBASE_API_KEY');
const _firebaseAppId = String.fromEnvironment('STARFORGE_FIREBASE_APP_ID');
const _firebaseAndroidApiKey = String.fromEnvironment(
  'STARFORGE_FIREBASE_ANDROID_API_KEY',
);
const _firebaseAndroidAppId = String.fromEnvironment(
  'STARFORGE_FIREBASE_ANDROID_APP_ID',
);
const _firebaseIosApiKey = String.fromEnvironment(
  'STARFORGE_FIREBASE_IOS_API_KEY',
);
const _firebaseIosAppId = String.fromEnvironment(
  'STARFORGE_FIREBASE_IOS_APP_ID',
);
const _firebaseMessagingSenderId = String.fromEnvironment(
  'STARFORGE_FIREBASE_MESSAGING_SENDER_ID',
);
const _firebaseProjectId = String.fromEnvironment(
  'STARFORGE_FIREBASE_PROJECT_ID',
);
const _firebaseStorageBucket = String.fromEnvironment(
  'STARFORGE_FIREBASE_STORAGE_BUCKET',
);
const _firebaseIosBundleId = String.fromEnvironment(
  'STARFORGE_FIREBASE_IOS_BUNDLE_ID',
  defaultValue: 'com.starforge.starforgeStudent',
);

String _platformValue(String platformValue, String commonValue) =>
    platformValue.trim().isNotEmpty ? platformValue.trim() : commonValue.trim();

FirebaseOptions? firebaseOptionsFromValues({
  required String apiKey,
  required String appId,
  required String messagingSenderId,
  required String projectId,
  String storageBucket = '',
  String iosBundleId = '',
}) {
  final requiredValues = [apiKey, appId, messagingSenderId, projectId];
  if (requiredValues.any((value) => value.trim().isEmpty)) return null;
  return FirebaseOptions(
    apiKey: apiKey.trim(),
    appId: appId.trim(),
    messagingSenderId: messagingSenderId.trim(),
    projectId: projectId.trim(),
    storageBucket: storageBucket.trim().isEmpty ? null : storageBucket.trim(),
    iosBundleId: iosBundleId.trim().isEmpty ? null : iosBundleId.trim(),
  );
}

FirebaseOptions? _firebaseOptionsFromEnvironment(TargetPlatform platform) {
  final apple = platform == TargetPlatform.iOS;
  return firebaseOptionsFromValues(
    apiKey: _platformValue(
      apple ? _firebaseIosApiKey : _firebaseAndroidApiKey,
      _firebaseApiKey,
    ),
    appId: _platformValue(
      apple ? _firebaseIosAppId : _firebaseAndroidAppId,
      _firebaseAppId,
    ),
    messagingSenderId: _firebaseMessagingSenderId,
    projectId: _firebaseProjectId,
    storageBucket: _firebaseStorageBucket,
    iosBundleId: apple ? _firebaseIosBundleId : '',
  );
}

String pushPlatformName(TargetPlatform platform) => switch (platform) {
  TargetPlatform.android => 'android',
  TargetPlatform.iOS => 'ios',
  _ => 'unsupported',
};

Map<String, Object?> pushDeviceRegistrationBody({
  required String deviceId,
  required String platform,
  required String token,
}) => <String, Object?>{
  'device_id': deviceId,
  'platform': platform,
  'push_token': token,
};

String notificationRouteFromPayload(Map<String, dynamic> payload) {
  if (payload['thread_id']?.toString().trim().isNotEmpty == true) {
    return 'messages';
  }
  for (final key in const ['route', 'screen', 'target', 'resource']) {
    final raw = payload[key]?.toString().trim() ?? '';
    if (raw.isEmpty) continue;
    var route = raw
        .replaceFirst(RegExp(r'^https?://[^/]+/?'), '')
        .replaceFirst(RegExp(r'^/+'), '')
        .replaceFirst(RegExp(r'^api/v1/'), '')
        .split('?')
        .first
        .split('#')
        .first
        .split('/')
        .first
        .trim()
        .toLowerCase();
    const aliases = {
      'notification': 'notifications',
      'notification_detail': 'notifications',
      'message': 'messages',
      'thread': 'messages',
      'profile': 'account',
      'user': 'account',
      'payment': 'finance',
      'assignment': 'assignments',
      'attendance_record': 'attendance',
    };
    route = aliases[route] ?? route;
    if (route.isNotEmpty) return route;
  }
  return 'notifications';
}

Map<String, dynamic> _payloadForMessage(RemoteMessage message) {
  final payload = <String, dynamic>{...message.data};
  final notification = message.notification;
  if (message.messageId case final id?) payload['message_id'] = id;
  if (notification?.title case final title?) payload['title'] = title;
  if (notification?.body case final body?) payload['body'] = body;
  payload.putIfAbsent('route', () => 'notifications');
  return payload;
}

int _notificationId(RemoteMessage message) {
  final source = message.messageId ?? '${message.sentTime}:${message.data}';
  return source.hashCode & 0x7fffffff;
}

@pragma('vm:entry-point')
Future<void> starforgeFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  try {
    await Firebase.initializeApp(
      options: _firebaseOptionsFromEnvironment(defaultTargetPlatform),
    );
    if (message.notification == null) {
      final payload = _payloadForMessage(message);
      await DeviceNotificationService.instance.show(
        id: _notificationId(message),
        title: payload['title']?.toString().trim().isNotEmpty == true
            ? payload['title'].toString()
            : 'StarForge EDU',
        body: payload['body']?.toString().trim().isNotEmpty == true
            ? payload['body'].toString()
            : 'Yangi bildirishnoma bor',
        payload: payload,
      );
    }
  } on Object {
    // A missing Firebase project must never prevent the application starting.
  }
}

/// Firebase Cloud Messaging bridge for authenticated student/parent devices.
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _tapSubscription;
  StreamSubscription<String>? _tokenSubscription;
  PushDeviceRegistrar? _registrar;
  String _deviceId = '';
  String? _lastRegisteredToken;
  bool _initialized = false;
  bool _available = false;
  String? _initializationError;
  String? _registrationError;

  bool get available => _available;
  String? get initializationError => _initializationError;
  String? get registrationError => _registrationError;

  Future<bool> initialize() async {
    if (_initialized) return _available;
    _initialized = true;
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return false;
    }

    try {
      final options = _firebaseOptionsFromEnvironment(defaultTargetPlatform);
      var hasNativeConfiguration = false;
      if (options == null) {
        try {
          hasNativeConfiguration =
              await _firebaseConfigChannel.invokeMethod<bool>(
                'hasNativeFirebaseConfig',
              ) ??
              false;
        } on MissingPluginException {
          hasNativeConfiguration = false;
        }
      }
      if (options == null && !hasNativeConfiguration) {
        _initializationError = 'native_firebase_config_missing';
        return false;
      }

      await Firebase.initializeApp(options: options);
      FirebaseMessaging.onBackgroundMessage(
        starforgeFirebaseMessagingBackgroundHandler,
      );
      final messaging = FirebaseMessaging.instance;
      await messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: false,
      );
      _foregroundSubscription = FirebaseMessaging.onMessage.listen(
        _handleForegroundMessage,
      );
      _tapSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        _handleMessageTap,
      );
      _tokenSubscription = messaging.onTokenRefresh.listen(
        (token) => unawaited(_submitToken(token)),
      );
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) _handleMessageTap(initialMessage);
      _available = true;
      _initializationError = null;
      return true;
    } on Object catch (error) {
      _available = false;
      _initializationError = error.runtimeType.toString();
      return false;
    }
  }

  Future<void> bindAuthenticatedSession({
    required String deviceId,
    required PushDeviceRegistrar registrar,
  }) async {
    _deviceId = deviceId.trim();
    _registrar = registrar;
    _lastRegisteredToken = null;
    if (_deviceId.isEmpty || !await initialize()) return;
    try {
      await DeviceNotificationService.instance.requestPermission();
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        for (var attempt = 0; attempt < 8; attempt++) {
          if (await FirebaseMessaging.instance.getAPNSToken() != null) break;
          await Future<void>.delayed(const Duration(milliseconds: 350));
        }
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.trim().isNotEmpty) await _submitToken(token);
    } on Object catch (error) {
      _registrationError = error.runtimeType.toString();
    }
  }

  void unbindAuthenticatedSession() {
    _registrar = null;
    _deviceId = '';
    _lastRegisteredToken = null;
  }

  Future<void> _submitToken(String token) async {
    final registrar = _registrar;
    final normalizedToken = token.trim();
    if (registrar == null ||
        _deviceId.isEmpty ||
        normalizedToken.isEmpty ||
        normalizedToken == _lastRegisteredToken) {
      return;
    }
    try {
      await registrar(
        pushDeviceRegistrationBody(
          deviceId: _deviceId,
          platform: pushPlatformName(defaultTargetPlatform),
          token: normalizedToken,
        ),
      );
      _lastRegisteredToken = normalizedToken;
      _registrationError = null;
    } on Object catch (error) {
      _registrationError = error.runtimeType.toString();
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final payload = _payloadForMessage(message);
    await DeviceNotificationService.instance.show(
      id: _notificationId(message),
      title: payload['title']?.toString().trim().isNotEmpty == true
          ? payload['title'].toString()
          : 'StarForge EDU',
      body: payload['body']?.toString().trim().isNotEmpty == true
          ? payload['body'].toString()
          : 'Yangi bildirishnoma bor',
      payload: payload,
    );
  }

  void _handleMessageTap(RemoteMessage message) {
    DeviceNotificationService.instance.ingestRemoteTap(
      _payloadForMessage(message),
    );
  }

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _tapSubscription?.cancel();
    await _tokenSubscription?.cancel();
  }
}
