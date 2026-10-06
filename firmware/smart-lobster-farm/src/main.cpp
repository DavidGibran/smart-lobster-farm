#include <Arduino.h>

#include <HTTPClient.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <math.h>
#include <time.h>

#include <DallasTemperature.h>
#include <OneWire.h>

#include "alert_manager.h"
#include "display_manager.h"
#include "pin_config.h"
#include "sensor_data.h"
#include "water_status.h"

const unsigned long SENSOR_INTERVAL_MS = 10000UL;
const unsigned long LATEST_INTERVAL_MS = 30000UL;
const unsigned long RAW_HISTORY_INTERVAL_MS = 300000UL;

const long GMT_OFFSET_SECONDS = 7L * 60L * 60L;
const int DAYLIGHT_OFFSET_SECONDS = 0;
const time_t MINIMUM_VALID_EPOCH = 1704067200;  // 2024-01-01 UTC

const char *FIREBASE_BASE_URL =
    "https://smart-lobster-oase-pps-default-rtdb.asia-southeast1.firebasedatabase.app";
const char *FIREBASE_LATEST =
    "https://smart-lobster-oase-pps-default-rtdb.asia-southeast1.firebasedatabase.app/devices/oase-01/latest.json";

OneWire oneWire(PinConfig::PIN_DS18B20);
DallasTemperature tempSensor(&oneWire);

struct RawAccumulator {
  double phSum = 0.0;
  double tdsSum = 0.0;
  double temperatureSum = 0.0;
  uint32_t sampleCount = 0;

  void add(const SensorReading &reading) {
    phSum += reading.ph;
    tdsSum += reading.tds;
    temperatureSum += reading.temperature;
    sampleCount++;
  }

  void reset() {
    phSum = 0.0;
    tdsSum = 0.0;
    temperatureSum = 0.0;
    sampleCount = 0;
  }
};

struct HourlyAccumulator {
  double phSum = 0.0;
  double tdsSum = 0.0;
  double temperatureSum = 0.0;
  float phMin = 0.0F;
  float phMax = 0.0F;
  float tdsMin = 0.0F;
  float tdsMax = 0.0F;
  float temperatureMin = 0.0F;
  float temperatureMax = 0.0F;
  uint16_t sampleCount = 0;
  String dateKey;
  String hourKey;

  void start(const String &date, const String &hour) {
    phSum = 0.0;
    tdsSum = 0.0;
    temperatureSum = 0.0;
    sampleCount = 0;
    dateKey = date;
    hourKey = hour;
  }

  void add(float ph, float tds, float temperature) {
    if (sampleCount == 0) {
      phMin = phMax = ph;
      tdsMin = tdsMax = tds;
      temperatureMin = temperatureMax = temperature;
    } else {
      phMin = min(phMin, ph);
      phMax = max(phMax, ph);
      tdsMin = min(tdsMin, tds);
      tdsMax = max(tdsMax, tds);
      temperatureMin = min(temperatureMin, temperature);
      temperatureMax = max(temperatureMax, temperature);
    }

    phSum += ph;
    tdsSum += tds;
    temperatureSum += temperature;
    sampleCount++;
  }
};

SensorReading latestReading;
RawAccumulator rawAccumulator;
HourlyAccumulator hourlyAccumulator;
WaterEvaluation latestEvaluation;
WaterStatusMonitor statusMonitor;
AlertManager alertManager;
DisplayManager displayManager;

bool hasSensorReading = false;
bool ntpWaitReported = false;
unsigned long lastSensorMs = 0;
unsigned long lastLatestMs = 0;
unsigned long rawWindowStartedMs = 0;
unsigned long lastRawAttemptMs = 0;

void connectWiFi() {
  WiFi.begin("Wokwi-GUEST", "");

  Serial.print("Connecting WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(300);
    Serial.print(".");
  }

  Serial.println();
  Serial.println("WiFi connected");
}

float readPH() {
  const int raw = analogRead(PinConfig::PIN_PH);

  // Simulasi existing: ADC 0-4095 -> pH 6-9.
  return 6.0F + (static_cast<float>(raw) / 4095.0F) * 3.0F;
}

float readTDS() {
  const int raw = analogRead(PinConfig::PIN_TDS);

  // Simulasi existing: ADC 0-4095 -> 200-600 ppm.
  return 200.0F + (static_cast<float>(raw) / 4095.0F) * 400.0F;
}

float readTemperature() {
  tempSensor.requestTemperatures();
  return tempSensor.getTempCByIndex(0);
}

