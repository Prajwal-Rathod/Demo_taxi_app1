import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:green_taxi/utils/app_colors.dart';
import 'package:green_taxi/utils/app_constants.dart';
import 'package:http/http.dart' as http;

class PolylineProvider with ChangeNotifier {
  List<LatLng> polyList = [];
  bool internet = true;
  Set<Polyline> polyline = {};

  Future<List<LatLng>> getPolylines(LatLng pickUp, LatLng drop) async {
    polyList.clear();

    String pickLat = pickUp.latitude.toString();
    String pickLng = pickUp.longitude.toString();
    String dropLat = drop.latitude.toString();
    String dropLng = drop.longitude.toString();

    try {
      var response = await http.get(Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json?origin=$pickLat%2C$pickLng&destination=$dropLat%2C$dropLng&avoid=ferries|indoor&transit_mode=bus&mode=driving&key=${AppConstants.kGoogleApiKey}'));

      if (response.statusCode == 200) {
        var steps =
        jsonDecode(response.body)['routes'][0]['overview_polyline']['points'];
        decodeEncodedPolyline(steps);
      } else {
        debugPrint('Error: ${response.body}');
      }
    } catch (e) {
      if (e is SocketException) {
        internet = false;
        debugPrint('No internet connection: $e');
      } else {
        debugPrint('Error occurred: $e');
      }
    }
    notifyListeners();
    return polyList;
  }

  List<PointLatLng> decodeEncodedPolyline(String encoded) {
    List<PointLatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    polyline.clear();

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      LatLng p = LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble());
      polyList.add(p);
    }

    polyline.add(
      Polyline(
          polylineId: const PolylineId('1'),
          color: AppColors.greenColor,
          visible: true,
          width: 4,
          points: polyList),
    );

    return poly;
  }
}

class PointLatLng {
  const PointLatLng(this.latitude, this.longitude)
      : assert(latitude != null),
        assert(longitude != null);

  final double latitude;
  final double longitude;

  @override
  String toString() {
    return "lat: $latitude / longitude: $longitude";
  }
}
