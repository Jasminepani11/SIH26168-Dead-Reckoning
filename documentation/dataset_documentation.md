# Dataset Documentation

## 1. Primary Dataset — Synchronized S and V Datasets

The project uses synchronized **S (smartphone)** and **V (vehicle)** datasets for preparing the ML training data.

The **S dataset** contains smartphone sensor and navigation measurements, including GPS information, accelerometer measurements, gravity, gyroscope measurements, phone orientation/yaw, and timing information.

The **V dataset** contains vehicle-related measurements, including vehicle velocity and heading.

For ML preparation, corresponding S and V journeys are matched and synchronized to create a derived dataset called **`Merged_S_V_Dataset`**.

The current merged training dataset contains **72 matched journeys** and approximately **1,065,198 synchronized samples**.

The S dataset provides the sensor measurements used as ML inputs, while the V dataset is currently used mainly to generate reliable training labels for East and North displacement.

> **Note:** The V dataset is used for training-label generation and is not used as a runtime ML input.

## 2. Data Categories

The synchronized dataset contains measurements from two main sources:

| Category | Source | Description |
|---|---|---|
| GPS Data | S | Latitude, longitude, speed, and heading measurements from the smartphone |
| Accelerometer Data | S | Three-axis acceleration measurements |
| Gravity Data | S | Three-axis gravity measurements used to obtain linear acceleration |
| Gyroscope Data | S | Three-axis angular velocity measurements |
| Phone Orientation | S | Phone orientation/yaw information |
| Timing Data | S | Time information used to calculate the sampling interval (`dt_s`) |
| Vehicle Velocity | V | Vehicle speed used to generate displacement labels |
| Vehicle Heading | V | Vehicle heading used with velocity to generate displacement labels |

The S-side measurements provide the sensor information required for the ML features. The V-side velocity and heading measurements are used to generate the East and North displacement labels for supervised training.

## 3. Feature Description

The S dataset contains the sensor measurements from which the ML input features are derived. The first XGBoost baseline uses exactly eight input features:

| Feature | Unit | Description |
|---|---|---|
| `linear_accel_x` | m/s² | Linear acceleration along the X-axis, obtained by subtracting gravity from the accelerometer measurement |
| `linear_accel_y` | m/s² | Linear acceleration along the Y-axis, obtained by subtracting gravity from the accelerometer measurement |
| `linear_accel_z` | m/s² | Linear acceleration along the Z-axis, obtained by subtracting gravity from the accelerometer measurement |
| `gyro_x` | rad/s | Angular velocity around the X-axis |
| `gyro_y` | rad/s | Angular velocity around the Y-axis |
| `gyro_z` | rad/s | Angular velocity around the Z-axis |
| `phone_heading_deg` | degrees | Phone heading/orientation used as an input feature |
| `dt_s` | seconds | Time interval between consecutive synchronized samples |

The ML model predicts two displacement values for each prediction interval:

- `delta_x` — East displacement in metres
- `delta_y` — North displacement in metres

The `journey` and `time_s` fields are retained as metadata and are not used as ML input features.

## 4. Example Data Record

A synchronized record contains sensor measurements from the S dataset along with the corresponding vehicle information from the V dataset.

A simplified example of the data structure is:

| Field | Example | Description |
|---|---:|---|
| `time_s` | 12.50 | Time since the start of the journey |
| `accel_x` | 0.42 | Accelerometer X-axis measurement |
| `accel_y` | -0.13 | Accelerometer Y-axis measurement |
| `accel_z` | 9.81 | Accelerometer Z-axis measurement |
| `gravity_x` | 0.01 | Gravity X-axis component |
| `gravity_y` | -0.02 | Gravity Y-axis component |
| `gravity_z` | 9.79 | Gravity Z-axis component |
| `gyro_x` | 0.012 | Gyroscope X-axis measurement |
| `gyro_y` | -0.021 | Gyroscope Y-axis measurement |
| `gyro_z` | 0.104 | Gyroscope Z-axis measurement |
| `phone_heading_deg` | 87.4 | Phone heading in degrees |
| `V_Velocity` | 36.0 | Vehicle velocity in km/h |
| `V_Heading` | 90.0 | Vehicle heading in degrees |

The complete synchronized dataset contains additional GPS and metadata fields. The fields used for ML training are derived from the available sensor measurements during preprocessing.

## 5. Relevance to Dead Reckoning

Dead reckoning estimates the current position of a moving vehicle using motion and sensor information when reliable GPS positioning is unavailable.

The dataset is relevant to the project because it provides synchronized smartphone sensor measurements along with vehicle velocity and heading information. The smartphone measurements provide the sensor features used by the ML model, while the vehicle measurements provide reference information for generating displacement labels.

For each synchronized time interval, the vehicle velocity and heading are used to calculate the corresponding displacement in the East and North directions. These values form the target outputs for supervised ML training.

The resulting training data allows the XGBoost regression models to learn the relationship between smartphone sensor measurements and vehicle displacement.

