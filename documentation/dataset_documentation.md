# Dataset Documentation

## 1. Primary Dataset — IOVNB S Dataset

The primary dataset used by our prototype is the **S Dataset** from the IOVNB dataset.

It contains time-series sensor and navigation measurements collected during vehicle movement. The dataset provides information about the vehicle's position, motion, acceleration and orientation.

Our backend currently uses the **S Dataset** for developing the AI-ML based dead reckoning prototype.

### Dataset Overview

| Property | Details |
|---|---|
| Dataset | IOVNB Dataset |
| Dataset used | **S Dataset** |
| Data format | CSV |
| Data type | Time-series sensor and navigation data |
| Application | Vehicle navigation and movement |
| Usage in our project | **Primary dataset for the prototype** |

### Data Categories

The S dataset contains several categories of sensor and navigation measurements.

| Category | Measurements |
|---|---|
| GPS | Latitude, Longitude, Altitude |
| GPS Movement | Speed, Orientation |
| GPS Quality | Accuracy, Satellites in range |
| Accelerometer | X, Y, Z |
| Gyroscope | Yaw, Pitch, Roll |
| Magnetic Field | X, Y, Z |
| Gravity | X, Y, Z |
| Orientation | Yaw, Pitch, Roll |
| Time | Timestamp, Time since start |

### Feature Description

The S dataset contains 24 columns. These columns represent positional, motion, orientation, environmental, and time-related information.

| Feature | Description |
|---|---|
| GPS Latitude | Geographic latitude of the recorded position |
| GPS Longitude | Geographic longitude of the recorded position |
| GPS Altitude | Recorded altitude |
| GPS Speed | Speed recorded by the GPS |
| GPS Accuracy | Estimated accuracy of the GPS measurement |
| GPS Orientation | Direction/orientation information from GPS |
| GPS Satellites in Range | Number of satellites detected |
| Time Since Start | Time elapsed since the beginning of the recording |
| Date | Date and time of the measurement |
| Accelerometer X | Acceleration along the X-axis |
| Accelerometer Y | Acceleration along the Y-axis |
| Accelerometer Z | Acceleration along the Z-axis |
| Gravity X | Gravity component along the X-axis |
| Gravity Y | Gravity component along the Y-axis |
| Gravity Z | Gravity component along the Z-axis |
| Gyroscope Yaw | Rotational measurement around the yaw axis |
| Gyroscope Pitch | Rotational measurement around the pitch axis |
| Gyroscope Roll | Rotational measurement around the roll axis |
| Magnetic Field X | Magnetic-field measurement along the X-axis |
| Magnetic Field Y | Magnetic-field measurement along the Y-axis |
| Magnetic Field Z | Magnetic-field measurement along the Z-axis |
| Orientation Yaw | Device orientation around the yaw axis |
| Orientation Pitch | Device orientation around the pitch axis |
| Orientation Roll | Device orientation around the roll axis |

## 4. Example Data Record

Each row in the S dataset represents a set of measurements recorded at a particular point in time.

A simplified representation of a record is:

| Data Type | Example Information |
|---|---|
| Position | Latitude, Longitude, Altitude |
| Movement | GPS Speed |
| Acceleration | Accelerometer X, Y, Z |
| Rotation | Gyroscope Yaw, Pitch, Roll |
| Magnetic Field | X, Y, Z |
| Gravity | X, Y, Z |
| Orientation | Yaw, Pitch, Roll |
| Time | Timestamp / Time Since Start |

The dataset contains a large number of such time-series records collected during vehicle movement.

## 5. Relevance to Dead Reckoning

Dead reckoning estimates the current position of a moving system using information about its previous position and movement.

The S dataset provides several measurements that are relevant to this process, including:

- Acceleration from the accelerometer
- Rotational measurements from the gyroscope
- Magnetic-field measurements
- Orientation information
- Speed and GPS information
- Time-related information

These measurements describe how the vehicle moves and changes orientation over time. Processing this time-series information can therefore support movement and position estimation for the proposed AI-ML based dead reckoning system.

The S dataset is used as the primary data source for the current prototype.

## 6. Dataset File Structure

The source data consists of synchronized **S (smartphone)** and **V (vehicle)** datasets.

For the current ML pipeline, corresponding S and V journeys are matched and synchronized to create a derived dataset called **`Merged_S_V_Dataset`**.

The corrected training data currently contains **72 matched journeys** and approximately **1,065,198 synchronized samples**.

### Dataset Components

| Component | Role |
|---|---|
| S Dataset | Provides smartphone sensor measurements used as ML inputs |
| V Dataset | Provides vehicle velocity and heading information used to generate training labels |
| Merged_S_V_Dataset | Contains synchronized S and V journey data used for ML training-data preparation |

The classical C++ dead-reckoning baseline continues to read the original S sensor files, while the merged S+V data is primarily used to construct reliable ML training labels.

## 7. Dataset Processing Flow

The ML training pipeline uses synchronized smartphone (S) and vehicle (V) data. The S data provides the sensor measurements, while the V data is used to generate reliable displacement labels.

The current processing flow is:

```text
S Dataset + V Dataset
          │
          ▼
Match Corresponding Journeys
          │
          ▼
Synchronize S and V Samples
          │
          ▼
Calculate Time Interval (dt)
          │
          ▼
Calculate Linear Acceleration
(Accelerometer − Gravity)
          │
          ▼
Generate East/North Displacement Labels
          │
          ▼
Prepare 8 ML Input Features
          │
          ▼
XGBoost Regression
          │
          ▼
Δx (East Displacement)
+
Δy (North Displacement)
          │
          ▼
Update Local Position
```

### Preprocessing

The current preprocessing pipeline includes:

- Matching corresponding S and V journeys.
- Keeping synchronized samples.
- Removing unmatched tail rows when the two files have different lengths.
- Calculating the time interval (`dt_s`) from consecutive S timestamps.
- Calculating linear acceleration by subtracting gravity from accelerometer measurements.
- Converting vehicle velocity from km/h to m/s when generating labels.
- Converting heading to radians when required for calculations.
- Generating East and North displacement labels using vehicle velocity and heading.
- Skipping invalid timing rows.

No StandardScaler, MinMaxScaler, PCA, or other normalization is currently applied. The XGBoost model receives the physical-unit features directly.

The corrected training dataset currently contains no missing values.

## 8. ML Training Data Preparation

For the ML training pipeline, the smartphone **S dataset** and vehicle **V dataset** are synchronized and merged to create the training data.

The current training dataset contains:

| Property | Details |
|---|---|
| Matched journeys | 72 |
| Synchronized samples | Approximately 1,065,198 |
| Mean time interval (`dt`) | Approximately 0.0999 seconds |
| Missing values | None |
| Effectively zero-displacement samples | Approximately 0.045% |

The **S dataset** provides the smartphone sensor measurements used as inputs to the ML model.

The **V dataset** provides vehicle velocity and heading information used to generate the displacement labels required for training.

> **Note:** V-dataset information is used to generate training labels and is not used as a runtime ML input.

### ML Model Inputs

The current XGBoost baseline uses eight input features:

| No. | Feature | Unit |
|---|---|---|
| 1 | Linear Acceleration X | m/s² |
| 2 | Linear Acceleration Y | m/s² |
| 3 | Linear Acceleration Z | m/s² |
| 4 | Gyroscope X | rad/s |
| 5 | Gyroscope Y | rad/s |
| 6 | Gyroscope Z | rad/s |
| 7 | Phone Heading | degrees |
| 8 | Time Interval (`dt`) | seconds |

The journey identifier and timestamp are retained as metadata and are not used as ML features.
