// notifications.dart — SunnahStride v1.0
// Prayer reminders, water, workout, fasting — all halal content
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> init() async { const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _ready = true;
  }

  static Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static const _channel = AndroidNotificationDetails( 'sunnahstride_main', 'SunnahStride', channelDescription:'SunnahStride reminders',
    importance: Importance.high,
    priority: Priority.high, icon:'@mipmap/ic_launcher',
  );

  // ── Instant notification ─────────────────────────────────
  static Future<void> show(int id, String title, String body) async {
    if (!_ready) return;
    await _plugin.show(id, title, body, NotificationDetails(android: _channel));
  }

  // ── Water reminder (every 2h) ─────────────────────────────
  static Future<void> scheduleWaterReminder({bool isAr = true}) async {
    if (!_ready) return; final title = isAr ?'💧 وقت الماء!' : '💧 Time to hydrate!';
    final body  = isAr ?'اشرب كوبًا من الماء الآن — السنة في الشرب بثلاث جرعات' :'Drink a glass of water — Sunnah says drink in 3 sips';
    // Schedule for next 8 hours, every 2 hours
    for (int h = 2; h <= 8; h += 2) {
      await _plugin.show(100 + h, title, body, NotificationDetails(android: _channel));
    }
  }

  // ── Workout reminder ─────────────────────────────────────
  static Future<void> showWorkoutReminder({bool isAr = true}) async {
    if (!_ready) return;
    await show(
      200, isAr ?'🏃 وقت التمرين!' : '🏃 Time to work out!',
      isAr ?'المؤمن القوي خير وأحب إلى الله من المؤمن الضعيف — مسلم' :'"The strong believer is better & more beloved to Allah" — Muslim',
    );
  }

  // ── Meal reminder ────────────────────────────────────────
  static Future<void> showMealReminder({bool isAr = true}) async {
    if (!_ready) return;
    await show(
      300, isAr ?'🌿 تذكير الوجبة' : '🌿 Meal reminder',
      isAr ?'لا تنسَ تسجيل وجبتك وتحقق من الحلال' :'Don\'t forget to log your meal and check halal status',
    );
  }

  // ── Fasting reminder ─────────────────────────────────────
  static Future<void> showFastingTip({bool isAr = true}) async {
    if (!_ready) return;
    await show(
      400, isAr ?'🌙 نصيحة رمضان' : '🌙 Ramadan tip',
      isAr ?'تسحّر ولو بشربة ماء — بركة السحور' :'Have suhoor even if just water — the blessing of suhoor',
    );
  }

  static Future<void> cancelAll() async {
    if (!_ready) return;
    await _plugin.cancelAll();
  }
}
