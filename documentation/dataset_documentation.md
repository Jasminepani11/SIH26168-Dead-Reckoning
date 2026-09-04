# Dataset Documentation

 1. Purpose

Datasets are used to understand, train, test, and evaluate inertial navigation and dead reckoning systems. For this project, publicly available datasets related to IMU-based navigation were reviewed as references for understanding sensor data, ground truth information, and machine-learning approaches.

 2. Selected Reference Dataset

### ROCIP Dataset

The ROCIP dataset was introduced as part of the study "ROCIP: Robust Continuous Inertial Position Tracking for Complex Actions Emerging from the Interaction of Human Actors and Environment", published in 2025.
The dataset is relevant to the proposed system because it contains inertial sensor measurements and corresponding ground-truth information for pedestrian position tracking.

### Dataset Details

| Parameter | Details |

| Dataset | ROCIP Dataset |
| Publication Year - 2025 |
| Application - Inertial navigation / Pedestrian Dead Reckoning |
| Subjects - 19 volunteers |
| Sequences - 151 |
| Total Duration - 929.8 minutes |
| IMU - Xsens Dot |
| IMU Sampling Rate - 60 Hz |
| Sensor Placement - Head-mounted |
| Additional Device - Smartphone |
| Ground Truth - Smartphone-based trajectory and orientation data |
| Activities - Walking and running |
| Environments - 4 different environments |
| Data Format - HDF5 (`.hdf5`) |
| Publicly Available | Yes |

 3. Data Characteristics

Each recorded sequence contains IMU measurements from the head-mounted Xsens Dot along with reference trajectory and orientation information obtained using a smartphone.
The dataset includes different walking and running speeds, straight paths, curves, and turns. Participants were also allowed to rotate their heads during movement, providing varied motion patterns for inertial tracking research.

 4. Dataset Source

The official dataset is publicly available through the authors' GitHub repository:

https://github.com/Oxford-NIL/ROCIP

The repository contains the dataset files in its `data` directory.

 5. Relevance to the Proposed System

The ROCIP dataset is relevant as a reference because it contains IMU measurements paired with ground-truth movement information. Such data can be used to study the relationship between inertial sensor measurements and actual movement, which is important for developing and evaluating AI-ML based dead reckoning systems.

 6. Usage in This Project

The ROCIP dataset is documented as a reference dataset for the project. The primary prototype uses the dataset provided by the government as specified for the problem statement. The ROCIP dataset can be considered as an additional reference for future testing, validation, or model development.
