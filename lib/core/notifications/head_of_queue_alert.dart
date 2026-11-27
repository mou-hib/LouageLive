import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Rings the chauffeur's phone when their louage reaches the head of the
/// queue (C3 → C4): a local notification plus a strong haptic.
///
/// Local only: it fires while the app runs (foreground or recently
/// backgrounded with the Realtime socket still open). A push needs FCM.
abstract interface class HeadOfQueueAlert {
  /// Asks the notification permission (Android 13+, iOS). Called when the
  /// chauffeur enters a queue, not at the moment it rings.
  Future<void> prepare();

  /// Texts are already translated (the caller has the locale).
  Future<void> ring({
    required String title,
    required String body,
    required String channelName,
  });
}

final headOfQueueAlertProvider = Provider<HeadOfQueueAlert>(
  (ref) => LocalHeadOfQueueAlert(),
);

class LocalHeadOfQueueAlert implements HeadOfQueueAlert {
  static const _channelId = 'tete_de_file';
  static const _notificationId = 1;

  final _plugin = FlutterLocalNotificationsPlugin();
  Future<bool?>? _init;

  Future<bool?> _initialize() => _init ??= _plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ),
  );

  @override
  Future<void> prepare() => _safely('prepare', () async {
    await _initialize();
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, sound: true);
  });

  @override
  Future<void> ring({
    required String title,
    required String body,
    required String channelName,
  }) async {
    await _safely('haptic', () async {
      await HapticFeedback.heavyImpact();
      await HapticFeedback.vibrate();
    });
    await _safely('show', () async {
      await _initialize();
      await _plugin.show(
        id: _notificationId,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            channelName,
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
        ),
      );
    });
  }

  /// A missing permission or plugin must never break the queue screen.
  Future<void> _safely(String what, Future<void> Function() body) async {
    try {
      await body();
    } catch (e, st) {
      developer.log(
        'Head-of-queue alert: $what failed',
        name: 'HeadOfQueueAlert',
        error: e,
        stackTrace: st,
      );
    }
  }
}
