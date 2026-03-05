class Prefs {
  // URL base del API
  static String _baseUrl = 'https://api-hono.kevin-cruzz.workers.dev';

  /// Obtiene la URL base configurada
  static String getWindowsUrl() {
    return _baseUrl;
  }

  /// Permite cambiar la URL base si es necesario
  static void setBaseUrl(String url) {
    _baseUrl = url;
  }
}
