# Frontend Documentation

## 1. Overview

The NAVIAI frontend is a Flutter-based mobile application designed to provide a user-friendly navigation interface for dead-reckoning-based positioning.

The application provides the user with destination search, map-based navigation, location services, trip-related features, and sensor availability checks. The frontend is designed to provide a continuous navigation experience while the backend and AI components handle positioning and dead-reckoning functionality.

## 2. Technology Stack

The frontend is developed using Flutter, providing a cross-platform mobile application interface.

### Technologies Used

- **Flutter** — Mobile application development and UI
- **Dart** — Application programming language
- **OpenStreetMap** — Map data and map visualization
- **OSRM** — Route calculation
- **Nominatim** — Place and destination search
- **Device Location Services** — Obtaining the user's current location
- **Device Sensors** — Accelerometer and gyroscope data used by the navigation system

## 3. Application Screens

### 3.1 Splash Screen
[image]

### 3.2 Onboarding and Setup
[image]

### 3.3 Home Screen
[image]

### 3.4 Destination Search
[image]

### 3.5 Map and Navigation
[image]

### 3.6 Trips
[image]

### 3.7 Settings
[image]

## 4. Frontend Features

The NAVIAI frontend provides the following key features:

- User onboarding and navigation setup
- Device location access
- Accelerometer and gyroscope availability checks
- Destination search
- Map visualization
- Route display
- Current-location tracking
- Trip management
- Application settings
- Navigation status display

## 5. Location and Map Functionality

The application uses the device's location services to obtain the user's current position and display it on the navigation interface.

OpenStreetMap is used for map visualization, while OSRM is used for route calculation. Nominatim is used to search for destinations and locations.

The map interface provides the visual foundation for displaying the user's position and navigation route.

## 6. Device Sensor Integration

The application checks the availability of the device sensors required by the navigation system.

The primary sensors involved are:

- **Accelerometer** — provides acceleration measurements from the device.
- **Gyroscope** — provides angular velocity measurements from the device.
- **Location sensor/GPS** — provides positioning information when satellite positioning is available.

These sensor inputs are intended to provide the navigation system with motion information that can be used during periods of reduced or unavailable GNSS positioning.

The integration between the live phone sensor data and the trained AI model is currently under development.

## 7. Navigation States

The frontend provides different navigation states to represent the availability of GNSS positioning and the use of dead-reckoning navigation.

The intended navigation states include:

- **GPS Active** — GNSS positioning is available.
- **GPS Signal Lost** — GNSS positioning is unavailable.
- **AI Dead Reckoning** — the navigation system continues positioning using dead-reckoning and AI-based correction.
- **GPS Restored** — GNSS positioning becomes available again.
- **GPS + AI Synchronized** — the navigation system returns to combined positioning after GNSS recovery.

These states are represented through the application's navigation interface to communicate the current positioning mode to the user.

> **Implementation status:** The navigation-state interface is available in the frontend. Live switching between these states based on actual sensor and GNSS conditions is being integrated with the backend and AI navigation system.

## 8. User Flow

The main user flow of the NAVIAI application is:

1. The user launches the application.
2. The application displays the splash screen.
3. The user completes the onboarding and device setup.
4. The application checks the availability of location services and required sensors.
5. The user reaches the home screen.
6. The user searches for and selects a destination.
7. The application calculates and displays the route on the map.
8. The navigation interface tracks the user's position.
9. During GNSS signal loss, the navigation system is designed to transition to its dead-reckoning mode.
10. When GNSS positioning becomes available again, the navigation system can return to the normal navigation state.

## 9. Current Implementation Status

| Component | Status |
|---|---|
| Flutter application UI | Completed |
| Splash screen | Completed |
| Onboarding and setup | Completed |
| Location services | Implemented |
| Accelerometer availability | Implemented |
| Gyroscope availability | Implemented |
| Destination search | Implemented |
| Map visualization | Implemented |
| Route display | Implemented |
| Trips section | Implemented |
| Settings section | Implemented |
| Navigation-state UI | Implemented |
| Live sensor-to-AI integration | In progress |
| Complete AI-assisted navigation | In progress |

