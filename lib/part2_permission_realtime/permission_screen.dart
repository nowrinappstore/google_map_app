import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../places.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with WidgetsBindingObserver {
  LocationPermission? _permission;
  bool _isServiceOn = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-check status when the user comes back from the settings screen
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  // Check whether the blue location dot can be shown
  bool get _canShowBlueDot {
    return _permission == LocationPermission.always ||
        _permission == LocationPermission.whileInUse;
  }

  // Refresh location service and permission status
  Future<void> _refresh() async {
    try {
      final bool serviceIsOn = await Geolocator.isLocationServiceEnabled();
      final LocationPermission permission = await Geolocator.checkPermission();

      if (!mounted) return;

      setState(() {
        _isServiceOn = serviceIsOn;
        _permission = permission;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking location status: $e')),
      );
    }
  }

  // Request location permission
  Future<void> _ask() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check whether location service is enabled
      final bool serviceIsOn = await Geolocator.isLocationServiceEnabled();

      if (!serviceIsOn) {
        if (!mounted) return;

        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Location Service Disabled'),
            content: const Text(
              'Please enable location service on your device.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await Geolocator.openLocationSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
        return; // finally block refreshes the status
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (!mounted) return;

      setState(() {
        _permission = permission;
      });

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permission permanently denied. Please enable it in app settings.',
            ),
          ),
        );

        await Geolocator.openAppSettings();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permission error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        await _refresh();
      }
    }
  }

  // Explain the current permission status
  String _explain() {
    final LocationPermission? permission = _permission;

    if (permission == null) {
      return 'Checking location permission...';
    }

    switch (permission) {
      case LocationPermission.denied:
        return 'Location permission is denied.';
      case LocationPermission.deniedForever:
        return 'Location permission is permanently denied.';
      case LocationPermission.always:
        return 'Location permission is granted always.';
      case LocationPermission.whileInUse:
        return 'Location permission is granted while in use.';
      case LocationPermission.unableToDetermine:
        return 'Unable to determine location permission.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Location Permission')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              _explain(),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: Places.openingCamera,
              myLocationEnabled: _canShowBlueDot,
              myLocationButtonEnabled: _canShowBlueDot,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _ask,
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Request permission'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _refresh,
                  child: const Text('Refresh'),
                ),
                const SizedBox(height: 10),
                Text('Location service is ${_isServiceOn ? 'ON' : 'OFF'}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
