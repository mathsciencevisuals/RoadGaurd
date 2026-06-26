# RoadGuard

RoadGuard is a Flutter-based driver-assistance mobile app focused on real-time road hazard awareness. It combines camera input, GPS, motion sensors, local persistence, on-device inference scaffolding, and backend synchronization to help surface potholes, road humps, pedestrians, vehicles, and other road risks.

## Project Overview

RoadGuard is designed to:

- detect and classify road hazards from the device camera
- combine visual detections with GPS and motion signals
- estimate risk and proximity for driver-facing alerts
- store hazard events locally for offline-first behavior
- synchronize selected hazard data with a backend when connectivity is available
- support future model rollout and version management from the backend

This repository currently contains:

- the Flutter mobile application under `lib/`
- the recommended FastAPI backend under `roadguard_backend/`
- an older backend prototype under `backend/`

## Safety Disclaimer

RoadGuard is a driver-assistance app, not an autonomous driving system.

The driver remains fully responsible for road awareness, safe decision-making, steering, braking, and vehicle control at all times. RoadGuard must not be treated as a substitute for active attention, legal driving obligations, or safe driving judgment.

## Architecture Diagram

```text
                   +----------------------------------+
                   |          RoadGuard App           |
                   |         Flutter / Dart           |
                   +----------------------------------+
                        |           |            |
                        |           |            |
                        v           v            v
               +-------------+ +---------+ +-----------+
               |   Camera    | |   GPS   | |  Motion   |
               |   frames    | | coords  | | sensors   |
               +-------------+ +---------+ +-----------+
                        \           |            /
                         \          |           /
                          v         v          v
                   +----------------------------------+
                   |   Detection / Inference Layer    |
                   | TFLite + tracking + fusion hooks |
                   +----------------------------------+
                            |                 |
                            |                 |
                            v                 v
                 +------------------+   +------------------+
                 |   Risk Engine    |   |  Alert Engine    |
                 | scoring/priority |   | voice/vibration  |
                 +------------------+   +------------------+
                            |
                            v
                 +--------------------------+
                 | Local Storage (Hive)     |
                 | hazards + trip events    |
                 +--------------------------+
                            |
                            v
                 +--------------------------+
                 | Networking / Sync Layer  |
                 | Dio + FastAPI backend    |
                 +--------------------------+
                            |
                            v
                 +--------------------------+
                 | PostgreSQL / Model APIs  |
                 | hazards + devices/models |
                 +--------------------------+
```

## Flutter Setup

### Prerequisites

- Flutter SDK 3.22 or newer
- matching Dart SDK from the selected Flutter release
- Android Studio or VS Code with Flutter tooling
- Xcode 15 or newer for iOS development
- CocoaPods for iOS dependency installation

### Install dependencies

```bash
flutter pub get
```

### Generate missing platform folders

This workspace currently may not include generated `android/` and `ios/` folders. If they are missing, generate them before running the app:

```bash
flutter create .
```

## Android Setup

1. Install Android Studio and the Android SDK.
2. Accept Android licenses:

```bash
flutter doctor --android-licenses
```

3. Create or start an emulator, or connect a physical Android device.
4. Configure Google Maps, camera, location, notifications, and sensor permissions in the generated Android project before release builds.
5. Verify the app’s minimum SDK and plugin compatibility after `flutter pub get`.

## iOS Setup

1. Install Xcode and Xcode command-line tools.
2. Install CocoaPods if needed:

```bash
sudo gem install cocoapods
```

3. Install iOS pods:

```bash
cd ios
pod install
cd ..
```

4. Open `ios/Runner.xcworkspace` in Xcode for signing, capabilities, and runtime validation.
5. Add the required location, camera, and notification usage descriptions to `Info.plist`.
6. Configure the Google Maps iOS key once the platform project exists.

## Required Permissions

RoadGuard currently requires:

- Camera
  Used for live road detection and visual hazard recognition.
- Location
  Used for GPS hazard tagging, hazard map placement, current speed context, and manual reporting.
