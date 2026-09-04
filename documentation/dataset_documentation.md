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

The AI preprocessing pipeline uses the S-series smartphone sensor recordings from the IOVNB dataset.

Only the Categorised S-series dataset tree is used for AI preprocessing. The Categorised and Uncategorised trees represent duplicate mirrors of the same underlying drives, so the Uncategorised mirror is excluded to prevent duplicate training data.

The source dataset contains 72 unique S-series recordings with 1,070,745 original sensor rows.

After structural cleanup, timebase normalization, sensor correction, and AI-example construction, the final AI-ready dataset contains 611,979 examples.

### Dataset Components

| Component | Role |
| --- | --- |
| S-series Dataset | Provides smartphone sensor and GNSS measurements |
| Continuous Sequences | Valid continuous segments created during preprocessing |
| AI Training Dataset | Final processed dataset used for AI model development |

The detailed transformations applied to the source data are documented in [`data_processing.md`](data_processing.md).

## 7. Dataset Processing

The raw S-series sensor data undergoes multiple processing stages before being used for AI model development.

The complete preprocessing pipeline is documented separately in [`data_processing.md`](data_processing.md).

The major stages are:

* Data cleaning and structural validation
* Timebase normalization and 10 Hz resampling
* GNSS ground-truth reconstruction
* Sensor correction
* Simulated GNSS outage generation
* Feature and target generation
* Leakage-safe dataset splitting

The final processed dataset contains 38 approved input features and 6 supplied targets.

## 8. Final AI Training Dataset

The final AI-ready dataset is generated from the processed S-series recordings.

| Property | Value |
| --- | --- |
| Source recordings | 72 |
| Continuous sequences | 83 |
| Final AI examples | 611,979 |
| Simulated GNSS outages | 2,629 |
| Input features | 38 |
| Targets | 6 |
| Sampling rate | 10 Hz |

The AI examples are generated using simulated GNSS outages of 5, 10, 20, 30, and 60 seconds.

The dataset is divided into training, validation, and test sets at the source-drive level to prevent highly correlated samples from the same recording from appearing across different splits.

## 9. AI Model Inputs and Targets

The final AI dataset contains 38 approved input features representing sensor motion, dead-reckoning state, heading, outage context, and sensor quality.

The feature set includes:

* World-frame acceleration
* World-frame gyroscope measurements
* Acceleration and gyroscope magnitudes
* Jerk and yaw-rate information
* Causal rolling statistics
* Vehicle-relative acceleration
* Dead-reckoning displacement and velocity
* Heading representation
* Integrated yaw
* Distance and time since GNSS
* Initial speed and course
* Initial GNSS accuracy
* Sensor bias confidence and calibration state
* Magnetic-field plausibility

The complete approved feature list is maintained in `FEATURE_COLUMNS.json`.

### Supplied Targets

The final dataset provides six targets:

* `target_delta_east_m`
* `target_delta_north_m`
* `target_error_east_m`
* `target_error_north_m`
* `target_speed_mps`
* `target_speed_error_mps`

The recommended correction targets for the supplied dead-reckoning baseline are:

* `target_error_east_m`
* `target_error_north_m`

The target columns are not used as model inputs.

### Data Leakage Prevention

Only the approved features defined in `FEATURE_COLUMNS.json` may be used as model inputs.

Normalization statistics are calculated from training data only and reused for validation, testing, and inference.

Training, validation, and test data are separated at the source-drive level, and each simulated GNSS outage belongs to only one split.
