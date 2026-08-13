import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pasos reales del sensor del teléfono. El sensor entrega un contador
/// ACUMULADO desde el último reinicio del dispositivo, no "pasos de hoy" —
/// por eso guardamos una base al empezar el día y restamos contra eso.
///
/// En desktop/web no hay sensor: [available] queda en false y la UI debe
/// mostrar un estado claro de "no disponible" en vez de quedarse cargando
/// para siempre o inventar un número. Importante: en Flutter Web, tocar
/// `Platform.isAndroid` tira una excepción — por eso `kIsWeb` se chequea
/// SIEMPRE primero, antes de cualquier acceso a Platform.
class StepService {
  StepService._();
  static final StepService instance = StepService._();

  final _controller = StreamController<int>.broadcast();
  Stream<int> get todaySteps => _controller.stream;

  StreamSubscription<StepCount>? _sub;
  int? _baseline;
  DateTime? _baselineDay;
  bool _available = true;
  bool get available => _available;

  /// Último valor emitido — para que una pantalla que se abre después de
  /// [start] pueda mostrar el número ya conocido sin esperar el próximo
  /// evento del sensor (que puede tardar).
  int? _lastValue;
  int? get lastValue => _lastValue;

  void _emit(int steps) {
    _lastValue = steps;
    _controller.add(steps);
  }

  Future<void> start() async {
    try {
      if (kIsWeb) {
        _available = false;
        _emit(0);
        return;
      }

      if (!Platform.isAndroid && !Platform.isIOS) {
        _available = false;
        _emit(0);
        return;
      }

      if (Platform.isAndroid) {
        final status = await Permission.activityRecognition.request();
        if (!status.isGranted) {
          _available = false;
          _emit(0);
          return;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final savedDay = prefs.getString('steps_baseline_day');
      final today = _dateKey(DateTime.now());
      if (savedDay == today) {
        _baseline = prefs.getInt('steps_baseline_value');
        _baselineDay = DateTime.now();
      }

      _sub = Pedometer.stepCountStream.listen(
        (event) async {
          final todayKey = _dateKey(event.timeStamp);
          if (_baseline == null || _baselineDay == null || _dateKey(_baselineDay!) != todayKey) {
            _baseline = event.steps;
            _baselineDay = event.timeStamp;
            await prefs.setString('steps_baseline_day', todayKey);
            await prefs.setInt('steps_baseline_value', _baseline!);
          }
          final steps = (event.steps - _baseline!).clamp(0, 1000000);
          _emit(steps);
        },
        onError: (_) {
          _available = false;
          _emit(0);
        },
        cancelOnError: true,
      );
    } catch (_) {
      // Cualquier plataforma/entorno no soportado: estado honesto de "no
      // disponible", nunca una pantalla pegada esperando un valor que no va a llegar.
      _available = false;
      _emit(0);
    }
  }

  /// Kcal activas estimadas a partir de pasos reales y el peso real del
  /// usuario (fórmula estándar: ~0,00045 kcal por paso y por kg).
  static int activeKcalFromSteps(int steps, double weightKg) {
    return (steps * weightKg * 0.00045).round();
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
