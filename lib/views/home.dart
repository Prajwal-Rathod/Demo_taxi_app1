import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_webservice/places.dart';
import 'package:geocoding/geocoding.dart' as geoCoding;
import 'dart:ui' as ui;

import '../controller/auth_controller.dart';
import '../controller/polyline_handler.dart';
import '../utils/app_colors.dart';
import '../views/my_profile.dart';
import '../views/payment.dart';
import '../widgets/text_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _mapStyle;
  AuthController authController = Get.find<AuthController>();
  late LatLng destination;
  late LatLng source;
  final Set<Polyline> _polyline = {};
  Set<Marker> markers = Set<Marker>();
  late Uint8List markIcons;

  List<String> list = <String>[
    '**** **** **** 8789',
    '**** **** **** 8921',
    '**** **** **** 1233',
    '**** **** **** 4352'
  ];

  @override
  void initState() {
    super.initState();
    authController.getUserInfo();
    rootBundle.loadString('assets/map_style.txt').then((string) {
      _mapStyle = string;
    });
    loadCustomMarker();
  }

  String dropdownValue = '**** **** **** 8789';
  final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  GoogleMapController? myMapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: buildDrawer(),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: GoogleMap(
              markers: markers,
              polylines: _polyline,
              zoomControlsEnabled: false,
              onMapCreated: (GoogleMapController controller) {
                myMapController = controller;
                myMapController!.setMapStyle(_mapStyle);
              },
              initialCameraPosition: _kGooglePlex,
            ),
          ),
          buildProfileTile(),
          buildTextField(),
          showSourceField ? buildTextFieldForSource() : Container(),
          buildCurrentLocationIcon(),
          buildNotificationIcon(),
          buildBottomSheet(),
        ],
      ),
    );
  }

  Widget buildProfileTile() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Obx(() => authController.myUser.value.name == null
          ? Center(
        child: CircularProgressIndicator(),
      )
          : Container(
        width: Get.width,
        height: Get.width * 0.5,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(color: Colors.white70),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: authController.myUser.value.image == null
                      ? DecorationImage(
                      image: AssetImage('assets/person.png'),
                      fit: BoxFit.fill)
                      : DecorationImage(
                      image: NetworkImage(
                          authController.myUser.value.image!),
                      fit: BoxFit.fill)),
            ),
            const SizedBox(
              width: 15,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                  text: TextSpan(children: [
                    TextSpan(
                        text: 'Good Morning, ',
                        style: TextStyle(
                            color: Colors.black, fontSize: 14)),
                    TextSpan(
                        text: authController.myUser.value.name,
                        style: TextStyle(
                            color: Colors.green,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ]),
                ),
                Text(
                  "Where are you going?",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                )
              ],
            )
          ],
        ),
      )),
    );
  }

  TextEditingController destinationController = TextEditingController();
  TextEditingController sourceController = TextEditingController();
  bool showSourceField = false;

  Widget buildTextField() {
    return Positioned(
      top: 170,
      left: 20,
      right: 20,
      child: Container(
        width: Get.width,
        height: 50,
        padding: EdgeInsets.only(left: 15),
        decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 4,
                  blurRadius: 10)
            ],
            borderRadius: BorderRadius.circular(8)),
        child: TextFormField(
          controller: destinationController,
          readOnly: true,
          onTap: () async {
            Prediction? p = await authController.showGoogleAutoComplete(context);

            if (p == null) return;

            String selectedPlace = p.description!;

            destinationController.text = selectedPlace;

            List<geoCoding.Location> locations =
            await geoCoding.locationFromAddress(selectedPlace);

            destination = LatLng(locations.first.latitude, locations.first.longitude);

            markers.add(Marker(
              markerId: MarkerId(selectedPlace),
              infoWindow: InfoWindow(
                title: 'Destination: $selectedPlace',
              ),
              position: destination,
              icon: BitmapDescriptor.fromBytes(markIcons),
            ));

            myMapController!.animateCamera(CameraUpdate.newCameraPosition(
                CameraPosition(target: destination, zoom: 14)));

            setState(() {
              showSourceField = true;
            });
          },
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: 'Search for a destination',
            hintStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Icon(
                Icons.search,
              ),
            ),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget buildTextFieldForSource() {
    return Positioned(
      top: 230,
      left: 20,
      right: 20,
      child: Container(
        width: Get.width,
        height: 50,
        padding: EdgeInsets.only(left: 15),
        decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 4,
                  blurRadius: 10)
            ],
            borderRadius: BorderRadius.circular(8)),
        child: TextFormField(
          controller: sourceController,
          readOnly: true,
          onTap: () async {
            buildSourceSheet();
          },
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: 'From:',
            hintStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Icon(
                Icons.search,
              ),
            ),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget buildCurrentLocationIcon() {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 30, right: 8),
        child: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.green,
          child: Icon(
            Icons.my_location,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget buildNotificationIcon() {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 30, left: 8),
        child: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.white,
          child: Icon(
            Icons.notifications,
            color: Color(0xffC3CDD6),
          ),
        ),
      ),
    );
  }

  Widget buildBottomSheet() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: Get.width * 0.8,
        height: 25,
        decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 4,
                  blurRadius: 10)
            ],
            borderRadius: BorderRadius.only(
                topRight: Radius.circular(12), topLeft: Radius.circular(12))),
        child: Center(
          child: Container(
            width: 60,
            height: 3,
            decoration: BoxDecoration(
                color: Colors.black, borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }

  void buildSourceSheet() {
    Get.bottomSheet(
        Container(
          width: Get.width,
          height: Get.height * 0.8,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 10,
              ),
              Center(
                child: Container(
                  width: 60,
                  height: 3,
                  decoration: BoxDecoration(
                      color: Colors.black, borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              TextWidget(
                  text: 'Choose Starting Point',
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
              const SizedBox(
                height: 30,
              ),
              buildListTile(
                  'Your Location', Icons.my_location, Colors.green, false),
              const SizedBox(
                height: 15,
              ),
              buildListTile(
                  'Choose location on map', Icons.location_on, Colors.red, false),
              const SizedBox(
                height: 15,
              ),
              buildListTile('Choose recent locations', Icons.schedule,
                  Colors.blueGrey, true),
            ],
          ),
        ),
        isScrollControlled: true);
  }

  Widget buildListTile(
      String title, IconData icon, Color iconColor, bool showRecentLocation) {
    return Column(
      children: [
        ListTile(
          onTap: () async {
            if (title == 'Your Location') {
              sourceController.text = title;
              Get.back();
            } else if (title == 'Choose location on map') {
              Prediction? p = await authController.showGoogleAutoComplete(context);

              if (p == null) return;

              String selectedPlace = p.description!;

              sourceController.text = selectedPlace;

              List<geoCoding.Location> locations =
              await geoCoding.locationFromAddress(selectedPlace);

              source = LatLng(locations.first.latitude, locations.first.longitude);

              markers.add(Marker(
                markerId: MarkerId(selectedPlace),
                infoWindow: InfoWindow(
                  title: 'Source: $selectedPlace',
                ),
                position: source,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen),
              ));

              myMapController!.animateCamera(CameraUpdate.newCameraPosition(
                  CameraPosition(target: source, zoom: 14)));

              authController.getDirections(destination, source).then((directions) {
                _polyline.add(Polyline(
                    polylineId: PolylineId('overview_polyline'),
                    width: 4,
                    color: AppColors.primaryColor,
                    points: directions));
                setState(() {});
              });
              Get.back();
            } else if (title == 'Choose recent locations') {
              // Handle recent locations
            }
          },
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: iconColor.withOpacity(0.1),
            child: Icon(
              icon,
              color: iconColor,
            ),
          ),
          title: TextWidget(text: title, fontSize: 14),
        ),
        showRecentLocation ? buildRecentLocations() : Container(),
      ],
    );
  }

  Widget buildRecentLocations() {
    return Column(
      children: [
        ListTile(
          onTap: () {
            sourceController.text = 'Mombasa';
            source = LatLng(-4.0435, 39.6682);
            addMarkerAndPolyline('Mombasa', source, true);
          },
          contentPadding: EdgeInsets.zero,
          leading: const Icon(
            Icons.restore,
            color: Colors.black,
          ),
          title: TextWidget(text: 'Mombasa', fontSize: 14),
        ),
        ListTile(
          onTap: () {
            sourceController.text = 'Nairobi';
            source = LatLng(-1.286389, 36.817223);
            addMarkerAndPolyline('Nairobi', source, true);
          },
          contentPadding: EdgeInsets.zero,
          leading: const Icon(
            Icons.restore,
            color: Colors.black,
          ),
          title: TextWidget(text: 'Nairobi', fontSize: 14),
        )
      ],
    );
  }

  void addMarkerAndPolyline(String title, LatLng position, bool isSource) {
    markers.add(Marker(
      markerId: MarkerId(title),
      infoWindow: InfoWindow(
        title: isSource ? 'Source: $title' : 'Destination: $title',
      ),
      position: position,
      icon: isSource
          ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
          : BitmapDescriptor.fromBytes(markIcons),
    ));
    myMapController!.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: position, zoom: 14)));
    authController.getDirections(destination, source).then((directions) {
      _polyline.add(Polyline(
          polylineId: PolylineId('overview_polyline'),
          width: 4,
          color: AppColors.primaryColor,
          points: directions));
      setState(() {});
    });
    Get.back();
  }

  Widget buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          buildDrawerHeader(),
          buildDrawerItem(
              'My Profile', Icons.person_outline, () => Get.to(() => MyProfile())),
          buildDrawerItem(
              'Payment Methods', Icons.credit_card_outlined, () => Get.to(() => Payment())),
          buildDrawerItem('Invite Friends', Icons.people_alt_outlined, () {}),
          buildDrawerItem('Help & Support', Icons.help_outline, () {}),
          buildDrawerItem('Settings', Icons.settings_outlined, () {}),
          buildDrawerItem(
              'Logout',
              Icons.logout_outlined,
                  () => FirebaseAuth.instance.signOut().then((value) =>
                  authController.clearUserData().then((value) =>
                      Get.offAllNamed('/login')))),
        ],
      ),
    );
  }

  Widget buildDrawerHeader() {
    return DrawerHeader(
      decoration: BoxDecoration(color: AppColors.primaryColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            backgroundImage: AssetImage('assets/person.png'),
          ),
          const SizedBox(
            height: 10,
          ),
          // TextWidget(
          //     text: authController.myUser.value.name ?? '',
          //     fontSize: 18,
          //     fontWeight: FontWeight.bold,
          //     color: Colors.white),
          // TextWidget(
          //     text: authController.myUser.value.email ?? '',
          //     fontSize: 14,
          //     color: Colors.white),
        ],
      ),
    );
  }

  Widget buildDrawerItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      title: TextWidget(text: title, fontSize: 16),
      leading: Icon(icon),
      onTap: onTap,
    );
  }

  Future<void> loadCustomMarker() async {
    markIcons = await getBytesFromAsset('assets/marker.png', 100);
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }
}

class TextWidget {
}
