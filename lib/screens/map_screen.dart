import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/event.dart';
import '../providers/event_provider.dart';
import 'event_detail_page.dart';

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

  @override
  void initState() {
    super.initState();
    _loadMe();
  }

  Future<void> _loadMe() async {
    final prefs = await SharedPreferences.getInstance();
    final me = prefs.getString('currentUserEmail') ??
        prefs.getString('userEmail') ??
        prefs.getString('email') ??
        'guest@local';
    if (!mounted) return;
    setState(() => _me = me);
  }

  // Coordinate “per zona” (privacy-safe)
  static const Map<String, LatLng> zoneCoords = {
    'Infernetto': LatLng(41.7479, 12.3774),
    'EUR': LatLng(41.8290, 12.4663),
    'Trastevere': LatLng(41.8897, 12.4690),
    'San Lorenzo': LatLng(41.8978, 12.5108),
    'Testaccio': LatLng(41.8786, 12.4768),
    'Ostia': LatLng(41.7324, 12.2797),
    'Centro': LatLng(41.9028, 12.4964),
  };

  LatLng _coordForZone(String zone, LatLng cityCenter) {
    final known = zoneCoords[zone];
    if (known != null) return known;

    final h = zone.hashCode;
    final latOffset = ((h % 1000) - 500) / 200000; // ~ -0.0025..+0.0025
    final lngOffset = (((h ~/ 1000) % 1000) - 500) / 200000;

    return LatLng(
      cityCenter.latitude + latOffset,
      cityCenter.longitude + lngOffset,
    );
  }

  LatLng? _pickCenter(Map<String, List<Event>> byZone) {
    for (final z in byZone.keys) {
      final pos = zoneCoords[z];
      if (pos != null) return pos;
    }
    return null;
  }

  void _fitToPointsIfNeeded(List<LatLng> points) {
    if (!_mapReady) return;
    if (points.isEmpty) return;

    // no NaN coords
    if (points.any((p) => p.latitude.isNaN || p.longitude.isNaN)) return;

    // Firma per evitare fit ripetuti uguali
    final signature = points
        .map((p) =>
            '${p.latitude.toStringAsFixed(5)},${p.longitude.toStringAsFixed(5)}')
        .join('|');

    if (_lastFitSignature == signature) return;
    _lastFitSignature = signature;

    // Delay piccolo: su web evita glitch di layout
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      if (!_mapReady) return;

      // ✅ FIX: se 1 solo punto, NON fare bounds-fit (area zero => Infinity/NaN)
      if (points.length == 1) {
        _mapController.move(points.first, 15); // zoom fisso “safe”
        return;
      }

      // ✅ bounds fit solo con >= 2 punti
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(60),
        ),
      );
    });
  }

  void _openZoneSheet(BuildContext context, String zone, List<Event> events) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final sorted = [...events]..sort((a, b) => a.date.compareTo(b.date));
        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (_, i) {
              final e = sorted[i];
              return ListTile(
                title: Text(e.name),
                subtitle: Text(
                  '${e.participants.length}/${e.maxParticipants} • ${e.zone ?? ''}',
                ),
                trailing: Text(e.listType == ListType.open ? 'Aperta' : 'Privata'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EventDetailPage(event: e)),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  _MarkerStyle _styleForZone(List<Event> events) {
    final hasPrivate = events.any((e) => e.listType == ListType.closed);
    final hasOpen = events.any((e) => e.listType == ListType.open);
    final isParticipatingHere = events.any((e) => e.participants.contains(_me));

    if (isParticipatingHere) {
      return const _MarkerStyle(
        color: Colors.amber,
        icon: Icons.star,
        label: 'Stai partecipando',
      );
    }
    if (hasPrivate && !hasOpen) {
      return const _MarkerStyle(
        color: Colors.redAccent,
        icon: Icons.lock,
        label: 'Solo privati',
      );
    }
    if (hasOpen && !hasPrivate) {
      return const _MarkerStyle(
        color: Colors.green,
        icon: Icons.event,
        label: 'Solo pubblici',
      );
    }
    return const _MarkerStyle(
      color: Colors.orange,
      icon: Icons.layers,
      label: 'Misti (pubblici + privati)',
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = context.watch<EventProvider>().events;

    // Raggruppa eventi per zona
    final Map<String, List<Event>> byZone = {};
    for (final e in events) {
      final z = (e.zone == null || e.zone!.trim().isEmpty)
          ? 'Senza zona'
          : e.zone!.trim();
      byZone.putIfAbsent(z, () => []).add(e);
    }

    final LatLng cityCenter =
        _pickCenter(byZone) ?? const LatLng(41.9028, 12.4964);

    final markers = <Marker>[];
    byZone.forEach((zone, list) {
      final pos = _coordForZone(zone, cityCenter);
      final style = _styleForZone(list);

      final openCount = list.where((e) => e.listType == ListType.open).length;
      final privateCount =
          list.where((e) => e.listType == ListType.closed).length;

      final tooltipText =
          '$zone • ${list.length} eventi\nPubblici: $openCount • Privati: $privateCount\n${style.label}';

      markers.add(
        Marker(
          point: pos,
          width: 58,
          height: 58,
          child: GestureDetector(
            onTap: () => _openZoneSheet(context, zone, list),
            child: _ZoneMarker(
              count: list.length,
              tooltip: tooltipText,
              color: style.color,
              icon: style.icon,
            ),
          ),
        ),
      );
    });

    // Fit quando cambia lista marker
    _fitToPointsIfNeeded(markers.map((m) => m.point).toList());

    return Scaffold(
      appBar: AppBar(title: const Text('Mappa eventi')),

      // Renderizza solo quando ha size valida (extra sicurezza web)
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          if (w <= 0 || h <= 0) {
            return const Center(child: CircularProgressIndicator());
          }

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: cityCenter,
              initialZoom: 12,
              onMapReady: () {
                _mapReady = true;
                _lastFitSignature = null; // forza fit al primo render
                final pts = markers.map((m) => m.point).toList();
                _fitToPointsIfNeeded(pts);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'my_first_app',
                keepBuffer: 2,
              ),
              MarkerLayer(markers: markers),
            ],
          );
        },
      ),
    );
  }
}

class _MarkerStyle {
  final Color color;
  final IconData icon;
  final String label;

  const _MarkerStyle({
    required this.color,
    required this.icon,
    required this.label,
  });
}

class _ZoneMarker extends StatelessWidget {
  final int count;
  final String tooltip;
  final Color color;
  final IconData icon;

  const _ZoneMarker({
    required this.count,
    required this.tooltip,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.92),
              border: Border.all(color: Colors.white, width: 3),
            ),
            alignment: Alignment.center,
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Icon(icon, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
