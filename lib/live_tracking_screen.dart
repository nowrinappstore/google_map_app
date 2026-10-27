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
    if (!hasPermission) return;

    await _updateLocation();
    _timer = Timer.periodic(_updateInterval, (_) => _updateLocation());
  }

  Future<bool> _handlePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showMessage('Location services are disabled. Please enable GPS.');
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showMessage('Location permission denied.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showMessage(
        'Location permission is permanently denied. Enable it from app settings.',
      );
      return false;
    }
    return true;
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
        _currentLatLng = newLatLng;
        _routePoints.add(newLatLng);

        // Marker with info window (tap to open).
        _markers = {
          Marker(
            markerId: _markerId,
            position: newLatLng,
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
            color: Colors.blue,
            width: 5,
          ),
        };
      });

      // Smoothly animate camera to the latest location.
      final controller = await _controller.future;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: newLatLng, zoom: 16),
        ),
      );
    } catch (e) {
      _showMessage('Could not get location: $e');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Real-Time Location Tracker')),
      body: _currentLatLng == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentLatLng!,
          zoom: 16,
        ),
        markers: _markers,
        polylines: _polylines,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
        onMapCreated: (GoogleMapController controller) {
          if (!_controller.isCompleted) {
            _controller.complete(controller);
          }
        },
      ),
    );
  }
}