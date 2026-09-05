#include "dead_reckoning.h"

#include <cmath>
#include <cstdint>
#include <algorithm>

namespace {

constexpr double PI = 3.14159265358979323846;
constexpr double EARTH_RADIUS_M = 6378137.0;

constexpr double GPS_TIMEOUT_MS = 2500.0;
constexpr double GYRO_BIAS_THRESHOLD_RAD_S = 0.08;
constexpr int GYRO_BIAS_SAMPLES_REQUIRED = 100;

constexpr double GRAVITY_EXPECTED_MPS2 = 9.81;
constexpr double GRAVITY_TOLERANCE_MPS2 = 1.5;

enum Mode {
    MODE_UNINITIALIZED = 0,
    MODE_GPS = 1,
    MODE_DEAD_RECKONING = 2,
};

struct Engine {
    bool initialized = false;

    double latitude = 0.0;
    double longitude = 0.0;

    double eastVelocity = 0.0;
    double northVelocity = 0.0;

    double headingDeg = 0.0;

    int64_t lastGoodGpsMs = 0;
    int64_t lastImuMs = 0;

    int mode = MODE_UNINITIALIZED;

    double gyroZBias = 0.0;
    double gyroBiasSum = 0.0;
    int gyroBiasSamples = 0;
    bool gyroBiasCalibrated = false;
};

double degreesToRadians(double degrees) {
    return degrees * PI / 180.0;
}

double radiansToDegrees(double radians) {
    return radians * 180.0 / PI;
}

double normalizeDegrees(double degrees) {
    double result = std::fmod(degrees, 360.0);

    if (result < 0.0) {
        result += 360.0;
    }

    return result;
}

bool finiteValue(double value) {
    return std::isfinite(value);
}

bool goodGps(
    double latitude,
    double longitude,
    int32_t hasAccuracy,
    double accuracy
) {
    if (!finiteValue(latitude) ||
        !finiteValue(longitude)) {
        return false;
    }

    if (hasAccuracy != 0) {
        if (!finiteValue(accuracy) ||
            accuracy > 20.0 ||
            accuracy < 0.0) {
            return false;
        }
    }

    return true;
}

void updatePositionFromMeters(
    Engine* engine,
    double eastMeters,
    double northMeters
) {
    if (engine == nullptr) {
        return;
    }

    const double latitudeRadians =
        degreesToRadians(engine->latitude);

    const double metersPerDegreeLatitude =
        EARTH_RADIUS_M * PI / 180.0;

    const double cosLatitude =
        std::max(
            0.01,
            std::abs(std::cos(latitudeRadians))
        );

    const double metersPerDegreeLongitude =
        metersPerDegreeLatitude * cosLatitude;

    engine->latitude +=
        northMeters / metersPerDegreeLatitude;

    engine->longitude +=
        eastMeters / metersPerDegreeLongitude;
}

void calibrateGyroBias(
    Engine* engine,
    double gyroZ,
    double gravityX,
    double gravityY,
    double gravityZ
) {
    if (engine == nullptr ||
        engine->gyroBiasCalibrated) {
        return;
    }

    const double gravityMagnitude =
        std::sqrt(
            gravityX * gravityX +
            gravityY * gravityY +
            gravityZ * gravityZ
        );

    const bool gravityValid =
        std::abs(
            gravityMagnitude -
            GRAVITY_EXPECTED_MPS2
        ) <= GRAVITY_TOLERANCE_MPS2;

    const bool gyroStable =
        finiteValue(gyroZ) &&
        std::abs(gyroZ) <=
            GYRO_BIAS_THRESHOLD_RAD_S;

    if (!gravityValid || !gyroStable) {
        return;
    }

    engine->gyroBiasSum += gyroZ;
    engine->gyroBiasSamples++;

    if (engine->gyroBiasSamples >=
        GYRO_BIAS_SAMPLES_REQUIRED) {

        engine->gyroZBias =
            engine->gyroBiasSum /
            static_cast<double>(
                engine->gyroBiasSamples
            );

        engine->gyroBiasCalibrated = true;
    }
}

} // namespace

