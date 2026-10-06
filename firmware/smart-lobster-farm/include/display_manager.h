#pragma once

#include <Arduino.h>

#include "sensor_data.h"
#include "water_status.h"

class DisplayManager {
 public:
  bool begin();
  void update(const SensorReading &reading,
              const WaterEvaluation &evaluation, unsigned long now);

 private:
  bool ready_ = false;
  unsigned long lastRefreshMs_ = 0;
};
