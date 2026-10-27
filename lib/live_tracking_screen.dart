import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  static const Duration _updateInterval = Duration(seconds: 10);
  static const MarkerId _markerId = MarkerId('current_location');

  final Completer<GoogleMapController> _controller = Completer();
  Timer? _timer;

  LatLng? _currentLatLng;
  final List<LatLng> _routePoints = [];

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  bool _isLoading = true;
  String? _error;
  int _updateCount = 0;
  double _distanceMeters = 0;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Fetch immediately, then every 10 seconds.
  Future<void> _startTracking() async {
    final hasPermission = await _handlePermission();
    if (!hasPermission) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    await _updateLocation();
    _timer = Timer.periodic(_updateInterval, (_) => _updateLocation());
  }

  Future<bool> _handlePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _setError('Location services are disabled. Please turn on GPS.');
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _setError('Location permission denied.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _setError('Permission permanently denied. Enable it from app settings.');
      return false;
    }
    return true;
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() => _error = message);
  }

  Future<void> _updateLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final newLatLng = LatLng(position.latitude, position.longitude);

      if (!mounted) return;
      setState(() {
        final previous = _currentLatLng;
        if (previous != null) {
          _distanceMeters += Geolocator.distanceBetween(
            previous.latitude,
            previous.longitude,
            newLatLng.latitude,
            newLatLng.longitude,
          );
        }

        _currentLatLng = newLatLng;
        _routePoints.add(newLatLng);
        _updateCount++;
        _lastUpdated = DateTime.now();
        _isLoading = false;
        _error = null;

        // Marker with info window (tap to open).
        _markers = {
          Marker(
            markerId: _markerId,
            position: newLatLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
            infoWindow: InfoWindow(
              title: 'My current location',
              snippet:
              'Lat: ${newLatLng.latitude.toStringAsFixed(6)}, '
                  'Lng: ${newLatLng.longitude.toStringAsFixed(6)}',
            ),
          ),
        };

        // Polyline connecting previous -> current (full path so far).
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: List<LatLng>.of(_routePoints),
            color: Colors.blueAccent,
            width: 6,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
          ),
        };
      });

      await _animateTo(newLatLng);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _setError('Could not get location: $e');
    }
  }

  // Smoothly animate camera to a location.
  Future<void> _animateTo(LatLng target) async {
    final controller = await _controller.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: 17)),
    );
  }

  Future<void> _showMarkerInfo() async {
    final controller = await _controller.future;
    await controller.showMarkerInfoWindow(_markerId);
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '--:--:--';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Live Tracking'),
        backgroundColor: scheme.surface.withOpacity(0.85),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      floatingActionButton: _currentLatLng == null
          ? null
          : Padding(
        padding: const EdgeInsets.only(bottom: 170),
        child: FloatingActionButton.small(
          tooltip: 'Recenter',
          onPressed: () {
            _animateTo(_currentLatLng!);
            _showMarkerInfo();
          },
          child: const Icon(Icons.my_location),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(23.8103, 90.4125), // Dhaka, starting view only
              zoom: 10,
            ),
            markers: _markers,
            polylines: _polylines,
            padding: const EdgeInsets.only(bottom: 170, top: 90),
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              if (!_controller.isCompleted) {
                _controller.complete(controller);
              }
            },
          ),

          // Top status chip
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _StatusChip(
                  isError: _error != null,
                  label: _error ?? 'Live • updates every 10 seconds',
                ),
              ),
            ),
          ),

          // First-fix loading overlay
          if (_isLoading)
            Container(
              color: scheme.surface.withOpacity(0.6),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Finding your location...'),
                  ],
                ),
              ),
            ),

          // Bottom info card
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on, color: scheme.primary),
                            const SizedBox(width: 8),
                            const Text(
                              'My current location',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentLatLng == null
                              ? 'Waiting for GPS...'
                              : 'Lat: ${_currentLatLng!.latitude.toStringAsFixed(6)}\n'
                              'Lng: ${_currentLatLng!.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _Stat(
                              icon: Icons.update,
                              label: 'Last update',
                              value: _formatTime(_lastUpdated),
                            ),
                            _Stat(
                              icon: Icons.pin_drop_outlined,
                              label: 'Points',
                              value: '$_updateCount',
                            ),
                            _Stat(
                              icon: Icons.route,
                              label: 'Distance',
                              value: _formatDistance(_distanceMeters),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.isError});

  final String label;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? Colors.red : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black26)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}