extern "C" {

void* dr_create() {
    return new Engine();
}

void dr_destroy(void* handle) {
    if (handle == nullptr) {
        return;
    }

    delete static_cast<Engine*>(handle);
}

void dr_reset(void* handle) {
    if (handle == nullptr) {
        return;
    }

    Engine* engine =
        static_cast<Engine*>(handle);

    *engine = Engine();
}

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
) {
    if (handle == nullptr) {
        return;
    }

    Engine* engine =
        static_cast<Engine*>(handle);

    if (!goodGps(
            latitude,
            longitude,
            hasAccuracy,
            accuracy)) {
        return;
    }

    engine->latitude = latitude;
    engine->longitude = longitude;

    engine->lastGoodGpsMs = timestampMs;

    if (hasSpeed != 0 &&
        finiteValue(speedMps) &&
        speedMps >= 0.0) {

        if (hasBearing != 0 &&
            finiteValue(bearingDeg)) {

            const double bearingRad =
                degreesToRadians(
                    bearingDeg
                );

            engine->eastVelocity =
                speedMps *
                std::sin(bearingRad);

            engine->northVelocity =
                speedMps *
                std::cos(bearingRad);

        } else {
            engine->eastVelocity = 0.0;
            engine->northVelocity = 0.0;
        }
    }

    if (hasBearing != 0 &&
        finiteValue(bearingDeg)) {

        engine->headingDeg =
            normalizeDegrees(bearingDeg);
    }

    engine->initialized = true;
    engine->mode = MODE_GPS;
}

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
) {
    if (handle == nullptr) {
        return;
    }

    Engine* engine =
        static_cast<Engine*>(handle);

    if (!finiteValue(accelX) ||
        !finiteValue(accelY) ||
        !finiteValue(accelZ) ||
        !finiteValue(gyroZ)) {
        return;
    }

    calibrateGyroBias(
        engine,
        gyroZ,
        gravityX,
        gravityY,
        gravityZ
    );

    if (engine->lastImuMs == 0) {
        engine->lastImuMs = timestampMs;
        return;
    }

    const double dt =
        static_cast<double>(
            timestampMs -
            engine->lastImuMs
        ) / 1000.0;

    engine->lastImuMs = timestampMs;

    if (dt <= 0.0 || dt > 0.25) {
        return;
    }

    if (!engine->initialized) {
        return;
    }

    const double correctedGyroZ =
        gyroZ -
        engine->gyroZBias;

    engine->headingDeg =
        normalizeDegrees(
            engine->headingDeg +
            radiansToDegrees(
                correctedGyroZ * dt
            )
        );

    const double headingRad =
        degreesToRadians(
            engine->headingDeg
        );

    const double forwardAcceleration =
        accelY;

    const double lateralAcceleration =
        accelX;

    const double northAcceleration =
        forwardAcceleration *
            std::cos(headingRad) -
        lateralAcceleration *
            std::sin(headingRad);

    const double eastAcceleration =
        forwardAcceleration *
            std::sin(headingRad) +
        lateralAcceleration *
            std::cos(headingRad);

    engine->northVelocity +=
        northAcceleration * dt;

    engine->eastVelocity +=
        eastAcceleration * dt;

    const bool gpsStillFresh =
        engine->lastGoodGpsMs != 0 &&
        timestampMs -
            engine->lastGoodGpsMs <=
            static_cast<int64_t>(
                GPS_TIMEOUT_MS
            );

    if (!gpsStillFresh) {
        engine->mode =
            MODE_DEAD_RECKONING;
    }

    if (engine->mode ==
        MODE_DEAD_RECKONING) {

        const double northDistance =
            engine->northVelocity * dt;

        const double eastDistance =
            engine->eastVelocity * dt;

        updatePositionFromMeters(
            engine,
            eastDistance,
            northDistance
        );
    }

    (void)gyroX;
    (void)gyroY;
    (void)yawDeg;
    (void)pitchDeg;
    (void)rollDeg;
}

double dr_get_latitude(void* handle) {
    if (handle == nullptr) {
        return 0.0;
    }

    return static_cast<Engine*>(handle)->latitude;
}

double dr_get_longitude(void* handle) {
    if (handle == nullptr) {
        return 0.0;
    }

    return static_cast<Engine*>(handle)->longitude;
}

double dr_get_heading_deg(void* handle) {
    if (handle == nullptr) {
        return 0.0;
    }

    return static_cast<Engine*>(handle)->headingDeg;
}

int32_t dr_get_mode(void* handle) {
    if (handle == nullptr) {
        return MODE_UNINITIALIZED;
    }

    return static_cast<Engine*>(handle)->mode;
}

int32_t dr_is_initialized(void* handle) {
    if (handle == nullptr) {
        return 0;
    }

    return static_cast<Engine*>(handle)->initialized
        ? 1
        : 0;
}

}