- Notifications
  Used for future background or system-level safety alerts.
- Motion sensors where supported
  Used for acceleration and movement context, including hump and bump confirmation logic.

RoadGuard should not request microphone permission for the current feature set.

## AI Model Asset Placement

Place on-device model assets under `assets/models/`.

Expected structure:

```text
assets/
  models/
    roadguard_object_detection.tflite
    labels.txt
```

Ensure the assets are registered in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/models/
```

The current code expects:

- `assets/models/roadguard_object_detection.tflite`
- `assets/models/labels.txt`

The checked-in `.tflite` file may still be a placeholder until a real model binary is supplied.

## Running the App

After installing dependencies and generating the platform folders:

```bash
flutter run
```

To target a specific device:

```bash
flutter devices
flutter run -d <device_id>
```

To point the app at a specific backend URL:

```bash
flutter run --dart-define=ROADGUARD_API_BASE_URL=http://10.0.2.2:8000
```

## Testing

Run static analysis and unit tests:

```bash
flutter analyze
flutter test
```

The repository already includes deterministic unit-test coverage for:

- `RiskEngine`
- `AlertThrottleService`
- `AlertEngine` low-risk voice suppression
- `BoundingBox` helper methods
- `PermissionService` result mapping
- `SettingsController`

These tests do not require a real camera, GPS device, or platform sensor hardware.

When validating backend integration separately:

```bash
cd roadguard_backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

## Folder Structure

```text
lib/
  app.dart
  main.dart
  core/
    config/
    constants/
    errors/
    permissions/
    theme/
    utils/
  features/
    onboarding/
    driver_mode/
    camera_detection/
    hazard_map/
    trip_summary/
    settings/
    shared/
  ai/
    detection/
    inference/
    tracking/
    distance/
    models/
  sensors/
  risk/
  alerts/
  storage/
  networking/

roadguard_backend/
  app/
    core/
    api/
    models/
    schemas/
    services/
```

## Feature Roadmap

1. Generate and finish native Android/iOS platform configuration.
2. Replace placeholder model assets with production TFLite binaries.
3. Complete camera frame pipeline and model-specific preprocessing.
4. Expand sensor fusion for humps, potholes, and contextual risk.
5. Add background sync and sync scheduling.
6. Introduce model rollout, download, and integrity verification.
7. Add moderation, verification, analytics, and trip insights.
8. Add authenticated users, data controls, and release hardening.

## Known Limitations

- Depth is approximate and should not be treated as a precise physical measurement.
- Detection quality depends heavily on phone placement, mounting stability, and camera angle.
- Night driving, rain, fog, glare, and occlusion may reduce accuracy.
- Overtaking detection requires clear camera visibility and stable framing.
- Some flows currently use placeholder inference or placeholder native integrations until real assets and platform code are supplied.

## Backend Integration

The recommended backend lives under `roadguard_backend/` and currently exposes:

- `GET /health`
- `POST /api/hazards`
- `GET /api/hazards/nearby`
- `POST /api/hazards/{hazard_id}/verify`
- `POST /api/hazards/{hazard_id}/false-positive`
- `POST /api/devices/register`
- `GET /api/devices/{device_id}`
- `GET /api/models`
- `POST /api/models`
- `GET /api/models/active`
- `PUT /api/models/{model_id}/activate`

Typical mobile flow:

1. Initialize Hive and local stores.
2. Register the device with the backend when networking is available.
3. Save hazard events locally first.
4. Sync unsynced hazards with the backend using the sync service.
5. Fetch nearby hazards for the map experience.
6. Query active model versions to coordinate model rollout.

## Privacy Notes

- Hazard events should be stored locally first to preserve offline-first behavior.
- Only the minimum necessary data should be uploaded for hazard mapping and product improvement.
- Camera imagery may contain vehicles, license plates, pedestrians, or other sensitive context and should be treated accordingly.
- User-facing consent should clearly explain cloud sync, data sharing, and any future image upload behavior.
- Data retention, deletion, export, and incident response requirements should be defined before production release.
