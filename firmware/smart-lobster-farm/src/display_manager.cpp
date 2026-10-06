#include "display_manager.h"

#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <Wire.h>

#include "pin_config.h"

namespace {

constexpr uint8_t SCREEN_WIDTH = 128;
constexpr uint8_t SCREEN_HEIGHT = 64;
constexpr int8_t OLED_RESET_PIN = -1;
constexpr uint8_t DISPLAY_I2C_ADDRESS = 0x3C;
constexpr unsigned long DISPLAY_REFRESH_INTERVAL_MS = 750UL;

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET_PIN);

void printSensorLine(const char *label, float value, bool valid,
                     uint8_t decimals, WaterStatus status) {
  display.print(label);
  display.print(' ');
  if (valid) {
    display.print(value, decimals);
    display.print(' ');
    display.print(waterStatusMarker(status));
  } else {
    display.print("ERR !!");
  }
  display.println();
}

}  // namespace

bool DisplayManager::begin() {
  Wire.begin(PinConfig::PIN_I2C_SDA, PinConfig::PIN_I2C_SCL);
  ready_ = display.begin(SSD1306_SWITCHCAPVCC, DISPLAY_I2C_ADDRESS, true,
                         false);
  if (!ready_) {
    Serial.println("[DISPLAY] SSD1306 initialization failed");
    return false;
  }

  display.clearDisplay();
  display.setTextColor(SSD1306_WHITE);
  display.setTextSize(1);
  display.setCursor(0, 0);
  display.println("Smart Lobster");
  display.println();
  display.println("Waiting for sensors");
  display.display();
  Serial.println("[DISPLAY] SSD1306 ready at 0x3C");
  return true;
}

void DisplayManager::update(const SensorReading &reading,
                            const WaterEvaluation &evaluation,
                            unsigned long now) {
  if (!ready_ || now - lastRefreshMs_ < DISPLAY_REFRESH_INTERVAL_MS) {
    return;
  }
  lastRefreshMs_ = now;

  display.clearDisplay();
  display.setTextColor(SSD1306_WHITE);
  display.setTextSize(1);
  display.setCursor(0, 0);
  display.println("Smart Lobster");
  display.drawFastHLine(0, 9, SCREEN_WIDTH, SSD1306_WHITE);
  display.setCursor(0, 13);
  printSensorLine("pH  ", reading.ph, reading.phValid, 2,
                  evaluation.phStatus);
  printSensorLine("TDS ", reading.tds, reading.tdsValid, 0,
                  evaluation.tdsStatus);
  printSensorLine("TEMP", reading.temperature, reading.temperatureValid, 1,
                  evaluation.temperatureStatus);
  display.setCursor(0, 52);
  display.print("SYSTEM: ");
  display.print(waterStatusName(evaluation.systemStatus));
  display.display();
}
