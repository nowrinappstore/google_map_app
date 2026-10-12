import 'package:google_maps_flutter/google_maps_flutter.dart';

class Landmark {
  const Landmark({
    required this.id,
    required this.name,
    required this.position,
    required this.fact,
  });

  final String id;
  final String name;
  final LatLng position;
  final String fact;
}

class Places {
  static const Landmark parliament = Landmark(
    id: 'parliament',
    name: 'National Parliament',
    position: LatLng(23.7625, 90.3783),
    fact: 'Jatiya Sangsad Bhaban',
  );
  static const Landmark shahidMinar = Landmark(
    id: 'shahid_minar',
    name: 'Shahid Minar',
    position: LatLng(23.7314, 90.3961),
    fact: 'Commemorates the Language Movement of 1952',
  );
  static const Landmark hatirjheel = Landmark(
    id: 'hatirjheel',
    name: 'Hatirjheel',
    position: LatLng(23.7650, 90.4000),
    fact: 'Lakeside recreation and transport project in central Dhaka',
  );
  static const Landmark satGombuj = Landmark(
    id: 'sat_gombuj',
    name: 'Sat Gombuj Mosque',
    position: LatLng(23.7554, 90.3598),
    fact: 'Historic 17th century mosque with seven domes',
  );
  static const Landmark lalbaghFort = Landmark(
    id: 'lalbagh_fort',
    name: 'Lalbagh Fort',
    position: LatLng(23.7188, 90.3880),
    fact: 'Mughal fort, started in 1678',
  );
  static const Landmark ahsanManzil = Landmark(
    id: 'ahsan_manzil',
    name: 'Ahsan Manzil',
    position: LatLng(23.7086, 90.4068),
    fact: 'The Pink Palace',
  );
  static const Landmark university = Landmark(
    id: 'du',
    name: 'University of Dhaka',
    position: LatLng(23.7340, 90.3928),
    fact: 'University of Dhaka campus',
  );

  static const List<Landmark> all = [
    parliament,
    shahidMinar,
    lalbaghFort,
    ahsanManzil,
    hatirjheel,
    satGombuj,
    university,
  ];

  // First camera frame. Later moves go through GoogleMapController.
  static const CameraPosition openingCamera = CameraPosition(
    target: LatLng(23.740, 90.400),
    zoom: 12,
  );
}