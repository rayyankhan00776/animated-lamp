# Animated Lamp

An animated lamp UI made in Flutter with a string switch to pull for on and off functionality.

## Features

- 🎨 Beautiful animated lamp UI with smooth transitions
- 💡 Interactive pull string switch for on/off control
- ✨ Realistic glow effects when the lamp is turned on
- 🎭 Smooth animations and visual feedback
- 📱 Responsive design that works on different screen sizes

## How to Use

1. **Pull the String**: Click and drag down on the string handle to pull it
2. **Toggle the Lamp**: Pull the string far enough (drag down) and release to toggle the lamp on or off
3. **Visual Feedback**: The lamp will glow with a warm amber light when turned on

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK

### Installation

1. Clone the repository:
```bash
git clone https://github.com/rayyankhan00776/animated-lamp.git
cd animated-lamp
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Project Structure

```
animated-lamp/
├── lib/
│   └── main.dart          # Main application file with lamp UI
├── pubspec.yaml           # Project dependencies
├── analysis_options.yaml  # Dart/Flutter linting rules
└── README.md             # This file
```

## Technical Details

- **Framework**: Flutter
- **Language**: Dart
- **Animation**: Custom animations using AnimationController
- **UI Components**: Custom painted widgets with gesture detection
- **State Management**: StatefulWidget with setState

## Features Implemented

- Pull string gesture detection (vertical drag)
- Smooth glow animations using AnimationController
- Dynamic string extension based on drag distance
- Color transitions for lamp state changes
- Background gradient changes based on lamp state
- Realistic light diffusion effects

## License

This project is open source and available under the MIT License.