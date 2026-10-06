#pragma once

#include <Arduino.h>

#include "water_status.h"

class AlertManager {
 public:
  void begin();
  void setStatus(WaterStatus status, unsigned long now);
  void update(unsigned long now);

 private:
  void setLed(bool on);
  void setBuzzer(bool on);

  WaterStatus status_ = WaterStatus::NORMAL;
  unsigned long statusStartedMs_ = 0;
  bool ledOn_ = false;
  bool buzzerOn_ = false;
};
