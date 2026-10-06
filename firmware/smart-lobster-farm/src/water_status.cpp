#include "water_status.h"

#include <math.h>

WaterStatus evaluatePh(float value, bool valid) {
  if (!valid || !isfinite(value)) {
    return WaterStatus::WARNING;
  }
  if (value >= WaterThresholds::PH_NORMAL_MIN &&
      value <= WaterThresholds::PH_NORMAL_MAX) {
    return WaterStatus::NORMAL;
  }
  if (value >= WaterThresholds::PH_CAUTION_MIN &&
      value <= WaterThresholds::PH_CAUTION_MAX) {
    return WaterStatus::CAUTION;
  }
  return WaterStatus::WARNING;
}

WaterStatus evaluateTds(float value, bool valid) {
  if (!valid || !isfinite(value)) {
    return WaterStatus::WARNING;
  }
  if (value >= WaterThresholds::TDS_REFERENCE_MIN &&
      value <= WaterThresholds::TDS_REFERENCE_MAX) {
    return WaterStatus::NORMAL;
  }
  return WaterStatus::CAUTION;
}

WaterStatus evaluateTemperature(float value, bool valid) {
  if (!valid || !isfinite(value)) {
    return WaterStatus::WARNING;
  }
  if (value >= WaterThresholds::TEMPERATURE_NORMAL_MIN &&
      value <= WaterThresholds::TEMPERATURE_NORMAL_MAX) {
    return WaterStatus::NORMAL;
  }
  if (value > WaterThresholds::TEMPERATURE_NORMAL_MAX &&
      value <= WaterThresholds::TEMPERATURE_CAUTION_MAX) {
    return WaterStatus::CAUTION;
  }
  return WaterStatus::WARNING;
}

WaterStatus worstStatus(WaterStatus first, WaterStatus second) {
  return static_cast<uint8_t>(first) >= static_cast<uint8_t>(second) ? first
                                                                    : second;
}

const char *waterStatusName(WaterStatus status) {
  switch (status) {
    case WaterStatus::CAUTION:
      return "CAUTION";
    case WaterStatus::WARNING:
      return "WARNING";
    case WaterStatus::NORMAL:
    default:
      return "NORMAL";
  }
}

const char *waterStatusMarker(WaterStatus status) {
  switch (status) {
    case WaterStatus::CAUTION:
      return "!";
    case WaterStatus::WARNING:
      return "!!";
    case WaterStatus::NORMAL:
    default:
      return "OK";
  }
}

WaterStatus ConfirmedStatus::update(WaterStatus observed) {
  if (!initialized_) {
    initialized_ = true;
    active_ = observed;
    candidate_ = observed;
    candidateReadings_ = 0;
    return active_;
  }

  if (observed == active_) {
    candidate_ = observed;
    candidateReadings_ = 0;
    return active_;
  }

  // Never delay critical escalation or an invalid sensor warning.
  if (observed == WaterStatus::WARNING) {
    active_ = observed;
    candidate_ = observed;
    candidateReadings_ = 0;
    return active_;
  }

  if (observed != candidate_) {
    candidate_ = observed;
    candidateReadings_ = 1;
  } else if (candidateReadings_ < UINT8_MAX) {
    candidateReadings_++;
  }

  if (candidateReadings_ >=
      WaterThresholds::NON_WARNING_CONFIRMATION_READINGS) {
    active_ = candidate_;
    candidateReadings_ = 0;
  }
  return active_;
}

WaterEvaluation WaterStatusMonitor::update(const SensorReading &reading) {
  WaterEvaluation result;
  result.phStatus =
      phStatus_.update(evaluatePh(reading.ph, reading.phValid));
  result.tdsStatus =
      tdsStatus_.update(evaluateTds(reading.tds, reading.tdsValid));
  result.temperatureStatus = temperatureStatus_.update(
      evaluateTemperature(reading.temperature, reading.temperatureValid));
  result.systemStatus = worstStatus(
      worstStatus(result.phStatus, result.tdsStatus),
      result.temperatureStatus);
  return result;
}
