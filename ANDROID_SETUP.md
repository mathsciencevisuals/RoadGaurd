# Android Setup Checklist

This repo still does not include committed Android project files. After running:

```bash
flutter create .
```

apply the following Android-specific setup before testing RoadGuard on device.

## 1. Required permissions

Update `android/app/src/main/AndroidManifest.xml` with:

- camera permission
- fine location permission
- coarse location permission
- notification permission for Android 13+
- internet permission

Typical entries:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

RoadGuard should not request microphone permission.

## 2. Google Maps setup

For `google_maps_flutter`, add your Android Maps API key in `AndroidManifest.xml` inside `<application>`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ANDROID_MAPS_API_KEY" />
```

## 3. Minimum Android validation

After the platform project is generated:

1. run `flutter pub get`
2. run `flutter analyze`
3. run `flutter build apk --debug`
4. install the debug APK on a device
5. validate:
   - onboarding permission flow
   - driver mode screen launch
   - hazard map screen launch
   - manual hazard reporting
   - backend connectivity

## 4. Runtime caveats

- the current `.tflite` file is still a placeholder
- camera preview and native plugin setup should be validated on a physical device
- real Google Maps behavior will not work without a valid API key
