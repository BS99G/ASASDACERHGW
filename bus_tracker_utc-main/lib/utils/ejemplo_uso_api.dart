import 'package:bus_tracker_utc/services/api_services.dart';

/// Ejemplo de uso del ApiRestManager
/// 
/// Este archivo muestra cómo usar directamente el ApiRestManager
/// en lugar de la capa ApiService si necesitas más control

class EjemploUsoApiRestManager {
  final ApiRestManager api = ApiRestManager();

  /// Ejemplo 1: GET request simple
  Future<void> ejemploGetRutas() async {
    try {
      final response = await api.requestServer('/rutas');
      final data = response.getJson();
      print('Rutas obtenidas: $data');
    } on FetchDataException catch (e) {
      print('Error de red: $e');
    } on BadRequestException catch (e) {
      print('Request inválido: $e');
    } on UnauthorisedException catch (e) {
      print('No autorizado: $e');
    } catch (e) {
      print('Error desconocido: $e');
    }
  }

  /// Ejemplo 2: POST request
  Future<void> ejemploStartTracking() async {
    try {
      final response = await api.postServer('/rutas/start', {
        'id_ruta': 1,
        'lat': 14.0583,
        'long': -87.2109,
        'unidad': 101,
      });
      
      final data = response.getJson();
      print('Tracking iniciado: $data');
    } catch (e) {
      print('Error al iniciar tracking: $e');
    }
  }

  /// Ejemplo 3: PUT request
  Future<void> ejemploPutRequest() async {
    try {
      final response = await api.putServer('/rutas/1/update', {
        'nombre': 'Ruta Actualizada',
        'status': 1,
      });
      
      final data = response.getJson();
      print('Ruta actualizada: $data');
    } catch (e) {
      print('Error al actualizar: $e');
    }
  }

  /// Ejemplo 4: Manejo de errores específicos
  Future<Map<String, dynamic>?> ejemploManejoErrores() async {
    try {
      final response = await api.requestServer('/rutas/999/location');
      return response.getJson();
    } on FetchDataException catch (e) {
      // Error de conexión o comunicación
      print('No hay conexión a Internet o el servidor no responde: $e');
      return null;
    } on BadRequestException catch (e) {
      // Error 400 - Request inválido
      print('El request es inválido: $e');
      return null;
    } on UnauthorisedException catch (e) {
      // Error 401/403 - No autorizado
      print('No estás autorizado: $e');
      return null;
    } catch (e) {
      // Cualquier otro error
      print('Error inesperado: $e');
      return null;
    }
  }
}
