import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_map_app/places.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GpsScreen extends StatefulWidget {
  const GpsScreen({super.key});

  @override
  State<GpsScreen> createState() => _GpsScreenState();
}

class _GpsScreenState extends State<GpsScreen> {
  GoogleMapController? _map;
  LatLng? _me;

  String _status = 'Press "Find Me" on an emulator. Set a fake location first.';

  bool _busy = false;

  Future<void> _findMe() async {
    setState(() => _busy = true);

    try {
      // 1. Check location service
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        setState(() {
          _status = 'Location service is disabled. Enable it from settings.';
        });
        return;
      }

      // 2. Check permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (!mounted) return;

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _status =
              'Location permission is $permission. Allow it from settings.';
        });
        return;
      }

      // 3. Get current position
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      if (!mounted) return;

      // 4. Convert Position to LatLng
      final LatLng here = LatLng(position.latitude, position.longitude);

      setState(() {
        _me = here;
        _status =
            'Lat: ${here.latitude.toStringAsFixed(4)}\n'
            'Lng: ${here.longitude.toStringAsFixed(4)}';
      });

      // 5. Move camera to current location
      await _map?.animateCamera(CameraUpdate.newLatLngZoom(here, 16));
    } on PermissionDeniedException {
      if (!mounted) return;

      setState(() {
        _status = 'Permission denied. Allow it from settings.';
      });
    } on LocationServiceDisabledException {
      if (!mounted) return;

      setState(() {
        _status = 'Location service is disabled. Enable it from settings.';
      });
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        _status = 'Timeout. Please try again.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _status = 'Unable to get location: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  void dispose() {
    _map?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Set<Marker> makers = {
      if(_me != null)
        Marker(markerId:const MarkerId('Me'),
        position: _me!,
        infoWindow: const InfoWindow(title: 'Me'),
        ),
    };
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          const Center(
            child: Text(
              'GPS Screen',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(_status, textAlign: TextAlign.center),
          ),
          // 6. Display Google Map
          Expanded(
            child: GoogleMap(
              initialCameraPosition: Places.openingCamera,
              myLocationEnabled: _me != null,
              myLocationButtonEnabled: _me != null,
              markers: _me == null
                  ? {}
                  : {
                      Marker(
                        markerId: const MarkerId('my_location'),
                        position: _me!,
                        infoWindow: const InfoWindow(
                          title: 'My Current Location',
                        ),
                      ),
                    },
              onMapCreated: (GoogleMapController controller) {
                _map = controller;

                if (_me != null) {
                  controller.animateCamera(
                    CameraUpdate.newLatLngZoom(_me!, 16),
                  );
                }
              },
            ),
          ),
          Padding(padding: const EdgeInsets.all(8),
          child: ElevatedButton(onPressed: _busy? null:_findMe,
              child: Text(_busy ? 'Finding....':'Find me'),
          ),
          ),
        ],
      ),
    );
  }
}
