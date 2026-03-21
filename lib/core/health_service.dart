// ============================================================
//  health_service.dart — HalalCalorie
//  Real steps, heart rate, sleep from Google Fit / Health Connect
// ============================================================
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthService {
  static final _health = Health();

  // ── Data types we want ─────────────────────────────────
  static const _types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  static const _permissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  // ── Request permissions ────────────────────────────────
  static Future<bool> requestPermissions() async {
    try {
      // Request activity recognition permission
      await Permission.activityRecognition.request();
      await Permission.sensors.request();

      // Configure health
      await _health.configure(useHealthConnectIfAvailable: true);

      // Request health permissions
      final granted = await _health.requestAuthorization(
        _types,
        permissions: _permissions,
      );
      return granted;
    } catch (e) {
      return false;
    }
  }

  // ── Check if authorized ────────────────────────────────
  static Future<bool> isAuthorized() async {
    try {
      await _health.configure(useHealthConnectIfAvailable: true);
      return await _health.hasPermissions(_types) ?? false;
    } catch (e) {
      return false;
    }
  }

  // ── Get today steps ───────────────────────────────────
  static Future<int> getTodaySteps() async {
    try {
      final now   = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final steps = await _health.getTotalStepsInInterval(start, now);
      return steps ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // ── Get latest heart rate ─────────────────────────────
  static Future<int> getLatestHeartRate() async {
    try {
      final now   = DateTime.now();
      final start = now.subtract(const Duration(hours: 24));

      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: [HealthDataType.HEART_RATE],
      );

      if (data.isEmpty) return 0;

      // Get most recent reading
      data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      final latest = data.first.value;
      if (latest is NumericHealthValue) {
        return latest.numericValue.round();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // ── Get last night sleep hours ────────────────────────
  static Future<double> getLastNightSleep() async {
    try {
      final now   = DateTime.now();
      final start = DateTime(now.year, now.month, now.day - 1, 18); // 6pm yesterday
      final end   = DateTime(now.year, now.month, now.day, 12);     // noon today

      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: [HealthDataType.SLEEP_ASLEEP, HealthDataType.SLEEP_IN_BED],
      );

      if (data.isEmpty) return 0;

      // Sum all sleep segments in minutes then convert to hours
      double totalMinutes = 0;
      for (final d in data) {
        if (d.type == HealthDataType.SLEEP_ASLEEP) {
          final duration = d.dateTo.difference(d.dateFrom).inMinutes;
          totalMinutes += duration;
        }
      }

      return double.parse((totalMinutes / 60).toStringAsFixed(1));
    } catch (e) {
      return 0;
    }
  }

  // ── Get active calories burned today ──────────────────
  static Future<int> getActiveCaloriesToday() async {
    try {
      final now   = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);

      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
      );

      double total = 0;
      for (final d in data) {
        if (d.value is NumericHealthValue) {
          total += (d.value as NumericHealthValue).numericValue;
        }
      }
      return total.round();
    } catch (e) {
      return 0;
    }
  }

  // ── Full today snapshot ───────────────────────────────
  static Future<HealthSnapshot> getTodaySnapshot() async {
    final authorized = await isAuthorized();
    if (!authorized) {
      return HealthSnapshot.empty();
    }

    final results = await Future.wait([
      getTodaySteps(),
      getLatestHeartRate(),
      getLastNightSleep(),
      getActiveCaloriesToday(),
    ]);

    return HealthSnapshot(
      steps:          results[0] as int,
      heartRate:      results[1] as int,
      sleepHours:     results[2] as double,
      activeCalories: results[3] as int,
      isReal:         true,
    );
  }
}

// ── Snapshot model ────────────────────────────────────────
class HealthSnapshot {
  final int    steps;
  final int    heartRate;
  final double sleepHours;
  final int    activeCalories;
  final bool   isReal;

  const HealthSnapshot({
    required this.steps,
    required this.heartRate,
    required this.sleepHours,
    required this.activeCalories,
    required this.isReal,
  });

  factory HealthSnapshot.empty() => const HealthSnapshot(
    steps: 0, heartRate: 0, sleepHours: 0,
    activeCalories: 0, isReal: false,
  );
}
