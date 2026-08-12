import 'package:flutter/foundation.dart';

/// Bus simple para avisar a las pantallas que dependen del diario (Hoy, Diario)
/// que algo cambió en otro lado (comida agregada/borrada, peso nuevo, plan
/// guardado) y tienen que refrescar sus datos.
class DiaryBus extends ChangeNotifier {
  DiaryBus._();
  static final DiaryBus instance = DiaryBus._();

  void refresh() => notifyListeners();
}