void readSensors() {
  SensorReading reading;
  reading.ph = readPH();
  reading.tds = readTDS();
  reading.temperature = readTemperature();
  reading.phValid = isfinite(reading.ph);
  reading.tdsValid = isfinite(reading.tds);
  reading.temperatureValid =
      isfinite(reading.temperature) &&
      reading.temperature != DEVICE_DISCONNECTED_C &&
      reading.temperature >= -55.0F && reading.temperature <= 125.0F;

  latestReading = reading;
  hasSensorReading = true;
  if (latestReading.allValid()) {
    rawAccumulator.add(latestReading);
  }

  const WaterStatus previousSystemStatus = latestEvaluation.systemStatus;
  latestEvaluation = statusMonitor.update(latestReading);

  Serial.print("[SENSOR] pH=");
  latestReading.phValid ? Serial.printf("%.2f", latestReading.ph)
                        : Serial.print("ERR");
  Serial.print(" TDS=");
  latestReading.tdsValid ? Serial.printf("%.1f", latestReading.tds)
                         : Serial.print("ERR");
  Serial.print(" TEMP=");
  latestReading.temperatureValid
      ? Serial.printf("%.1f\n", latestReading.temperature)
      : Serial.println("ERR");
  Serial.printf("[STATUS] PH=%s TDS=%s TEMP=%s SYSTEM=%s\n",
                waterStatusName(latestEvaluation.phStatus),
                waterStatusName(latestEvaluation.tdsStatus),
                waterStatusName(latestEvaluation.temperatureStatus),
                waterStatusName(latestEvaluation.systemStatus));

  if (latestEvaluation.systemStatus != previousSystemStatus) {
    Serial.printf("[ALERT] SYSTEM %s -> %s\n",
                  waterStatusName(previousSystemStatus),
                  waterStatusName(latestEvaluation.systemStatus));
  }
  alertManager.setStatus(latestEvaluation.systemStatus, millis());
}

bool isClockValid() {
  return time(nullptr) >= MINIMUM_VALID_EPOCH;
}

String getDateKey(time_t timestamp) {
  struct tm localTime;
  localtime_r(&timestamp, &localTime);

  char buffer[11];
  strftime(buffer, sizeof(buffer), "%Y-%m-%d", &localTime);
  return String(buffer);
}

String getHourKey(time_t timestamp) {
  struct tm localTime;
  localtime_r(&timestamp, &localTime);

  char buffer[3];
  strftime(buffer, sizeof(buffer), "%H", &localTime);
  return String(buffer);
}

String epochMillisecondsKey(time_t timestamp) {
  char buffer[24];
  snprintf(buffer, sizeof(buffer), "%llu",
           static_cast<unsigned long long>(timestamp) * 1000ULL);
  return String(buffer);
}

int firebasePut(const String &url, const String &payload) {
  if (WiFi.status() != WL_CONNECTED) {
    return -1;
  }

  WiFiClientSecure client;
  client.setInsecure();

  HTTPClient http;
  if (!http.begin(client, url)) {
    return -1;
  }

  http.addHeader("Content-Type", "application/json");
  const int statusCode = http.PUT(payload);
  http.end();
  return statusCode;
}

bool isHttpSuccess(int statusCode) {
  return statusCode >= 200 && statusCode < 300;
}

String buildLatestPayload(const SensorReading &reading) {
  String payload;
  payload.reserve(128);
  payload = "{\"ph\":" + String(reading.ph, 2);
  payload += ",\"tds\":" + String(reading.tds, 2);
  payload += ",\"temperature\":" + String(reading.temperature, 2);
  payload += ",\"timestamp\":{\".sv\":\"timestamp\"}}";
  return payload;
}

void updateLatest() {
  const int statusCode =
      firebasePut(String(FIREBASE_LATEST), buildLatestPayload(latestReading));
  Serial.printf("[LATEST] HTTP %d\n", statusCode);
}

bool saveHourlyHistory() {
  if (hourlyAccumulator.sampleCount == 0) {
    return true;
  }

  const float count = static_cast<float>(hourlyAccumulator.sampleCount);
  String payload;
  payload.reserve(320);
  payload = "{\"ph_avg\":" + String(hourlyAccumulator.phSum / count, 2);
  payload += ",\"ph_min\":" + String(hourlyAccumulator.phMin, 2);
  payload += ",\"ph_max\":" + String(hourlyAccumulator.phMax, 2);
  payload +=
      ",\"tds_avg\":" + String(hourlyAccumulator.tdsSum / count, 2);
  payload += ",\"tds_min\":" + String(hourlyAccumulator.tdsMin, 2);
  payload += ",\"tds_max\":" + String(hourlyAccumulator.tdsMax, 2);
  payload += ",\"temperature_avg\":" +
             String(hourlyAccumulator.temperatureSum / count, 2);
  payload += ",\"temperature_min\":" +
             String(hourlyAccumulator.temperatureMin, 2);
  payload += ",\"temperature_max\":" +
             String(hourlyAccumulator.temperatureMax, 2);
  payload +=
      ",\"sample_count\":" + String(hourlyAccumulator.sampleCount);
  payload += ",\"timestamp\":{\".sv\":\"timestamp\"}}";

  const String url = String(FIREBASE_BASE_URL) +
                     "/devices/oase-01/history_hourly/" +
                     hourlyAccumulator.dateKey + "/" +
                     hourlyAccumulator.hourKey + ".json";
  const int statusCode = firebasePut(url, payload);

  Serial.println("[HOURLY]");
  Serial.printf("date=%s\n", hourlyAccumulator.dateKey.c_str());
  Serial.printf("hour=%s\n", hourlyAccumulator.hourKey.c_str());
  Serial.printf("samples=%u\n", hourlyAccumulator.sampleCount);
  Serial.printf("HTTP %d\n", statusCode);
  return isHttpSuccess(statusCode);
}

