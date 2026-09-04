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

The project uses synchronized S and V journey files for preparing the ML training data. Corresponding S and V journey files are matched and combined to create the derived `Merged_S_V_Dataset`.

The dataset organization can be represented as:

```text
Synchronized S and V Datasets
│
├── S Dataset
│   └── S-*.csv
│
├── V Dataset
│   └── V-*.csv
│
└── Merged_S_V_Dataset
    └── S + V synchronized journey files
```

The original S files contain smartphone sensor and navigation measurements, while the V files contain vehicle measurements such as velocity and heading.

The `Merged_S_V_Dataset` contains the matched and synchronized S and V journeys used during ML training-data preparation.

The current merged dataset contains 72 matched journeys and approximately 1,065,198 synchronized samples.

## 7. Dataset Processing Flow

The dataset is processed through the following steps before it is used for ML training:

1. **Load S and V data**  
   Smartphone sensor data from the S dataset and vehicle data from the V dataset are loaded.

2. **Match corresponding journeys**  
   S and V journeys are matched to identify corresponding recordings.

3. **Synchronize the data**  
   The matched S and V measurements are synchronized using their timestamps so that corresponding measurements refer to the same time interval.

4. **Calculate the sampling interval**  
   The time difference between consecutive synchronized samples is calculated as `dt_s`.

5. **Prepare sensor features**  
   Accelerometer and gravity measurements are used to obtain linear acceleration. Gyroscope measurements and phone heading are also prepared for ML use.

6. **Generate displacement labels**  
   Vehicle velocity and heading from the V dataset are used to calculate East and North displacement values.

7. **Create the merged dataset**  
   The synchronized information is combined to form the `Merged_S_V_Dataset`, which is used to prepare the ML training data.

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

