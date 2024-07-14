import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:geocoding/geocoding.dart' as geoCoding;
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:green_taxi/models/user_model/user_model.dart';
import 'package:green_taxi/views/driver/car_registration/car_registration_template.dart';
import 'package:green_taxi/views/home.dart';
import 'package:green_taxi/views/profile_settings.dart';
import 'package:path/path.dart' as Path;

import '../utils/app_constants.dart';
import '../views/driver/profile_setup.dart';

class AuthController extends GetxController {
  String userUid = '';
  var verId = '';
  int? resendTokenId;
  bool phoneAuthCheck = false;
  dynamic credentials;

  var isProfileUploading = false.obs;

  bool isLoginAsDriver = false;

  RxList userCards = [].obs;
  var isDecided = false;
  var myUser = UserModel().obs;

  @override
  void onInit() {
    super.onInit();
    if (FirebaseAuth.instance.currentUser != null) {
      getUserCards();
      getUserInfo();
    }
  }

  Future<bool> storeUserCard(String number, String expiry, String cvv, String name) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('cards')
          .add({'name': name, 'number': number, 'cvv': cvv, 'expiry': expiry});
      return true;
    } catch (e) {
      log('Error storing user card: $e');
      return false;
    }
  }

  void getUserCards() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('cards')
        .snapshots()
        .listen((event) {
      userCards.value = event.docs;
    });
  }

  Future<void> phoneAuth(String phone) async {
    try {
      credentials = null;
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          log('Verification completed');
          credentials = credential;
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        forceResendingToken: resendTokenId,
        verificationFailed: (FirebaseAuthException e) {
          log('Verification failed: ${e.message}');
          if (e.code == 'invalid-phone-number') {
            debugPrint('The provided phone number is not valid.');
          }
        },
        codeSent: (String verificationId, int? resendToken) async {
          log('Code sent');
          verId = verificationId;
          resendTokenId = resendToken;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          verId = verificationId;
        },
      );
    } catch (e) {
      log("Error occurred during phone authentication: $e");
    }
  }

  Future<void> verifyOtp(String otpNumber) async {
    try {
      log("Verifying OTP");
      PhoneAuthCredential credential =
      PhoneAuthProvider.credential(verificationId: verId, smsCode: otpNumber);

      await FirebaseAuth.instance.signInWithCredential(credential).then((value) {
        decideRoute();
      }).catchError((e) {
        log("Error while signing in with OTP: $e");
      });
    } catch (e) {
      log("Error occurred during OTP verification: $e");
    }
  }

  void decideRoute() {
    if (isDecided) {
      return;
    }
    isDecided = true;
    log("Deciding route");

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).get().then((value) {
        if (isLoginAsDriver) {
          if (value.exists) {
            Get.offAll(() => DriverProfileSetup());
          } else {
            Get.offAll(() => CarRegistrationTemplate());
          }
        } else {
          if (value.exists) {
            Get.offAll(() => HomeScreen());
          } else {
            Get.offAll(() => ProfileSettingScreen());
          }
        }
      }).catchError((e) {
        log("Error while deciding route: $e");
      });
    }
  }

  Future<String> uploadImage(File image) async {
    try {
      String fileName = Path.basename(image.path);
      var reference = FirebaseStorage.instance.ref().child('users/$fileName');
      UploadTask uploadTask = reference.putFile(image);
      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
      String imageUrl = await taskSnapshot.ref.getDownloadURL();
      log("Image uploaded, URL: $imageUrl");
      return imageUrl;
    } catch (e) {
      log("Error uploading image: $e");
      return '';
    }
  }

  Future<void> storeUserInfo(File? selectedImage, String name, String home, String business, String shop,
      {String url = '', LatLng? homeLatLng, LatLng? businessLatLng, LatLng? shoppingLatLng}) async {
    try {
      isProfileUploading(true);
      String imageUrl = url;
      if (selectedImage != null) {
        imageUrl = await uploadImage(selectedImage);
      }
      String uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'image': imageUrl,
        'name': name,
        'home_address': home,
        'business_address': business,
        'shopping_address': shop,
        'home_latlng': GeoPoint(homeLatLng!.latitude, homeLatLng.longitude),
        'business_latlng': GeoPoint(businessLatLng!.latitude, businessLatLng.longitude),
        'shopping_latlng': GeoPoint(shoppingLatLng!.latitude, shoppingLatLng.longitude),
      }, SetOptions(merge: true));
      isProfileUploading(false);
      Get.to(() => HomeScreen());
    } catch (e) {
      log("Error storing user info: $e");
      isProfileUploading(false);
    }
  }

  void getUserInfo() {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore.instance.collection('users').doc(uid).snapshots().listen((event) {
      if (event.data() != null) {
        myUser.value = UserModel.fromJson(event.data()!);
      }
    });
  }

  Future<Prediction?> showGoogleAutoComplete(BuildContext context) async {
    try {
      Prediction? prediction = await PlacesAutocomplete.show(
        offset: 0,
        radius: 1000,
        strictbounds: false,
        region: "pk",
        language: "en",
        context: context,
        mode: Mode.overlay,
        apiKey: AppConstants.kGoogleApiKey,
        components: [Component(Component.country, "pk")],
        types: [],
        hint: "Search City",
      );
      return prediction;
    } catch (e) {
      log("Error showing Google AutoComplete: $e");
      return null;
    }
  }

  Future<LatLng> buildLatLngFromAddress(String place) async {
    try {
      List<geoCoding.Location> locations = await geoCoding.locationFromAddress(place);
      return LatLng(locations.first.latitude, locations.first.longitude);
    } catch (e) {
      log("Error building LatLng from address: $e");
      return LatLng(0, 0);
    }
  }

  Future<void> storeDriverProfile(File? selectedImage, String name, String email, {String url = ''}) async {
    try {
      isProfileUploading(true);
      String imageUrl = url;
      if (selectedImage != null) {
        imageUrl = await uploadImage(selectedImage);
      }
      String uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'image': imageUrl,
        'name': name,
        'email': email,
        'isDriver': true
      }, SetOptions(merge: true));
      isProfileUploading(false);
      Get.off(() => CarRegistrationTemplate());
    } catch (e) {
      log("Error storing driver profile: $e");
      isProfileUploading(false);
    }
  }

  Future<bool> uploadCarEntry(Map<String, dynamic> carData) async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set(carData, SetOptions(merge: true));
      return true;
    } catch (e) {
      log("Error uploading car entry: $e");
      return false;
    }
  }

  clearUserData() {}
}
