import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../places.dart';

class CustomMarkerScreen extends StatefulWidget {
  const CustomMarkerScreen({super.key});

  @override
  State<CustomMarkerScreen> createState() => _CustomMarkerScreenState();
}

class _CustomMarkerScreenState extends State<CustomMarkerScreen> {
  BitmapDescriptor? _campusPin;

  GoogleMapController? _mapController;

  final Set<Marker> _markers = {};

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(23.6850, 90.3563),
    zoom: 7,
  );

  @override
  void initState() {
    super.initState();
    _createMarkers();
    _loadCampusPin();
  }

  // Load custom campus marker image
  Future<void> _loadCampusPin() async {
    try {
      final icon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(64, 48)),
        'assets/campus_pin.png', // use PNG
      );

      if (!mounted) return;

      setState(() {
        _campusPin = icon; // FIX: was `campusPin` (undefined)
        _createMarkers();
      });
    } catch (e) {
      debugPrint('Error loading campus pin: $e');
    }
  }

  // Create all map markers (no setState here; callers handle it)
  void _createMarkers() {
    _markers
      ..clear()
      ..addAll([
        _huePin(Places.parliament, BitmapDescriptor.hueRed),
        _huePin(Places.shahidMinar, BitmapDescriptor.hueAzure),
        _huePin(Places.lalbaghFort, BitmapDescriptor.hueGreen),
        _huePin(Places.ahsanManzil, BitmapDescriptor.hueYellow),
        _huePin(Places.hatirjheel, BitmapDescriptor.hueOrange),

        // University custom marker
        Marker(
          markerId: MarkerId(Places.university.id.toString()),
          position: Places.university.position,
          icon: _campusPin ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: Places.university.name,
            snippet: _campusPin == null
                ? 'Loading custom marker...'
                : 'Custom marker loaded successfully!',
          ),
        ),
      ]);
  }

  // Create a marker with a specific color
  Marker _huePin(Landmark place, double hue) {
    return Marker(
      markerId: MarkerId(place.id.toString()),
      position: place.position,
      infoWindow: InfoWindow(title: place.name, snippet: place.fact),
      icon: BitmapDescriptor.defaultMarkerWithHue(hue),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Marker'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Custom Marker Screen'),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: _initialPosition,
              markers: _markers,
              onMapCreated: (controller) => _mapController = controller,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              mapType: MapType.normal,
            ),
          ),
        ],
      ),
    );
  }
}