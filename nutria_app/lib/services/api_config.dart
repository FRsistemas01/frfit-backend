/// URL base del backend. Por defecto apunta a la IP de LAN de desarrollo
/// (así un celular real en la misma Wi-Fi llega al Django que corrés en tu
/// PC). Para un build de release, pasar la URL real del backend desplegado:
///
///   flutter build appbundle --dart-define=API_BASE_URL=https://nutria-backend.onrender.com/api
class ApiConfig {
  ApiConfig._();

  static const String _devLanHost = '192.168.100.124';
  static const int _devPort = 8001;

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://$_devLanHost:$_devPort/api',
  );
}
