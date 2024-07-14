import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:green_taxi/controller/auth_controller.dart';
import 'package:green_taxi/utils/app_colors.dart';
import 'package:green_taxi/widgets/green_intro_widget.dart';
import 'package:image_picker/image_picker.dart';

class MyProfile extends StatefulWidget {
  const MyProfile({Key? key}) : super(key: key);

  @override
  State<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController homeController = TextEditingController();
  final TextEditingController businessController = TextEditingController();
  final TextEditingController shopController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final AuthController authController = Get.find<AuthController>();

  final ImagePicker _picker = ImagePicker();
  File? selectedImage;

  late LatLng homeAddress;
  late LatLng businessAddress;
  late LatLng shoppingAddress;

  @override
  void initState() {
    super.initState();
    nameController.text = authController.myUser.value.name ?? "";
    homeController.text = authController.myUser.value.hAddress ?? "";
    shopController.text = authController.myUser.value.mallAddress ?? "";
    businessController.text = authController.myUser.value.bAddress ?? "";

    homeAddress = authController.myUser.value.homeAddress!;
    businessAddress = authController.myUser.value.businessAddress!;
    shoppingAddress = authController.myUser.value.shoppingAddress!;
  }

  Future<void> getImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      selectedImage = File(image.path);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildProfileHeader(),
            const SizedBox(height: 20),
            buildProfileForm(),
          ],
        ),
      ),
    );
  }

  Widget buildProfileHeader() {
    return Container(
      height: Get.height * 0.4,
      child: Stack(
        children: [
          greenIntroWidgetWithoutLogos(title: 'My Profile'),
          Align(
            alignment: Alignment.bottomCenter,
            child: InkWell(
              onTap: () => getImage(ImageSource.camera),
              child: buildProfileImage(),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProfileImage() {
    return Container(
      width: 120,
      height: 120,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xffD6D6D6),
        image: selectedImage != null
            ? DecorationImage(
          image: FileImage(selectedImage!),
          fit: BoxFit.fill,
        )
            : authController.myUser.value.image != null
            ? DecorationImage(
          image: NetworkImage(authController.myUser.value.image!),
          fit: BoxFit.fill,
        )
            : null,
      ),
      child: selectedImage == null && authController.myUser.value.image == null
          ? const Center(
        child: Icon(
          Icons.camera_alt_outlined,
          size: 40,
          color: Colors.white,
        ),
      )
          : null,
    );
  }

  Widget buildProfileForm() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 23),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            buildTextField('Name', Icons.person_outlined, nameController, (input) {
              if (input!.isEmpty) return 'Name is required!';
              if (input.length < 5) return 'Please enter a valid name!';
              return null;
            }),
            const SizedBox(height: 10),
            buildTextField('Home Address', Icons.home_outlined, homeController, (input) {
              if (input!.isEmpty) return 'Home Address is required!';
              return null;
            }, onTap: () async {
              Prediction? p = await authController.showGoogleAutoComplete(context);
              homeAddress = await authController.buildLatLngFromAddress(p!.description!);
              homeController.text = p.description!;
            }, readOnly: true),
            const SizedBox(height: 10),
            buildTextField('Business Address', Icons.card_travel, businessController, (input) {
              if (input!.isEmpty) return 'Business Address is required!';
              return null;
            }, onTap: () async {
              Prediction? p = await authController.showGoogleAutoComplete(context);
              businessAddress = await authController.buildLatLngFromAddress(p!.description!);
              businessController.text = p.description!;
            }, readOnly: true),
            const SizedBox(height: 10),
            buildTextField('Shopping Center', Icons.shopping_cart_outlined, shopController, (input) {
              if (input!.isEmpty) return 'Shopping Center is required!';
              return null;
            }, onTap: () async {
              Prediction? p = await authController.showGoogleAutoComplete(context);
              shoppingAddress = await authController.buildLatLngFromAddress(p!.description!);
              shopController.text = p.description!;
            }, readOnly: true),
            const SizedBox(height: 30),
            Obx(() => authController.isProfileUploading.value
                ? const Center(child: CircularProgressIndicator())
                : buildUpdateButton()),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(
      String title,
      IconData iconData,
      TextEditingController controller,
      Function validator, {
        Function? onTap,
        bool readOnly = false,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xffA7A7A7),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 1,
              ),
            ],
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextFormField(
            readOnly: readOnly,
            onTap: onTap != null ? () => onTap() : null,
            validator: (input) => validator(input),
            controller: controller,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xffA7A7A7),
            ),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Icon(
                  iconData,
                  color: AppColors.greenColor,
                ),
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildUpdateButton() {
    return MaterialButton(
      minWidth: Get.width,
      height: 50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      color: AppColors.greenColor,
      onPressed: () {
        if (!formKey.currentState!.validate()) return;

        authController.isProfileUploading(true);
        authController.storeUserInfo(
          selectedImage,
          nameController.text,
          homeController.text,
          businessController.text,
          shopController.text,
          url: authController.myUser.value.image ?? "",
          homeLatLng: homeAddress,
          shoppingLatLng: shoppingAddress,
          businessLatLng: businessAddress,
        );
      },
      child: Text(
        'Update',
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
