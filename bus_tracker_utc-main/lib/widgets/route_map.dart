import 'dart:async';
import 'package:bus_tracker_utc/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../constants/map_constants.dart';

class RouteMap extends StatefulWidget {
  final int routeId;
  final VoidCallback onClose;

  const RouteMap({super.key, required this.routeId, required this.onClose});

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> {
  final MapController _mapController = MapController();
  final List<LatLng> _path = [];
  Timer? _pollTimer;

  bool _isActive = false;
  String? _error;
  LatLng? _currentPosition;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _tick();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _tick());
  }

  Future<void> _tick() async {
    try {
      final api = context.read<ApiService>();
      final data = await api.getRouteLocation(widget.routeId);

      if (!mounted) return;

      setState(() {
        _isActive = data.isActive;
        _error = null;

        if (data.position != null) {
          final newPos = data.position!;

          // Solo agregar si es diferente
          if (_path.isEmpty ||
              _path.last.latitude != newPos.latitude ||
              _path.last.longitude != newPos.longitude) {
            _path.add(newPos);

            // Limitar el historial
            if (_path.length > 600) {
              _path.removeAt(0);
            }

            _currentPosition = newPos;
            _mapController.move(newPos, _mapController.camera.zoom);
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildHeader(),
          SizedBox(
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
                // Ruta predefinida (solo para ruta 1)
                if (widget.routeId == 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: MapConstants.route1Coords,
                        strokeWidth: 5,
                        color: Colors.blue.withOpacity(0.5),
                      ),
                    ],
                  ),
                // Path del tracking en vivo
                if (_path.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _path,
                        strokeWidth: 3,
                        color: Colors.purple,
                        //isDotted: true,
                      ),
                    ],
                  ),
                // Círculos de referencia
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
                    // Zona de llegada
                    if (widget.routeId == 1)
                      CircleMarker(
                        point: MapConstants.utcRamos,
                        color: const Color(0xFF16a34a).withOpacity(0.06),
                        borderColor: const Color(0xFF16a34a),
                        borderStrokeWidth: 1,
                        radius: MapConstants.arrivalRadiusM,
                        useRadiusInMeter: true,
                      ),
                  ],
                ),
                // Marcadores de inicio y destino (ruta 1)
                if (widget.routeId == 1)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: MapConstants.priSaltillo,
                        width: 80,
                        height: 30,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: const Color(0xFF1e3a8a),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Text(
                            'Inicio',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Marker(
                        point: MapConstants.utcRamos,
                        width: 80,
                        height: 30,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: const Color(0xFF16a34a),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Text(
                            'UTC',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                // Marcador del bus actual
                if (_currentPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentPosition!,
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
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.red.shade50,
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Ruta #${widget.routeId}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              _buildStatusBadge(),
            ],
          ),
          ElevatedButton(
            onPressed: widget.onClose,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              foregroundColor: Colors.grey.shade900,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text('Cerrar mapa', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _isActive ? const Color(0xFFDCFCE7) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _isActive ? const Color(0xFF16a34a) : Colors.grey.shade500,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _isActive ? 'Activa' : 'Inactiva',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _isActive ? const Color(0xFF16a34a) : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
