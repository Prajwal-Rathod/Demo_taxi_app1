import 'package:google_maps_flutter/google_maps_flutter.dart';

class UserModel {
  String? bAddress;
  String? hAddress;
  String? mallAddress;
  String? name;
  String? image;

  LatLng? homeAddress;
  LatLng? businessAddress;
  LatLng? shoppingAddress;

  UserModel({
    this.name,
    this.mallAddress,
    this.hAddress,
    this.bAddress,
    this.image,
    this.homeAddress,
    this.businessAddress,
    this.shoppingAddress,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    try {
      return UserModel(
        bAddress: json['business_address'],
        hAddress: json['home_address'],
        mallAddress: json['shopping_address'],
        name: json['name'],
        image: json['image'],
        homeAddress: json['home_latlng'] != null
            ? LatLng(json['home_latlng']['latitude'], json['home_latlng']['longitude'])
            : null,
        businessAddress: json['business_latlng'] != null
            ? LatLng(json['business_latlng']['latitude'], json['business_latlng']['longitude'])
            : null,
        shoppingAddress: json['shopping_latlng'] != null
            ? LatLng(json['shopping_latlng']['latitude'], json['shopping_latlng']['longitude'])
            : null,
      );
    } catch (e) {
      print('Error parsing JSON to UserModel: $e');
      return UserModel();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'business_address': bAddress,
      'home_address': hAddress,
      'shopping_address': mallAddress,
      'name': name,
      'image': image,
      'home_latlng': homeAddress != null ? {'latitude': homeAddress!.latitude, 'longitude': homeAddress!.longitude} : null,
      'business_latlng': businessAddress != null ? {'latitude': businessAddress!.latitude, 'longitude': businessAddress!.longitude} : null,
      'shopping_latlng': shoppingAddress != null ? {'latitude': shoppingAddress!.latitude, 'longitude': shoppingAddress!.longitude} : null,
    };
  }
}
