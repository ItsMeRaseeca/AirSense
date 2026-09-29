/*
 * AirSense - IoT-Based Air Quality Monitoring System
 * Firmware for ESP32 Dev Module
 *
 * Hardware Pinout:
 *   - DHT22 DATA:              GPIO 4
 *   - Green LED (NORMAL):      GPIO 18
 *   - Red LED (POOR):          GPIO 19
 *   - MQ135 AO:                GPIO 34 (via voltage divider)
 *   - I2C LCD SDA:             GPIO 21
 *   - I2C LCD SCL:             GPIO 22
 *   - LCD I2C Address:         0x27
 *
 * Cloud Integration:
 *   - ThingSpeak Channel ID:   3513305
 *   - Field 1: Temperature (°C)
 *   - Field 2: Humidity (%)
 *   - Field 3: MQ135 Raw ADC
 *   - Field 4: Air Quality Status (0 = NORMAL, 1 = POOR)
 */

#include <WiFi.h>
#include <HTTPClient.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <DHT.h>

// ── Wi-Fi & ThingSpeak Credentials (Replace with your actual credentials) ────
const char* WIFI_SSID     = "YOUR_WIFI_SSID";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";

const char* THINGSPEAK_SERVER        = "api.thingspeak.com";
const char* THINGSPEAK_WRITE_API_KEY = "YOUR_THINGSPEAK_WRITE_API_KEY";

// ── Pin Definitions ──────────────────────────────────────────────────────────
#define DHT_PIN       4
#define DHT_TYPE      DHT22

#define GREEN_LED_PIN 18
#define RED_LED_PIN   19
#define MQ135_ADC_PIN 34

// ── Thresholds ───────────────────────────────────────────────────────────────
// Application-level raw ADC threshold for prototype classification
// < 2000 => NORMAL (0), >= 2000 => POOR (1)
const int MQ135_POOR_THRESHOLD = 2000;

// ── Peripherals Initialization ───────────────────────────────────────────────
DHT dht(DHT_PIN, DHT_TYPE);
LiquidCrystal_I2C lcd(0x27, 16, 2);

unsigned long lastUploadTime = 0;
const unsigned long UPLOAD_INTERVAL_MS = 20000; // Upload every 20s

void setup() {
  Serial.begin(115200);

  // Initialize LEDs
  pinMode(GREEN_LED_PIN, OUTPUT);
  pinMode(RED_LED_PIN, OUTPUT);
  digitalWrite(GREEN_LED_PIN, LOW);
  digitalWrite(RED_LED_PIN, LOW);

  // Initialize Sensors & Display
  dht.begin();
  Wire.begin(21, 22);
  lcd.init();
  lcd.backlight();

  lcd.setCursor(0, 0);
  lcd.print("AirSense Init...");

  // Connect to Wi-Fi
  Serial.print("Connecting to Wi-Fi: ");
  Serial.println(WIFI_SSID);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  int retries = 0;
  while (WiFi.status() != WL_CONNECTED && retries < 20) {
    delay(500);
    Serial.print(".");
    retries++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWi-Fi Connected!");
    lcd.setCursor(0, 1);
    lcd.print("Wi-Fi Connected");
  } else {
    Serial.println("\nWi-Fi Connection Failed (Offline Mode)");
    lcd.setCursor(0, 1);
    lcd.print("Wi-Fi Offline");
  }
  delay(1500);
  lcd.clear();
}

void loop() {
  // Read Sensors
  float temperature = dht.readTemperature();
  float humidity    = dht.readHumidity();
  int mq135Raw      = analogRead(MQ135_ADC_PIN);

  // Handle sensor reading failures
  if (isnan(temperature)) temperature = 0.0;
  if (isnan(humidity))    humidity = 0.0;

  // Air Quality Classification (0 = NORMAL, 1 = POOR)
  int airStatus = (mq135Raw >= MQ135_POOR_THRESHOLD) ? 1 : 0;
  bool isPoor = (airStatus == 1);

  // Update Physical LED Indicators
  if (isPoor) {
    digitalWrite(RED_LED_PIN, HIGH);
    digitalWrite(GREEN_LED_PIN, LOW);
  } else {
    digitalWrite(RED_LED_PIN, LOW);
    // Green LED blinking indicator for NORMAL status
    digitalWrite(GREEN_LED_PIN, (millis() / 500) % 2 == 0 ? HIGH : LOW);
  }

  // Update LCD Display
  lcd.setCursor(0, 0);
  lcd.print("T:");
  lcd.print((int)temperature);
  lcd.print("C H:");
  lcd.print((int)humidity);
  lcd.print("%    ");

  lcd.setCursor(0, 1);
  lcd.print("MQ:");
  lcd.print(mq135Raw);
  lcd.print(isPoor ? " POOR " : " NORM ");

  // Upload to ThingSpeak at configured interval
  if (millis() - lastUploadTime >= UPLOAD_INTERVAL_MS) {
    lastUploadTime = millis();
    if (WiFi.status() == WL_CONNECTED) {
      uploadToThingSpeak(temperature, humidity, mq135Raw, airStatus);
    }
  }

  delay(200);
}

void uploadToThingSpeak(float temp, float hum, int mqRaw, int status) {
  HTTPClient http;
  String url = "http://" + String(THINGSPEAK_SERVER) + "/update?api_key=" + String(THINGSPEAK_WRITE_API_KEY) +
               "&field1=" + String(temp, 1) +
               "&field2=" + String(hum, 1) +
               "&field3=" + String(mqRaw) +
               "&field4=" + String(status);

  http.begin(url);
  int httpCode = http.GET();
  if (httpCode > 0) {
    Serial.printf("ThingSpeak Upload OK (Response Code: %d)\n", httpCode);
  } else {
    Serial.printf("ThingSpeak Upload Failed: %s\n", http.errorToString(httpCode).c_str());
  }
  http.end();
}
