#include "alert_manager.h"

#include "pin_config.h"

namespace {

constexpr unsigned long CAUTION_LED_CYCLE_MS = 2000UL;
constexpr unsigned long CAUTION_LED_ON_MS = 500UL;
constexpr unsigned long WARNING_LED_CYCLE_MS = 500UL;
constexpr unsigned long WARNING_LED_ON_MS = 250UL;

constexpr unsigned long CAUTION_BUZZER_CYCLE_MS = 25000UL;
constexpr unsigned long CAUTION_BUZZER_ON_MS = 100UL;
constexpr unsigned long WARNING_BUZZER_CYCLE_MS = 5000UL;
constexpr unsigned long WARNING_BUZZER_FIRST_END_MS = 200UL;
constexpr unsigned long WARNING_BUZZER_SECOND_START_MS = 400UL;
constexpr unsigned long WARNING_BUZZER_SECOND_END_MS = 600UL;
constexpr unsigned int BUZZER_FREQUENCY_HZ = 2000U;

}  // namespace

void AlertManager::begin() {
  pinMode(PinConfig::PIN_LED, OUTPUT);
  pinMode(PinConfig::PIN_BUZZER, OUTPUT);
  digitalWrite(PinConfig::PIN_LED, LOW);
  noTone(PinConfig::PIN_BUZZER);
  ledOn_ = false;
  buzzerOn_ = false;
}

void AlertManager::setStatus(WaterStatus status, unsigned long now) {
  if (status == status_) {
    return;
  }
  status_ = status;
  statusStartedMs_ = now;
  setLed(false);
  setBuzzer(false);
}

void AlertManager::update(unsigned long now) {
  const unsigned long elapsed = now - statusStartedMs_;

  if (status_ == WaterStatus::NORMAL) {
    setLed(false);
    setBuzzer(false);
    return;
  }

  if (status_ == WaterStatus::CAUTION) {
    setLed(elapsed % CAUTION_LED_CYCLE_MS < CAUTION_LED_ON_MS);
    setBuzzer(elapsed % CAUTION_BUZZER_CYCLE_MS < CAUTION_BUZZER_ON_MS);
    return;
  }

  setLed(elapsed % WARNING_LED_CYCLE_MS < WARNING_LED_ON_MS);
  const unsigned long buzzerPhase = elapsed % WARNING_BUZZER_CYCLE_MS;
  setBuzzer(buzzerPhase < WARNING_BUZZER_FIRST_END_MS ||
            (buzzerPhase >= WARNING_BUZZER_SECOND_START_MS &&
             buzzerPhase < WARNING_BUZZER_SECOND_END_MS));
}

void AlertManager::setLed(bool on) {
  if (on == ledOn_) {
    return;
  }
  ledOn_ = on;
  digitalWrite(PinConfig::PIN_LED, on ? HIGH : LOW);
}

void AlertManager::setBuzzer(bool on) {
  if (on == buzzerOn_) {
    return;
  }
  buzzerOn_ = on;
  if (on) {
    tone(PinConfig::PIN_BUZZER, BUZZER_FREQUENCY_HZ);
  } else {
    noTone(PinConfig::PIN_BUZZER);
  }
}
