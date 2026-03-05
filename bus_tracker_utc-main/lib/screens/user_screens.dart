import 'dart:async';
import 'package:bus_tracker_utc/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/route_card.dart';
import '../widgets/route_map.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  List<BusRoute> _routes = [];
  bool _showAll = false;
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;
  final Map<int, bool> _openMaps = {};

  @override
  void initState() {
    super.initState();
    _loadRoutes();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadRoutes(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRoutes() async {
    try {
      final api = context.read<ApiService>();
      final routes = await api.getRutas();
      if (mounted) {
        setState(() {
          _routes = routes;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<BusRoute> get _filteredRoutes {
    return _showAll ? _routes : _routes.where((r) => r.isActive).toList();
  }

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
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildRoutesSection()),
                    SliverToBoxAdapter(child: _buildMapsSection()),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  ],
                ),
              ),
              _buildFooter(),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bus Tracker',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                'Cobertura: Saltillo & Ramos Arizpe',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/admin'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade900,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ir a Admin'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutesSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Rutas disponibles',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  Row(
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _showAll,
                            onChanged:
                                (val) =>
                                    setState(() => _showAll = val ?? false),
                          ),
                          const Text(
                            'Mostrar también inactivas',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _loadRoutes,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          foregroundColor: Colors.grey.shade900,
                        ),
                        child: const Text('Actualizar'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_error != null)
                Text(
                  'Error: $_error',
                  style: const TextStyle(color: Colors.red),
                )
              else if (_filteredRoutes.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      'No hay rutas ${_showAll ? '' : 'activas'}.',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns =
                        constraints.maxWidth > 900
                            ? 3
                            : (constraints.maxWidth > 600 ? 2 : 1);
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.5,
                      ),
                      itemCount: _filteredRoutes.length,
                      itemBuilder: (context, index) {
                        final route = _filteredRoutes[index];
                        return RouteCard(
                          route: route,
                          isMapOpen: _openMaps[route.id] ?? false,
                          onToggleMap: () {
                            setState(() {
                              _openMaps[route.id] =
                                  !(_openMaps[route.id] ?? false);
                            });
                          },
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapsSection() {
    final openRoutes = _routes.where((r) => _openMaps[r.id] == true).toList();
    if (openRoutes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (final route in openRoutes)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: RouteMap(
                routeId: route.id,
                onClose: () {
                  setState(() {
                    _openMaps[route.id] = false;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  // Widget _buildMapsSection() {
  //   final openRoutes = _routes.where((r) => _openMaps[r.id] == true).toList();
  //   if (openRoutes.isEmpty) return const SizedBox.shrink();

  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 16),
  //     child: Column(
  //       children: openRoutes.map((route) {
  //         return Padding(
  //           padding: const EdgeInsets.only(bottom: 16),
  //           child: RouteMap(
  //             routeId: route.id,
  //             onClose: () {
  //               setState(() {
  //                 _openMaps[route.id] = false;
  //               });
  //             },
  //           ),
  //         );
  //       }).toList(),
  //     ),
  //   );
  // }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Text(
        'Leaflet + Hono API • Punto de referencia: Saltillo (25.426,-100.995) y Ramos Arizpe (25.549,-100.947)',
        style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
        textAlign: TextAlign.center,
      ),
    );
  }
}
