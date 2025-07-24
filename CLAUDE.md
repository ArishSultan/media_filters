# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter plugin called `media_filters` that applies filters on visual media using hardware acceleration. It provides video preview capabilities with real-time filter application for both iOS and Android platforms.

## Development Commands

### Flutter Commands
- `flutter pub get` - Install dependencies
- `flutter test` - Run Dart tests
- `flutter analyze` - Run static analysis

### iOS Development
- `cd ios && swift build` - Build iOS Swift package
- `pod lib lint media_filters.podspec` - Validate podspec before publishing
- iOS minimum version: 13.0

### Android Development  
- `cd android && ./gradlew test` - Run Android unit tests
- `cd android && ./gradlew build` - Build Android module
- Android minimum SDK: 21, compile SDK: 36

### Example App
- `cd example && flutter run` - Run the example app
- `cd example && flutter build ios` - Build example for iOS
- `cd example && flutter build android` - Build example for Android

## Architecture

### Core Components

**Flutter Layer (Dart)**
- `VideoPreviewController`: Main controller that manages video playback and filter application
- `VideoPreview`: Flutter widget that embeds native platform views
- Platform-specific APIs: `VideoPreviewDarwinApi` (iOS) and `VideoPreviewAndroidApi` (Android)

**iOS Native Layer (Swift)**
- `MediaFiltersPlugin`: Flutter plugin registration
- `VideoPreviewManager`: Singleton managing multiple preview instances
- `VideoPreview`: Core video player with filter support using SwiftCube library
- `ViewPreviewViewFactory`: Creates native iOS views for Flutter integration
- C FFI interface: Functions prefixed with `vp` for cross-language communication

**Android Native Layer (Kotlin)**
- `MediaFiltersPlugin`: Basic Flutter plugin stub (minimal implementation)

### Key Dependencies
- iOS: SwiftCube library for video processing and filters
- Flutter: `ffi` package for native interop, `plugin_platform_interface` for platform abstraction

### Platform View Integration
- Uses Flutter's platform view system (`UiKitView` for iOS, `AndroidView` for Android)
- View type identifier: `"media_filters.preview"`
- Controller binding happens via `onPlatformViewCreated` callback

### State Management
- Real-time state callbacks for playback state, progress, and duration
- Stream-based API for reactive UI updates
- Thread-safe preview management with locks on iOS

## Important Notes

- The README.md file appears to be empty or minimal
- iOS implementation is more complete than Android (which is mostly a stub)
- The plugin uses FFI for iOS native communication
- Swift package uses SwiftCube for video processing capabilities
- Privacy manifest support is prepared but commented out in build files