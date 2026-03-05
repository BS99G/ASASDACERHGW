import 'dart:async';
import 'package:bus_tracker_utc/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../constants/map_constants.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _idRutaController = TextEditingController();
  final _unidadController = TextEditingController();
  final _mapController = MapController();

  bool _isTracking = false;
  StreamSubscription<Position>? _positionStream;

  double? _currentLat;
  double? _currentLng;
  int _sentCount = 0;
  String _message = '';
  String _error = '';
  DateTime? _lastSent;

  @override
  void dispose() {
    _stopTracking();
    _idRutaController.dispose();
    _unidadController.dispose();
    super.dispose();
  }

  Future<bool> _checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _setError('Los servicios de ubicación están desactivados');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _setError('Permisos de ubicación denegados');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _setError('Permisos de ubicación denegados permanentemente');
      return false;
    }

    return true;
  }

  Future<void> _sendPing() async {
    if (!await _checkPermissions()) return;

    _setMessage('Obteniendo GPS...');
    _setError('');

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _sendLocation(position.latitude, position.longitude);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> _sendLocation(double lat, double lng) async {
    final idRuta = int.tryParse(_idRutaController.text);
    final unidad = int.tryParse(_unidadController.text);

    if (idRuta == null || unidad == null) {
      _setError('Ingresa id_ruta y unidad');
      return;
    }

    try {
      final api = context.read<ApiService>();
      await api.startTracking(
        idRuta: idRuta,
        lat: lat,
        lng: lng,
        unidad: unidad,
      );

      setState(() {
        _currentLat = lat;
        _currentLng = lng;
        _sentCount++;
        _message = 'Tracking enviado';
        _error = '';
        _lastSent = DateTime.now();
      });

      _mapController.move(LatLng(lat, lng), 15);
      await _checkArrival(idRuta, lat, lng);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> _checkArrival(int idRuta, double lat, double lng) async {
    final distance = Geolocator.distanceBetween(
      lat,
      lng,
      MapConstants.utcRamos.latitude,
      MapConstants.utcRamos.longitude,
    );

    if (distance <= MapConstants.arrivalRadiusM) {
      try {
        final api = context.read<ApiService>();
        await api.cancelRoute(idRuta);
        _setMessage(
          'Llegaste a la UTC (~${distance.round()} m). Viaje finalizado.',
        );
        _stopTracking();
      } catch (e) {
        _setError('Error al auto-cancelar: $e');
      }
    }
  }

  void _startTracking() async {
    if (!await _checkPermissions()) return;

    final idRuta = int.tryParse(_idRutaController.text);
    final unidad = int.tryParse(_unidadController.text);

    if (idRuta == null || unidad == null) {
      _setError('Ingresa id_ruta y unidad');
      return;
    }

    setState(() {
      _isTracking = true;
      _message = 'Tracking en vivo iniciado (cada ~10 s)';
      _error = '';
    });

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      final now = DateTime.now();
      if (_lastSent == null || now.difference(_lastSent!).inSeconds >= 10) {
        _sendLocation(position.latitude, position.longitude);
      }
    });
  }

  void _stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    setState(() {
      _isTracking = false;
      _message = 'Tracking en vivo detenido (no cancela el viaje)';
    });
  }

  Future<void> _cancelTrip() async {
    final idRuta = int.tryParse(_idRutaController.text);
    if (idRuta == null) {
      _setError('Ingresa id_ruta');
      return;
    }

    _setMessage('Cancelando...');
    _setError('');

    try {
      final api = context.read<ApiService>();
      await api.cancelRoute(idRuta);
      _setMessage('Viaje cancelado (status=0)');
      _stopTracking();
    } catch (e) {
      _setError(e.toString());
    }
  }

  void _setMessage(String msg) => setState(() => _message = msg);
  void _setError(String err) => setState(() => _error = err);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF9FAFB), Color(0xFFF3F4F6)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Enviar ubicación (desde este dispositivo)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInputFields(),
                          const SizedBox(height: 16),
                          _buildActionButtons(),
                          const SizedBox(height: 16),
                          _buildStats(),
                          if (_message.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              _message,
                              style: const TextStyle(color: Colors.green),
                            ),
                          ],
                          if (_error.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              _error,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                          const SizedBox(height: 24),
                          _buildMap(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Panel de Admin / Dispositivo',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade900,
              foregroundColor: Colors.white,
            ),
            child: const Text('Volver a Usuario'),
          ),
        ],
      ),
    );
  }

  Widget _buildInputFields() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return Row(
            children: [
              Expanded(
                child: _buildTextField('ID ruta', _idRutaController, '1'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField('unidad', _unidadController, '101'),
              ),
              const SizedBox(width: 16),
            ],
          );
        } else {
          return Column(
            children: [
              _buildTextField('ID ruta', _idRutaController, '1'),
              const SizedBox(height: 12),
              _buildTextField('unidad', _unidadController, '101'),
            ],
          );
        }
      },
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ElevatedButton(
          onPressed: _isTracking ? null : _startTracking,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade900,
            foregroundColor: Colors.white,
          ),
          child: const Text('Iniciar tracking en vivo (GPS)'),
        ),
        ElevatedButton(
          onPressed: _isTracking ? _stopTracking : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade100,
            foregroundColor: Colors.grey.shade900,
          ),
          child: const Text('Detener tracking en vivo'),
        ),
        ElevatedButton(
          onPressed: _cancelTrip,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
          ),
          child: const Text('Cancelar viaje'),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2,
          children: [
            _buildStatCard('Lat', _currentLat?.toStringAsFixed(6) ?? '—'),
            _buildStatCard('Long', _currentLng?.toStringAsFixed(6) ?? '—'),
            _buildStatCard('Envíos', _sentCount.toString()),
            _buildStatCard('Estado', _isTracking ? 'Activo' : '—'),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 380,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: MapConstants.saltillo,
                initialZoom: 11,
                minZoom: 10,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'dev.fleaflet.flutter_map.example',
  // + many other options
),
                // TileLayer(
                //   urlTemplate:
                //       'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                //   subdomains: const ['a', 'b', 'c'],
                // ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: MapConstants.saltillo,
                      color: const Color(0xFF1e3a8a).withOpacity(0.3),
                      borderColor: const Color(0xFF1e3a8a),
                      borderStrokeWidth: 2,
                      radius: 6,
                    ),
                    CircleMarker(
                      point: MapConstants.ramosArizpe,
                      color: const Color(0xFF16a34a).withOpacity(0.3),
                      borderColor: const Color(0xFF16a34a),
                      borderStrokeWidth: 2,
                      radius: 6,
                    ),
                    CircleMarker(
                      point: MapConstants.utcRamos,
                      color: const Color(0xFF16a34a).withOpacity(0.08),
                      borderColor: const Color(0xFF16a34a),
                      borderStrokeWidth: 1,
                      radius: MapConstants.arrivalRadiusM,
                      useRadiusInMeter: true,
                    ),
                  ],
                ),
                if (_currentLat != null && _currentLng != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(_currentLat!, _currentLng!),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.directions_bus,
                          color: Colors.blue,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'El marcador se coloca donde está tu GPS. Debes usar HTTPS o localhost.',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}
