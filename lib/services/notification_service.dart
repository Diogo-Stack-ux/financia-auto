import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize() async {
    if (!supported || _initialized) return;
    data.initializeTimeZones();
    final deviceZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(deviceZone.identifier));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  Future<bool> enable() async {
    if (!supported) return false;
    await initialize();
    bool granted = false;
    if (defaultTargetPlatform == TargetPlatform.android) {
      granted =
          await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    } else {
      granted =
          await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    if (granted) await scheduleDaily();
    return granted;
  }

  Future<void> scheduleDaily() async {
    if (!supported) return;
    await initialize();
    const reminders = [
      (
        9,
        'Seu próximo carro começa com um plano',
        'Simule uma parcela que cabe no seu orçamento.',
      ),
      (
        14,
        'Uma entrada maior faz diferença',
        'Compare cenários antes de escolher seu financiamento.',
      ),
      (
        19,
        'Que tal revisar suas simulações?',
        'Seu histórico ajuda a comparar prazo, parcela e juros.',
      ),
    ];
    try {
      for (var i = 0; i < reminders.length; i++) {
        final (hour, title, body) = reminders[i];
        final now = tz.TZDateTime.now(tz.local);
        var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
        if (!next.isAfter(now)) {
          next = tz.TZDateTime(
            tz.local,
            now.year,
            now.month,
            now.day + 1,
            hour,
          );
        }
        await _plugin.zonedSchedule(
          id: 100 + i,
          title: title,
          body: body,
          scheduledDate: next,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'daily_planning',
              'Planejamento do veículo',
              channelDescription:
                  'Três lembretes diários de planejamento financeiro',
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    } catch (_) {
      await disable();
      rethrow;
    }
  }

  Future<void> disable() async {
    if (!supported) return;
    await initialize();
    for (var id = 100; id < 103; id++) {
      await _plugin.cancel(id: id);
    }
  }
}
