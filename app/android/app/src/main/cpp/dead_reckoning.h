#ifndef DEAD_RECKONING_H
#define DEAD_RECKONING_H

#include <cstdint>

#ifdef __cplusplus
extern "C" {
#endif

void* dr_create();

void dr_destroy(void* handle);

void dr_reset(void* handle);

void dr_update_gps(
    void* handle,
    double latitude,
    double longitude,
    int64_t timestampMs,
    int32_t hasAccuracy,
    double accuracy,
    int32_t hasSpeed,
    double speedMps,
    int32_t hasBearing,
    double bearingDeg
);

void dr_update_imu(
    void* handle,

    double accelX,
    double accelY,
    double accelZ,

    double gravityX,
    double gravityY,
    double gravityZ,

    double gyroX,
    double gyroY,
    double gyroZ,

    double yawDeg,
    double pitchDeg,
    double rollDeg,

    int64_t timestampMs
);

double dr_get_latitude(void* handle);

double dr_get_longitude(void* handle);

double dr_get_heading_deg(void* handle);

int32_t dr_get_mode(void* handle);

int32_t dr_is_initialized(void* handle);

#ifdef __cplusplus
}
#endif

#endif