## 6. Dataset File Structure

The source data consists of synchronized S-series smartphone sensor recordings from the IOVNB dataset.

For the AI preprocessing pipeline, only the Categorised S-series dataset tree is used. The Categorised and Uncategorised trees were identified as duplicate mirrors of the same underlying drives, so the Uncategorised mirror is excluded to prevent duplicate training data.

The original dataset contains 72 unique S-series recordings and 1,070,745 sensor rows.

During structural processing, exact duplicate rows were removed and recordings were segmented at gaps greater than 500 ms. This produced 83 continuous sequences.

After timebase normalization and resampling to a uniform 10 Hz grid, the processed dataset contained 1,064,108 rows.

The final AI training dataset contains 611,979 examples generated from controlled simulated GNSS outages.

### Dataset Components

| Component | Role |
| --- | --- |
| S-series Dataset | Provides smartphone sensor and GNSS measurements used for preprocessing and AI training |
| Continuous Sequences | Segmented recordings used to maintain valid continuous time intervals |
| Resampled Dataset | Uniform 10 Hz sensor stream used for feature construction |
| AI Training Dataset | Final HDF5 dataset containing training, validation and test examples |

The final AI dataset is stored in HDF5 format with separate `/train`, `/validation`, and `/test` tables.

## 7. Dataset Processing Flow

The AI training pipeline processes the S-series sensor data through several controlled stages.

The overall processing flow is:

    S-series Sensor Dataset
              │
              ▼
    Source Selection & Deduplication
              │
              ▼
    Structural Cleanup
              │
              ▼
    Timebase Normalization
              │
              ▼
    Uniform 10 Hz Resampling
              │
              ▼
    GNSS Ground-Truth Reconstruction
              │
              ▼
    Sensor Correction
              │
              ▼
    Artificial GNSS Outage Generation
              │
              ▼
    Feature & Target Construction
              │
              ▼
    Leakage-Safe Train / Validation / Test Split
              │
              ▼
    Final HDF5 AI Training Dataset

### Preprocessing

The preprocessing pipeline includes:

* Selecting the Categorised S-series dataset tree and excluding the duplicate Uncategorised mirror.
* Removing exact duplicate rows.
* Using the absolute DATE field as the canonical timestamp.
* Repairing timestamp resets.
* Splitting recordings at gaps greater than 500 ms.
* Resampling the sensor data to a uniform 10 Hz grid.
* Selecting the nearest real IMU snapshot without interpolating sensor measurements.
* Applying an IMU validity gate to prevent distant source samples from being used.
* Identifying valid GNSS fix events.
* Filtering GNSS fixes using reported accuracy and physical-transition checks.
* Interpolating only short GNSS intervals between accepted fixes.
* Converting GNSS positions to a local East/North/Up representation.
* Removing gravity from accelerometer measurements.
* Correcting device-frame measurements into the East/North/Up world frame.
* Applying causal sensor bias estimation where sufficient stable IMU evidence is available.
* Applying causal low-pass filtering to reduce high-frequency sensor noise.
* Generating controlled artificial GNSS outages for supervised AI training.
* Constructing causal motion, dead-reckoning, heading and sensor-quality features.
* Splitting the data by complete source recording to prevent leakage.

## 8. ML Training Data Preparation

After synchronization and preprocessing, the merged S + V data is prepared for supervised machine learning.

The S dataset provides the sensor-based input features, while the V dataset provides reference vehicle information used to generate the displacement labels.

The eight input features used for the initial XGBoost baseline are:

- `linear_accel_x`
- `linear_accel_y`
- `linear_accel_z`
- `gyro_x`
- `gyro_y`
- `gyro_z`
- `phone_heading_deg`
- `dt_s`

The target values are:

- `delta_x` — East displacement in metres
- `delta_y` — North displacement in metres

The resulting training data therefore consists of the eight sensor-derived input features and the corresponding East/North displacement labels.

The current merged dataset contains approximately 1,065,198 synchronized samples from 72 matched journeys.

The exact train/test split and final training configuration will be finalized as the ML implementation is completed.

## 9. ML Model and Prediction

The initial ML approach uses **XGBoost regression** to estimate vehicle displacement from smartphone sensor measurements.

Two regression outputs are considered:

- `delta_x` — predicted East displacement in metres
- `delta_y` — predicted North displacement in metres

The model uses the following eight input features:

1. `linear_accel_x`
2. `linear_accel_y`
3. `linear_accel_z`
4. `gyro_x`
5. `gyro_y`
6. `gyro_z`
7. `phone_heading_deg`
8. `dt_s`

The trained models are intended to learn the relationship between smartphone sensor measurements and the corresponding vehicle displacement derived from the V dataset.

The predicted displacement can then be used by the dead reckoning system to estimate movement when reliable GPS information is unavailable or degraded.

The XGBoost model and its final training configuration are currently under development. Final model performance and evaluation results will be added after training and testing are completed.

