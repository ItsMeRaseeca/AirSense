# AirSense

### IoT-Based Air Quality Monitoring System

AirSense is a low-cost IoT-based environmental monitoring system that combines an ESP32, MQ135 gas sensor, DHT22 temperature/humidity sensor, local display indicators, ThingSpeak cloud monitoring, and a Flutter mobile application.

The system continuously collects environmental readings, processes the MQ135 sensor signal to provide a simple NORMAL/POOR air-quality classification, displays information locally, and uploads the measurements to ThingSpeak for remote monitoring and historical visualization.

The Flutter application, **AirSense**, acts as the mobile monitoring layer for the system.

---

## Overview

AirSense follows this architecture:

```text
             AIR ENVIRONMENT
                    │
          ┌─────────┴─────────┐
          │                   │
        MQ135               DHT22
     Gas response      Temperature/Humidity
          │                   │
          └─────────┬─────────┘
                    ↓
                  ESP32
                    │
          ┌─────────┼─────────┐
          │         │         │
        LCD       LEDs      Wi-Fi
          │                   │
          │                   ↓
          │              ThingSpeak
          │                   │
          │                   ↓
          │             Cloud Data
          │                   │
          └───────────────────┘
                              ↓
                         Flutter App
                          (AirSense)
```

---

## Key Features

### Hardware Monitoring
- MQ135-based general air-quality/gas sensing
- DHT22 temperature measurement
- DHT22 humidity measurement
- 16×2 I²C LCD for local monitoring
- Green LED for NORMAL air-quality status
- Red LED for POOR air-quality status
- ESP32 as the main controller

### Cloud Monitoring
Sensor data is uploaded to ThingSpeak through Wi-Fi.

The current ThingSpeak fields are:

| Field | Data |
|---|---|
| Field 1 | Temperature (°C) |
| Field 2 | Humidity (%) |
| Field 3 | MQ135 Raw ADC |
| Field 4 | Air-quality status (0 = NORMAL, 1 = POOR) |

### Flutter Mobile Application
The AirSense mobile application provides:
- Live sensor dashboard
- Temperature and humidity monitoring
- MQ135 raw reading
- NORMAL/POOR status
- Automatic data refresh & manual pull-to-refresh
- Historical charts
- Monitoring location
- Today's PDF report generation (save & share)
- Optional Gemini-powered explanation of sensor readings
- No login or signup required

---

## Air-Quality Classification

The MQ135 is used in this project as a broad-spectrum gas/air-quality indicator.

The sensor produces an analog response which is read by the ESP32 ADC.

The current prototype uses the following application-level threshold:

```text
MQ135 Raw < 2000  ──►  NORMAL (0)
MQ135 Raw >= 2000 ──►  POOR (1)
```

The ESP32 determines this status and sends the result to ThingSpeak.

> ⚠️ **Important Limitation**  
> The value 2000 is a project-specific raw ADC threshold.  
> It is **not** an official AQI threshold, **not** a ppm value, and **not** a calibrated pollutant concentration.  
> Likewise, the MQ135 raw reading displayed by the system should not be interpreted as AQI or ppm.  
> This project is intended as a prototype for threshold-based relative air-quality indication rather than a laboratory-grade pollution monitoring instrument.

---

## Sensors

### MQ135
The MQ135 is a broad-spectrum semiconductor gas sensor that responds to multiple gases associated with air pollution. It is not a selective analyzer for one specific gas. In AirSense, the MQ135 provides the primary air-quality signal used for the prototype's NORMAL/POOR classification.

### DHT22
The DHT22 provides:
- Temperature
- Relative humidity

The DHT22 is monitored alongside the MQ135 to provide environmental context. In the current implementation, temperature and humidity do not directly determine the NORMAL/POOR classification.

---

## Hardware Setup

### Main Components
- ESP32 Dev Module
- MQ135 Gas Sensor Module
- DHT22 Temperature/Humidity Sensor
- 16×2 I²C LCD (Address `0x27`)
- Green LED
- Red LED
- Resistors (for LEDs and voltage divider)
- Breadboard & Jumper wires

### ESP32 Pin Configuration

