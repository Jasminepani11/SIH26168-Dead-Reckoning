# SIH26168 - Intelligent Dead Reckoning System

This project was developed for SIH26168 and focuses on maintaining navigation when GPS becomes temporarily unreliable or unavailable.

The basic idea is to use the phone's sensors along with GPS. Under normal conditions the app uses GPS, but when the GPS signal is lost, sensor data can be used by the dead reckoning system to estimate the user's movement until a reliable GPS position is available again.

The Android app is built using Flutter.

## How it works

The overall flow of the project is:

```text
Phone Sensors + GPS
        |
        v
Sensor Processing
        |
        v
AI / Movement Estimation
        |
        v
Dead Reckoning
        |
        v
GPS + DR Position
        |
        v
Navigation App
```

GPS gives us an absolute position whenever it is available. If GPS is lost, the last reliable GPS position is used as the starting point for dead reckoning.

The accelerometer and gyroscope provide information about the phone's movement. This data has to be processed before it can be used because the sensor axes depend on how the phone is oriented.

One of the main problems with dead reckoning is drift. Small errors in the sensor readings accumulate over time, so the system is mainly intended to handle temporary GPS outages rather than completely replace GPS.

## Main Features

- GPS navigation
- Accelerometer and gyroscope data collection
- Sensor orientation handling
- Dead reckoning during GPS loss
- AI/ML movement estimation
- GPS and dead reckoning integration
- Route display and destination selection
- Speed, heading and GPS accuracy display
- Flutter Android application
- Support for offline navigation components

## Running the App

### Requirements

You will need:

- Flutter SDK
- Android Studio / Android SDK
- Git
- An Android phone with USB debugging enabled

Using a real Android phone is recommended since the project depends on the phone's motion sensors.

### 1. Clone the repository

```bash
git clone https://github.com/Jasminepani11/SIH26168-Dead-Reckoning.git
cd SIH26168-Dead-Reckoning
```

### 2. Go to the Flutter project

```bash
cd app
```

### 3. Install the dependencies

```bash
flutter pub get
```

### 4. Check your Flutter setup

```bash
flutter doctor
```

Fix any required Android or Flutter setup problems shown by `flutter doctor`.

### 5. Connect your phone

Enable Developer Options and USB Debugging on the Android phone, then connect it to the computer.

You can check if Flutter detects it using:

```bash
flutter devices
```

### 6. Run the app

```bash
flutter run
```

Allow the location permissions requested by the app when it starts.

## Building the APK

From inside the `app` folder:

```bash
flutter build apk --release
```

The APK should be generated at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

For a debug APK:

```bash
flutter build apk --debug
```

## Project Structure

```text
SIH26168-Dead-Reckoning/
|
|-- app/                 Flutter application
|   |-- android/
|   |-- lib/
|   |   |-- models/
|   |   |-- screens/
|   |   |-- services/
|   |   `-- main.dart
|   `-- pubspec.yaml
|
|-- documentation/
|
`-- README.md
```

Most of the application logic is inside `app/lib`.

The services folder contains the location, sensor and dead reckoning related parts of the application, while the screens folder contains the Flutter UI.

## Flutter Packages Used

Some of the main packages used in the app are:

- `geolocator` - GPS/location
- `sensors_plus` - accelerometer and gyroscope
- `flutter_compass2` - compass/orientation
- `flutter_map` - map display
- `latlong2` - coordinate calculations
- `permission_handler` - Android permissions
- `provider` - state management
- `http` - network requests
- `shared_preferences` - local storage
- `flutter_tts` - text-to-speech

## GPS and Dead Reckoning

During normal navigation, GPS is used as the main position source.

If GPS becomes unreliable, the system can use the last reliable GPS coordinate as an anchor and continue estimating movement using the dead reckoning pipeline.

When GPS becomes reliable again, the estimated position can be corrected using the new GPS position.

The app is structured so that the map does not need to handle GPS and dead reckoning separately. It receives a common navigation position containing values such as:

- latitude and longitude
- speed
- heading
- accuracy
- position source
- timestamp

This made it easier for us to integrate the dead reckoning work with the existing navigation app.

## Testing

For testing dead reckoning, GPS can be deliberately removed from part of a recorded journey.

The hidden GPS positions are not given to the dead reckoning system, but they can still be kept separately as the actual path. This gives us something to compare the estimated path against.

For example:

```text
GPS:       ● ● ● ● ● ● ● ● ● ●

DR input:  ● ● ● X X X X ● ● ●
                 ^
             GPS outage
```

This allows us to measure how much the estimated position drifts while GPS is unavailable.

## Limitations

The main limitation is accumulated drift. Smartphone sensors contain noise and small measurement errors, and those errors become more significant the longer dead reckoning runs without GPS.

Phone orientation is another issue because accelerometer and gyroscope measurements are relative to the phone itself. Moving or rotating the phone can therefore affect the sensor readings.

Different phones also use different sensor hardware, so performance may not be identical across devices.

Because of this, the aim of the project is not to replace GPS completely. It is to keep navigation working through temporary periods where GPS cannot provide a reliable position.

## Future Work

There are several areas we would like to improve further:

- Better GPS/DR fusion
- More training and testing data
- Testing across different phones and vehicles
- Longer GPS outage testing
- Improved offline maps and routing
- Better handling of arbitrary phone movement
- Optimizing model inference and battery usage

## Team

Developed for **SIH26168 - AI/ML Based Intelligent Dead Reckoning System for Seamless Navigation**.
