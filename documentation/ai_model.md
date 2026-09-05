# AI Model Documentation

## 1. Overview

BEACON uses machine learning to reduce accumulated drift in smartphone-based dead reckoning during temporary GNSS outages.

## 2. AI Model

The system uses XGBoost for learning-based correction of dead-reckoning errors.

The model learns corrections from processed smartphone sensor and navigation data.

## 3. Model Inputs

The finalized AI dataset contains 38 approved input features covering:

* Sensor motion
* Dead-reckoning state
* Heading
* GNSS outage context
* Sensor quality

The approved feature list is maintained in `FEATURE_COLUMNS.json`.

## 4. Model Targets

The dataset provides six target variables:

* `target_delta_east_m`
* `target_delta_north_m`
* `target_error_east_m`
* `target_error_north_m`
* `target_speed_mps`
* `target_speed_error_mps`

The primary correction targets are `target_error_east_m` and `target_error_north_m`.

## 5. Training Dataset

The finalized dataset contains 611,979 AI examples generated from 72 source recordings and 2,629 simulated GNSS outages.

The dataset uses 38 input features and 6 targets at a 10 Hz sampling rate.

## 6. Role in Navigation

During GNSS outages, IMU-based dead reckoning continues estimating motion.

XGBoost provides learned corrections to reduce accumulated positioning drift.

When GNSS becomes available again, the navigation system re-anchors its position.
