import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_student/notification_service.dart';
import 'package:starforge_student/push_notification_service.dart';

void main() {
  test('Firebase options require a complete project identity', () {
    expect(
      firebaseOptionsFromValues(
        apiKey: '',
        appId: 'app',
        messagingSenderId: 'sender',
        projectId: 'project',
      ),
      isNull,
    );
    expect(
      firebaseOptionsFromValues(
        apiKey: 'api',
        appId: 'app',
        messagingSenderId: 'sender',
        projectId: 'project',
      ),
      isA<FirebaseOptions>()
          .having((value) => value.projectId, 'projectId', 'project')
          .having((value) => value.messagingSenderId, 'sender', 'sender'),
    );
  });

  test('push registration matches backend device contract', () {
    expect(pushPlatformName(TargetPlatform.android), 'android');
    expect(pushPlatformName(TargetPlatform.iOS), 'ios');
    expect(
      pushDeviceRegistrationBody(
        deviceId: 'family-device',
        platform: 'android',
        token: 'fcm-token',
      ),
      {
        'device_id': 'family-device',
        'platform': 'android',
        'push_token': 'fcm-token',
      },
    );
  });

  test('notification payloads map to family portal destinations', () {
    expect(notificationRouteFromPayload({'thread_id': 12}), 'messages');
    expect(
      notificationRouteFromPayload({'route': '/api/v1/attendance/records/44/'}),
      'attendance',
    );
    expect(notificationRouteFromPayload({'resource': 'payment'}), 'finance');
    expect(notificationRouteFromPayload(const {}), 'notifications');
    expect(decodeNotificationPayload('messages'), {'route': 'messages'});
  });
}
