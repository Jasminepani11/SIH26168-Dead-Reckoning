# Data Processing Documentation

## 1. Overview

The raw phone and GNSS sensor data is processed before being used for AI model training.

The processing pipeline cleans the recorded data, standardizes the sensor timebase, prepares reliable GNSS ground truth, corrects sensor-related effects, and generates realistic GNSS outage scenarios for training the dead-reckoning correction model.

The final processed dataset contains **611,979 AI training examples** from **72 source recordings**, including **2,629 simulated GNSS outages**.

## 2. Processing Pipeline

The data goes through the following major stages:

1. **Data Cleaning** — Removes duplicate and invalid records and separates discontinuous recordings.
2. **Timebase Normalization** — Resamples the sensor data to a consistent 10 Hz timebase.
3. **GNSS Ground Truth** — Filters unreliable GNSS fixes and reconstructs valid position data.
4. **Sensor Correction** — Applies gravity removal, orientation correction, bias correction, and noise filtering.
5. **GNSS Outage Generation** — Creates simulated 5, 10, 20, 30, and 60-second GNSS outages for AI training.
6. **Feature & Target Generation** — Creates the inputs and outputs required by the AI model.
7. **Dataset Splitting** — Separates the data into training, validation, and test sets while preventing data leakage.

## 3. Final AI Dataset

The processed data is stored as an AI-ready dataset for model development.

### Dataset Summary

| Property | Value |
|---|---:|
| Source recordings | 72 |
| Final AI examples | 611,979 |
| Simulated GNSS outages | 2,629 |
| Input features | 38 |
| Targets | 6 |
| Sampling rate | 10 Hz |

The dataset is divided into separate training, validation, and test sets. The split is performed at the source-drive level to prevent highly correlated samples from the same recording from appearing across different sets.

## 4. Data Quality and Validation

Several validation checks were performed throughout the processing pipeline to ensure that the final dataset was suitable for AI training.

Key results include:

- **0** invalid IMU rows after resampling
- **14,025** GNSS fixes accepted after quality filtering
- **0** non-finite corrected sensor rows
- No source-drive or outage leakage between training, validation, and test sets
- Final dataset quality checks: **PASS**

The preprocessing pipeline is considered complete and frozen unless a specific data defect is identified during model validation.
