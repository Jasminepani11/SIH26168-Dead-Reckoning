# Problem Statement

## SIH26168

AI-ML based Intelligent Dead Reckoning System for Seamless Navigation

 1. Overview

Navigation systems such as GPS/GNSS provide accurate positioning in open environments. However, their performance can become unreliable or unavailable in environments where satellite signals are weak, obstructed, or completely unavailable.
Dead reckoning is a navigation technique used to estimate the current position of a moving system using its previous position and measurements of its movement. Inertial Measurement Units (IMUs), which typically contain accelerometers and gyroscopes, can provide continuous motion information for this purpose.

 2. Problem

Traditional inertial dead reckoning methods are affected by sensor noise, bias, and accumulated drift. Even small errors in sensor measurements can accumulate over time, causing the estimated position to increasingly deviate from the actual position.
Therefore, there is a need for an intelligent navigation system that can use sensor measurements and AI/ML techniques to improve dead reckoning performance and provide more reliable position estimation when GNSS information is unavailable or unreliable.

 3. Proposed Solution

The proposed system aims to develop an AI-ML based intelligent dead reckoning system that processes inertial sensor data to estimate the position of a moving system.

The system will:

- Process and preprocess sensor measurements.
- Use AI/ML techniques to learn patterns in sensor data and motion.
- Estimate the movement and position of the system using dead reckoning.
- Reduce the effects of sensor noise and accumulated drift.
- Provide continuous navigation information when GNSS signals are unavailable or unreliable.

 4. Objective

The primary objective is to develop a prototype capable of providing seamless navigation by combining inertial dead reckoning with AI/ML-based estimation techniques.

The system is intended to improve the reliability of position estimation in situations where conventional satellite-based navigation cannot be continuously relied upon.
