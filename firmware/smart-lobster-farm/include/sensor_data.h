#pragma once

struct SensorReading {
  float ph = 0.0F;
  float tds = 0.0F;
  float temperature = 0.0F;
  bool phValid = false;
  bool tdsValid = false;
  bool temperatureValid = false;

  bool allValid() const {
    return phValid && tdsValid && temperatureValid;
  }
};