bool prepareHourlyBucket(const String &dateKey, const String &hourKey) {
  if (hourlyAccumulator.sampleCount == 0) {
    hourlyAccumulator.start(dateKey, hourKey);
    return true;
  }

  if (hourlyAccumulator.dateKey == dateKey &&
      hourlyAccumulator.hourKey == hourKey) {
    return true;
  }

  if (!saveHourlyHistory()) {
    return false;
  }

  hourlyAccumulator.start(dateKey, hourKey);
  return true;
}

bool saveRawHistory() {
  if (rawAccumulator.sampleCount == 0 || !isClockValid()) {
    return false;
  }

  const time_t now = time(nullptr);
  const String dateKey = getDateKey(now);
  const String hourKey = getHourKey(now);

  // Tutup bucket jam sebelumnya sebelum memasukkan agregat lima-menit baru.
  if (!prepareHourlyBucket(dateKey, hourKey)) {
    return false;
  }

  const float count = static_cast<float>(rawAccumulator.sampleCount);
  const float phAverage = rawAccumulator.phSum / count;
  const float tdsAverage = rawAccumulator.tdsSum / count;
  const float temperatureAverage = rawAccumulator.temperatureSum / count;

  String payload;
  payload.reserve(192);
  payload = "{\"ph\":" + String(phAverage, 2);
  payload += ",\"tds\":" + String(tdsAverage, 2);
  payload += ",\"temperature\":" + String(temperatureAverage, 2);
  payload += ",\"sample_count\":" + String(rawAccumulator.sampleCount);
  payload += ",\"timestamp\":{\".sv\":\"timestamp\"}}";

  const String url = String(FIREBASE_BASE_URL) +
                     "/devices/oase-01/history_raw/" + dateKey + "/" +
                     epochMillisecondsKey(now) + ".json";
  const int statusCode = firebasePut(url, payload);

  Serial.println("[RAW HISTORY]");
  Serial.printf("date=%s\n", dateKey.c_str());
  Serial.printf("samples=%lu\n",
                static_cast<unsigned long>(rawAccumulator.sampleCount));
  Serial.printf("HTTP %d\n", statusCode);

  if (!isHttpSuccess(statusCode)) {
    return false;
  }

  // Hourly memakai satu titik per hasil agregasi lima-menit, bukan sample 10 detik.
  hourlyAccumulator.add(phAverage, tdsAverage, temperatureAverage);
  rawAccumulator.reset();
  return true;
}

void handleRawHistorySchedule(unsigned long now) {
  if (now - rawWindowStartedMs < RAW_HISTORY_INTERVAL_MS) {
    return;
  }

  if (!isClockValid()) {
    if (!ntpWaitReported) {
      Serial.println("[RAW HISTORY] waiting for NTP sync");
      ntpWaitReported = true;
    }
    return;
  }

  ntpWaitReported = false;

  // Jika REST gagal, retry maksimal satu kali per interval pembacaan sensor.
  if (lastRawAttemptMs != 0 &&
      now - lastRawAttemptMs < SENSOR_INTERVAL_MS) {
    return;
  }

  lastRawAttemptMs = now;
  if (saveRawHistory()) {
    rawWindowStartedMs = now;
  }
}

void setup() {
  Serial.begin(115200);
  analogReadResolution(12);
  tempSensor.begin();
  alertManager.begin();
  displayManager.begin();

  connectWiFi();
  configTime(GMT_OFFSET_SECONDS, DAYLIGHT_OFFSET_SECONDS, "pool.ntp.org",
             "time.google.com");

  const unsigned long now = millis();
  lastSensorMs = now - SENSOR_INTERVAL_MS;
  lastLatestMs = now - LATEST_INTERVAL_MS;
  rawWindowStartedMs = now;
}

void loop() {
  const unsigned long now = millis();

  alertManager.update(now);
  if (hasSensorReading) {
    displayManager.update(latestReading, latestEvaluation, now);
  }

  // Simpan window lama sebelum sample pada batas 5 menit masuk ke window baru.
  handleRawHistorySchedule(now);

  if (now - lastSensorMs >= SENSOR_INTERVAL_MS) {
    lastSensorMs = now;
    readSensors();
  }

  if (hasSensorReading && latestReading.allValid() &&
      now - lastLatestMs >= LATEST_INTERVAL_MS) {
    lastLatestMs = now;
    updateLatest();
  }
}
