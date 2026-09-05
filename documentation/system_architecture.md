# System Architecture

## 1. Overview

BEACON is a hybrid GNSS and IMU navigation system designed to maintain positioning during temporary GNSS-denied conditions.

## 2. System Components

| Component | Technology | Role |
| --- | --- | --- |
| Application | Flutter / Dart | User interface and navigation |
| Navigation Engine | C++ | IMU-based dead reckoning |
| AI Model | XGBoost | Dead-reckoning drift correction |
| Maps | OpenStreetMap + Flutter Map | Map visualization |
| Positioning | GNSS + IMU | Continuous navigation |

## 3. Navigation Flow

**GNSS + IMU → Dead Reckoning → XGBoost Correction → Position Estimate**

During GNSS outages, IMU-based dead reckoning continues estimating motion while XGBoost helps reduce accumulated drift.

When GNSS returns, the system re-anchors the position.

## 4. Key Design Goal

The system aims to provide continuous navigation during temporary GNSS-denied conditions such as tunnels, urban canyons, and other environments with unreliable GNSS positioning.
