import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapGesturesScreen extends StatefulWidget {
  const MapGesturesScreen({super.key});

  @override
  State<MapGesturesScreen> createState() =>
      _MapGesturesScreenState();
}

class _MapGesturesScreenState
    extends State<MapGesturesScreen> {
  GoogleMapController? _map;

  bool _scroll = true;
  bool _zoom = true;
  bool _rotate = true;
  bool _tilt = true;

  LatLng _target = const LatLng(23.7625, 90.3783);

  double _zoomLevel = 12.0;
  double _tiltLevel = 0.0;
  double _bearing = 0.0;

  // Hatirjheel, Dhaka
  static const LatLng _hatirjheel =
  LatLng(23.7745, 90.4203);

  void _onCameraMove(CameraPosition position) {
    if (!mounted) return;

    setState(() {
      _target = position.target;
      _zoomLevel = position.zoom;
      _tiltLevel = position.tilt;
      _bearing = position.bearing;
    });
  }

  Future<void> _goToHatirjheel() async {
    await _map?.animateCamera(
      CameraUpdate.newCameraPosition(
        const CameraPosition(
          target: _hatirjheel,
          zoom: 16,
          tilt: 50,
          bearing: 45,
        ),
      ),
    );
  }

  Future<void> _resetNorth() async {
    await _map?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _target,
          zoom: _zoomLevel,
          tilt: 0,
          bearing: 0,
        ),
      ),
    );
  }

  Future<void> _zoomIn() async {
    await _map?.animateCamera(
      CameraUpdate.zoomIn(),
    );
  }

  Future<void> _zoomOut() async {
    await _map?.animateCamera(
      CameraUpdate.zoomOut(),
    );
  }

  Widget _gestureChip(
      String label,
      bool selected,
      ValueChanged<bool> onChanged,
      ) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (value) {
        setState(() {
          onChanged(value);
        });
      },
    );
  }

  Widget _actionButton(
      String label,
      VoidCallback onPressed,
      ) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        visualDensity: VisualDensity.compact,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  void dispose() {
    _map?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Gestures'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 6),

          const Text(
            'Map Gestures Screen',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Lat: ${_target.latitude.toStringAsFixed(4)}',
          ),
          Text(
            'Lng: ${_target.longitude.toStringAsFixed(4)}',
          ),
          Text(
            'Zoom: ${_zoomLevel.toStringAsFixed(2)}',
          ),
          Text(
            'Tilt: ${_tiltLevel.toStringAsFixed(2)}',
          ),
          Text(
            'Bearing: ${_bearing.toStringAsFixed(2)}',
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Drag, scroll, twist and tilt with two fingers',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ),

          // Google Map
          Expanded(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(23.7625, 90.3783),
                zoom: 12,
              ),
              onMapCreated: (controller) {
                _map = controller;
              },
              onCameraMove: _onCameraMove,
              scrollGesturesEnabled: _scroll,
              zoomGesturesEnabled: _zoom,
              rotateGesturesEnabled: _rotate,
              tiltGesturesEnabled: _tilt,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
          ),

          // Gesture controls
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 0,
              children: [
                _gestureChip(
                  'Scroll',
                  _scroll,
                      (v) => _scroll = v,
                ),
                _gestureChip(
                  'Zoom',
                  _zoom,
                      (v) => _zoom = v,
                ),
                _gestureChip(
                  'Rotate',
                  _rotate,
                      (v) => _rotate = v,
                ),
                _gestureChip(
                  'Tilt',
                  _tilt,
                      (v) => _tilt = v,
                ),
              ],
            ),
          ),

          // Map action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 2,
              children: [
                _actionButton(
                  'Go To Hatirjheel',
                  _goToHatirjheel,
                ),
                _actionButton(
                  'Reset North',
                  _resetNorth,
                ),
                _actionButton(
                  'Zoom In',
                  _zoomIn,
                ),
                _actionButton(
                  'Zoom Out',
                  _zoomOut,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}