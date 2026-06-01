import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:my_first_app/screens/event_detail_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/event.dart';
import '../providers/event_provider.dart';


class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  bool _mapReady = false;
  String? _lastFitSignature;
  String _me = 'guest@local';

  static const LatLng cityCenter = LatLng(41.9028, 12.4964); // Roma

  @override
  void initState() {
    super.initState();
    _loadMe();
  }

  Future<void> _loadMe() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _me = prefs.getString('user_email') ?? 
            prefs.getString('currentUserEmail') ?? 
            prefs.getString('email') ?? 
            'guest@local';
    });
  }

  void _zoom(double delta) {
    final cam = _mapController.camera;
    _mapController.move(cam.center, cam.zoom + delta);
  }

  void _fitToPointsIfNeeded(List<LatLng> points) {
    if (!_mapReady || points.isEmpty) return;

    final signature = points
        .map((p) =>
            '${p.latitude.toStringAsFixed(5)},${p.longitude.toStringAsFixed(5)}')
        .join('|');

    if (_lastFitSignature == signature) return;
    _lastFitSignature = signature;

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted || !_mapReady) return;

      if (points.length == 1) {
        _mapController.move(points.first, 15);
        return;
      }

      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.all(60),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final events = context.watch<EventProvider>().events;
    final markers = <Marker>[];

    for (final e in events) {
  final lat = e.lat;
  final lng = e.lng;

  if (lat == null || lng == null) continue;
  if (!lat.isFinite || !lng.isFinite) continue;
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) continue;

  final pos = LatLng(lat, lng);
      final bool isGuest = _me == 'guest@local';
      final bool isMine = e.participants.any((p) => p.trim().toLowerCase() == _me.trim().toLowerCase());

      Color color;
      if (!isGuest && isMine) {
        color = Colors.orange; 
      } else if (e.listType == ListType.open) {
        color = Colors.green; 
      } else {
        color = Colors.redAccent; 
      }

      markers.add(
        Marker(
          point: pos,
          width: 50,
          height: 50,
          key: ValueKey('marker-${e.id}-$isMine-${e.participants.length}'), 
          child: GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EventDetailPage(event: e)),
              );
              _loadMe();
            },
            child: Icon(Icons.location_on, size: 45, color: color),
          ),
        ),
      );
    }

    _fitToPointsIfNeeded(markers.map((m) => m.point).toList());

    return Scaffold(
      appBar: AppBar(title: const Text('Mappa Eventi')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: cityCenter,
              initialZoom: 12,
              onMapReady: () {
                _mapReady = true;
                _lastFitSignature = null;
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'my_first_app',
              ),
              MarkerLayer(markers: markers),
            ],
          ),

          // POSIZIONE ORIGINALE (bottom: 110, right: 20)
          Positioned(
            bottom: 110,
            right: 20,
            child: Column(
              children: [
                _ZoomButton(icon: Icons.add, onTap: () => _zoom(1)),
                const SizedBox(height: 8),
                _ZoomButton(icon: Icons.remove, onTap: () => _zoom(-1)),
              ],
            ),
          ),

          // POSIZIONE ORIGINALE (top: 16, right: 16)
          Positioned(
            top: 16,
            right: 16,
            child: _Legend(),
          ),
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25), // Forma a pillola
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.black),
        onPressed: onTap,
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20), // Forma a pillola/arrotondata
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendItem(color: Colors.green, label: 'Aperto'),
          SizedBox(height: 6),
          _LegendItem(color: Colors.redAccent, label: 'Privato'),
          SizedBox(height: 6),
          _LegendItem(color: Colors.orange, label: 'Iscritto'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on, color: color, size: 18),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}