| Component | ESP32 Pin |
|---|---|
| DHT22 Data | GPIO 4 |
| Green LED | GPIO 18 |
| Red LED | GPIO 19 |
| MQ135 Analog Output | GPIO 34 (via voltage divider) |
| LCD SDA | GPIO 21 |
| LCD SCL | GPIO 22 |

*LCD I²C address: `0x27`*

The MQ135 digital output is not used.  
The MQ135 analog output is connected to GPIO34 through a voltage divider to reduce the sensor output voltage before it reaches the ESP32 ADC input.

### Local Output
Air quality is indicated physically through LEDs:
- **NORMAL**: Green LED blinking / ON
- **POOR**: Red LED ON, Green LED OFF

The 16×2 I²C LCD displays environmental measurements and air-quality status locally.

---

## Software Stack

### Embedded System
- Arduino IDE / C++
- ESP32

### Mobile Application
- Flutter / Dart
- Dependencies: `http`, `fl_chart`, `pdf`, `printing`, `geolocator`, `geocoding`, `flutter_map`, `latlong2`

### Cloud & AI
- ThingSpeak REST API
- Google Gemini API (`gemini-2.5-flash`)

---

## System Workflow

```text
1. MQ135 & DHT22 collect environmental data
                    ↓
2. ESP32 reads the sensors
                    ↓
3. ESP32 classifies MQ135 status (< 2000: NORMAL, >= 2000: POOR)
                    ↓
4. LCD and LEDs provide local feedback
                    ↓
5. ESP32 connects via Wi-Fi
                    ↓
6. Sensor data uploaded to ThingSpeak
                    ↓
7. ThingSpeak stores time-series data
                    ↓
8. AirSense Flutter app reads cloud data
                    ↓
9. User views live metrics & historical charts
                    ↓
10. User can generate PDF reports or request Gemini AI explanations
```

---

## Project Structure

```text
AirSense/
│
├── README.md
├── .gitignore
├── esp32/
│   └── airsense_esp32.ino
│
├── lib/
│   ├── config/
│   │   └── app_config.dart
│   ├── models/
│   │   └── sensor_data.dart
│   ├── screens/
│   │   ├── dashboard_screen.dart
│   │   ├── history_screen.dart
│   │   └── about_screen.dart
│   ├── services/
│   │   ├── thingspeak_service.dart
│   │   ├── location_service.dart
│   │   ├── pdf_report_service.dart
│   │   └── gemini_service.dart
│   ├── theme/
│   │   └── app_theme.dart
│   ├── widgets/
│   │   ├── air_quality_card.dart
│   │   ├── chart_card.dart
│   │   ├── connection_status.dart
│   │   ├── gemini_explanation_sheet.dart
│   │   ├── location_card.dart
│   │   └── sensor_card.dart
│   └── main.dart
│
├── android/
├── pubspec.yaml
└── test/
```

---

## Running the Application

### Running the Flutter App

1. Install Flutter and configure the Android SDK.
2. Get dependencies:
   ```bash
   flutter pub get
   ```
3. Run on a connected device:
   ```bash
   flutter run
   ```

To build a standalone APK:
```bash
flutter build apk --release
```

---

## Limitations & Future Scope

### Prototype Limitations
- MQ135 is a broad-spectrum gas sensor and is not selective for one specific pollutant.
- The NORMAL/POOR threshold is an application-level raw ADC threshold (`2000`).
- The MQ135 raw reading is not equivalent to AQI or ppm.
- Mobile location feature represents the monitoring phone's location when permission is granted; the ESP32 itself has no GPS hardware.

### Future Scope
- Proper MQ135 calibration and pollutant-specific sensors.
- Additional environmental sensors (PM2.5, CO2).
- Mobile push notifications for status changes.
- Dedicated backend for secure AI proxy integration.

---

## Authors

**Raseeca Kashelkar • Shreya Shukla • Divya Patil**

**Project**: AirSense — IoT-Based Air Quality Monitoring System  
**GitHub Repository**: [https://github.com/ItsMeRaseeca/AirSense](https://github.com/ItsMeRaseeca/AirSense)
