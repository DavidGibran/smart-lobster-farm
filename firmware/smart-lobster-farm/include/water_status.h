#pragma once

#include <stdint.h>

#include "sensor_data.h"

enum class WaterStatus : uint8_t {
  NORMAL = 0,
  CAUTION = 1,
  WARNING = 2,
};

namespace WaterThresholds {

// Operational monitoring thresholds synchronized with the existing mobile app.
// They are configurable prototype thresholds, not absolute biological limits.
constexpr float PH_CAUTION_MIN = 6.5F;
constexpr float PH_NORMAL_MIN = 7.0F;
constexpr float PH_NORMAL_MAX = 8.0F;
constexpr float PH_CAUTION_MAX = 9.0F;

// 320-400 ppm is the project's reference range, not a universal optimum.
constexpr float TDS_REFERENCE_MIN = 320.0F;
constexpr float TDS_REFERENCE_MAX = 400.0F;

constexpr float TEMPERATURE_NORMAL_MIN = 26.0F;
constexpr float TEMPERATURE_NORMAL_MAX = 29.0F;
constexpr float TEMPERATURE_CAUTION_MAX = 32.0F;

// WARNING is immediate; less severe transitions need consecutive confirmation.
constexpr uint8_t NON_WARNING_CONFIRMATION_READINGS = 2;

}  // namespace WaterThresholds

struct WaterEvaluation {
  WaterStatus phStatus = WaterStatus::NORMAL;
  WaterStatus tdsStatus = WaterStatus::NORMAL;
  WaterStatus temperatureStatus = WaterStatus::NORMAL;
  WaterStatus systemStatus = WaterStatus::NORMAL;
};

WaterStatus evaluatePh(float value, bool valid);
WaterStatus evaluateTds(float value, bool valid);
WaterStatus evaluateTemperature(float value, bool valid);
WaterStatus worstStatus(WaterStatus first, WaterStatus second);
const char *waterStatusName(WaterStatus status);
const char *waterStatusMarker(WaterStatus status);

class ConfirmedStatus {
 public:
  WaterStatus update(WaterStatus observed);

 private:
  bool initialized_ = false;
  WaterStatus active_ = WaterStatus::NORMAL;
  WaterStatus candidate_ = WaterStatus::NORMAL;
  uint8_t candidateReadings_ = 0;
};

class WaterStatusMonitor {
 public:
  WaterEvaluation update(const SensorReading &reading);

 private:
  ConfirmedStatus phStatus_;
  ConfirmedStatus tdsStatus_;
  ConfirmedStatus temperatureStatus_;
};
