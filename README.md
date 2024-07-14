# demo_taxi_app

To set up your Flutter project with Firebase and Google Maps, you need to follow these steps:

Step 1: Adding google-services.json and GoogleService-Info.plist
Add google-services.json to Android:

Place the google-services.json file in the android/app directory of your Flutter project.
Add GoogleService-Info.plist to iOS:

Place the GoogleService-Info.plist file in the ios/Runner directory of your Flutter project.
Step 2: Configuring AndroidManifest.xml
Open the AndroidManifest.xml file located at android/app/src/main/AndroidManifest.xml.
Add your Google Maps API key within the <application> tag:
xml
Copy code
<application>
...
<meta-data
android:name="com.google.android.geo.API_KEY"
android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
...
</application>
Replace YOUR_GOOGLE_MAPS_API_KEY with your actual Google Maps API key.

Step 3: Updating app_constants.dart
Create or update the app_constants.dart file in your lib/utils directory (you may need to create the directory if it doesn't exist). Here's an example with descriptive comments:

dart
Copy code
// lib/utils/app_constants.dart

/// This file contains the constants used throughout the application,
/// such as API keys, URLs, and other configurations.

class AppConstants {
// Google Maps API key
static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

// Other constants related to the project can be added here
// e.g., API endpoints, shared preferences keys, etc.
}
Replace YOUR_GOOGLE_MAPS_API_KEY with your actual API key.

Project Description (in app_constants.dart)
You can add a brief description of your project at the top of the app_constants.dart file to provide context:

dart
Copy code
// lib/utils/app_constants.dart

/// Green Taxi App
///
/// This project is a taxi booking application built using Flutter.
/// It leverages the Google Maps API for location services and
/// Firebase for backend services including authentication,
/// real-time database, and cloud storage.
///
/// Key Features:
/// - User Authentication (Email/Password, Google Sign-In)
/// - Profile Management
/// - Real-time Location Tracking
/// - Booking and Ride Management
/// - Push Notifications
///
/// This file contains the constants used throughout the application,
/// such as API keys, URLs, and other configurations.

class AppConstants {
// Google Maps API key
static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

// Other constants related to the project can be added here
// e.g., API endpoints, shared preferences keys, etc.
}
Step 4: Ensuring Dependencies
Ensure your pubspec.yaml file includes the necessary dependencies:

yaml
Copy code
dependencies:
flutter:
sdk: flutter
firebase_core: latest_version
firebase_auth: latest_version
cloud_firestore: latest_version
firebase_storage: latest_version
google_fonts: latest_version
get: latest_version
google_maps_flutter: latest_version
google_maps_webservice: latest_version
image_picker: latest_version
Run flutter pub get to install these dependencies.

Final Touches
Ensure your Firebase project is set up correctly and linked to your Flutter project.
Ensure your Google Maps API is enabled for your project on the Google Cloud Console.
Test the integration to make sure everything is working as expected.
With these steps, your project should be configured correctly to use Firebase and Google Maps in both Android and iOS.
# Demo_taxi_app1
