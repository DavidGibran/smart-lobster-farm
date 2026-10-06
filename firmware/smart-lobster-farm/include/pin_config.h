#pragma once

#include <stdint.h>

namespace PinConfig {

// Existing ADC1 pins are retained so analog reads keep working while Wi-Fi is on.
constexpr uint8_t PIN_PH = 34;
constexpr uint8_t PIN_TDS = 35;
constexpr uint8_t PIN_DS18B20 = 4;

// Safe general-purpose output pins with no ESP32 boot-strap role.
constexpr uint8_t PIN_LED = 18;
constexpr uint8_t PIN_BUZZER = 19;

// Standard ESP32 I2C pins.
constexpr uint8_t PIN_I2C_SDA = 21;
constexpr uint8_t PIN_I2C_SCL = 22;

}  // namespace PinConfig
