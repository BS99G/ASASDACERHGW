import 'package:bus_tracker_utc/services/api_services.dart';
import 'package:flutter/material.dart';

class RouteCard extends StatelessWidget {
  final BusRoute route;
  final bool isMapOpen;
  final VoidCallback onToggleMap;

  const RouteCard({
    super.key,
    required this.route,
    required this.isMapOpen,
    required this.onToggleMap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onToggleMap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.nombre ?? 'Ruta #${route.id}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildStatusBadge(),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: onToggleMap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade900,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: Text(isMapOpen ? 'Ocultar mapa' : 'Abrir mapa'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfo('ID', route.id.toString()),
              if (route.unidad != null)
                _buildInfo('Unidad', route.unidad.toString()),
              _buildInfo(
                'Última lat/long',
                '${route.lat?.toStringAsFixed(6) ?? '—'} / ${route.long?.toStringAsFixed(6) ?? '—'}',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final isActive = route.isActive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFDCFCE7) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF16a34a) : Colors.grey.shade500,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'Activa' : 'Inactiva',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isActive ? const Color(0xFF16a34a) : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
