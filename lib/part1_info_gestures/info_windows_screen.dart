import 'package:flutter/material.dart';
import 'package:google_map_app/part1_info_gestures/places.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class InfoWindowsScreen extends StatefulWidget {
  const InfoWindowsScreen({super.key});

  @override
  State<InfoWindowsScreen> createState() => _InfoWindowsScreenState();
}

class _InfoWindowsScreenState extends State<InfoWindowsScreen> {
  String _status = 'Tap a pin, then tap the white bubble';

  // String? _snippetFor(Landmark landmark) {}

  // Set<Marker> markers() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Part 1 - Info windows'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_status),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: Places.openingCamera,
              zoomControlsEnabled: false,
              markers: {
                Marker(
                  markerId: const MarkerId('test marker'),
                  position: Places.all.first.position,
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}