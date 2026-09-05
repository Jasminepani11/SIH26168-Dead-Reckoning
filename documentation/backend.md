# Backend and Navigation Engine

## 1. Overview

BEACON uses a C++ navigation engine together with the Flutter/Dart application layer.

## 2. Navigation Engine

The navigation engine is implemented in C++ and supports IMU-based dead reckoning for navigation during GNSS outages.

## 3. AI Integration

XGBoost is used for learning-based correction of dead-reckoning drift.

## 4. Hybrid Navigation

The system combines GNSS and IMU-based dead reckoning. During temporary GNSS outages, IMU-based dead reckoning maintains the position estimate. When GNSS returns, the system re-anchors the position.

## 5. Application Integration

Flutter/Dart provides the application interface, while the C++ navigation engine handles the core navigation functionality.
