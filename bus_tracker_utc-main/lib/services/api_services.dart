import 'dart:convert';
import 'dart:io';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:bus_tracker_utc/utils/prefs.dart';

class JsonResponse extends http.Response {
  JsonResponse(super.body, super.statusCode);

  dynamic getJson() {
    var data = json.decode(
      body.toString(),
    );
    return data;
  }
}

class ApiRestManager {
  static String baseUrl() {
    return Prefs.getWindowsUrl();
  }

  Future<JsonResponse> requestServer(String path) async {
    JsonResponse responseJson;

    try {
      String url = baseUrl() + path;

      var response = await http.get(Uri.parse(url));

      responseJson = _response(response);
    } on SocketException {
      throw FetchDataException('No Internet connection');
    }

    return responseJson;
  }

  Future<JsonResponse> postServer(String path, dynamic body) async {
    JsonResponse responseJson;

    try {
      String url = baseUrl() + path;
      var response = await http.post(Uri.parse(url), body: jsonEncode(body));

      responseJson = _response(response);
    } on SocketException {
      throw FetchDataException('No Internet connection');
    }

    return responseJson;
  }

  Future<JsonResponse> putServer(String path, dynamic body) async {
    JsonResponse responseJson;

    try {
      String url = baseUrl() + path;
      var response = await http.put(Uri.parse(url), body: jsonEncode(body));

      responseJson = _response(response);
    } on SocketException {
      throw FetchDataException('No Internet connection');
    }

    return responseJson;
  }

  JsonResponse _response(http.Response response) {
    log('Response status: ${response.statusCode}');

    switch (response.statusCode) {
      case 200:
        return JsonResponse(response.body, response.statusCode);
      case 400:
        throw BadRequestException(response.body.toString());
      case 401:
        throw UnauthorisedException(response.body.toString());
      case 403:
        throw UnauthorisedException(response.body.toString());
      case 500:
      default:
        throw FetchDataException(
          'Error occured while Communication with Server with StatusCode : ${response.statusCode}',
        );
    }
  }
}

class CustomException implements Exception {
  // ignore: prefer_typing_uninitialized_variables
  final _message;
  // ignore: prefer_typing_uninitialized_variables
  final _prefix;

  CustomException([this._message, this._prefix]);

  @override
  String toString() {
    return "$_prefix$_message";
  }
}

class FetchDataException extends CustomException {
  FetchDataException([String? message])
      : super(message, "Error During Communication: ");
}

class BadRequestException extends CustomException {
  BadRequestException([message]) : super(message, "Invalid Request: ");
}

class UnauthorisedException extends CustomException {
  UnauthorisedException([message]) : super(message, "Unauthorised: ");
}

class InvalidInputException extends CustomException {
  InvalidInputException([String? message]) : super(message, "Invalid Input: ");
}

// Clase de servicio compatible con el patrón anterior
class ApiService {
  final ApiRestManager _api = ApiRestManager();

  Future<List<BusRoute>> getRutas() async {
    final response = await _api.requestServer('/rutas');
    final data = response.getJson() as List<dynamic>;
    return data.map((json) => BusRoute.fromJson(json)).toList();
  }

  Future<LocationData> getRouteLocation(int routeId) async {
    final response = await _api.requestServer('/rutas/$routeId/location');
    final data = response.getJson() as Map<String, dynamic>;
    return LocationData.fromJson(data);
  }

  Future<void> startTracking({
    required int idRuta,
    required double lat,
    required double lng,
    required int unidad,
  }) async {
    await _api.postServer('/rutas/start', {
      'id_ruta': idRuta,
      'lat': lat,
      'long': lng,
      'unidad': unidad,
    });
  }

  Future<void> cancelRoute(int idRuta) async {
    await _api.postServer('/rutas/cancel', {'id_ruta': idRuta});
  }
}

class BusRoute {
  final int id;
  final String? nombre;
  final int status;
  final int? unidad;
  final double? lat;
  final double? long;

  BusRoute({
    required this.id,
    this.nombre,
    required this.status,
    this.unidad,
    this.lat,
    this.long,
  });

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    return BusRoute(
      id: json['id'] as int,
      nombre: json['nombre'] as String?,
      status: json['status'] as int? ?? 0,
      unidad: json['unidad'] as int?,
      lat: (json['lat'] as num?)?.toDouble(),
      long: (json['long'] as num?)?.toDouble(),
    );
  }

  bool get isActive => status == 1;
}

class LocationData {
  final int? status;
  final double? lat;
  final double? lng;

  LocationData({this.status, this.lat, this.lng});

  factory LocationData.fromJson(Map<String, dynamic> json) {
    final statusVal = json['status'] ?? (json['activo'] == true ? 1 : 0);
    final latVal = json['lat'] ?? json['latitude'];
    final lngVal = json['long'] ?? json['lng'] ?? json['longitude'];

    return LocationData(
      status: statusVal is int ? statusVal : (statusVal == true ? 1 : 0),
      lat: (latVal as num?)?.toDouble(),
      lng: (lngVal as num?)?.toDouble(),
    );
  }

  bool get isActive => status == 1;
  LatLng? get position =>
      (lat != null && lng != null) ? LatLng(lat!, lng!) : null;
}
