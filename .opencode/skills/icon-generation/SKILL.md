---
name: icon-generation
description: Generate app launcher icons and UI icon assets for Android Flutter apps with proper sizing and flutter_launcher_icons integration
---

# Icon Generation

Generate app icons (SVG/PNG) and launcher icons for Android Flutter apps.

## When to Use

- Creating app launcher icons
- Generating UI icons for the app
- Setting up flutter_launcher_icons
- Producing platform-ready icon assets

## Android Launcher Icon Sizes (mipmap)

| Density  | Size      |
|----------|-----------|
| mdpi     | 48x48 px  |
| hdpi     | 72x72 px  |
| xhdpi    | 96x96 px  |
| xxhdpi   | 144x144 px|
| xxxhdpi  | 192x192 px|
| Source   | 1024x1024 px (Play Store) |

## File Locations

- **Launcher icons**: `android/app/src/main/res/mipmap-*/ic_launcher.png`
- **Custom UI icons**: `assets/icons/` (register in pubspec.yaml)
- **Source icon**: `assets/icon/app_icon.png`

## Using flutter_launcher_icons

Add to `pubspec.yaml`:

```yaml
flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/icon/app_icon.png"
  adaptive_icon_background: "#2196F3"
  adaptive_icon_foreground: "assets/icon/app_icon.png"
```

Generate icons:
```bash
dart run flutter_launcher_icons
```

## Icon Design Guidelines

- Keep icons simple and legible at 48x48
- Use transparent backgrounds for adaptive icons
- Provide both foreground and background for adaptive icons
- Test at small sizes before finalizing
- Consider dark/light mode variations
- Single-color or two-tone palette works best
- Avoid text, heavy shadows, and photorealism

## UI Icon Guidelines

- Use Flutter's built-in `Icons` class when possible
- For custom icons, use `flutter_svg` package with SVG files
- SVG viewBox: `0 0 24 24` for standard icons
- Keep paths simple for performance
- Provide alt text / semantic labels for accessibility

## Image Generation Prompt Template

```
Create a clean, flat-style app icon for a universal AI chat platform.
- Transparent or solid background (#2196F3)
- Simple two-tone palette: primary #2196F3, secondary #FFFFFF
- Minimalist chat/AI symbol, centered, no text
- Output: PNG 1024x1024 source
- Style: flat, minimal, rounded corners
- Avoid: photorealism, gradients, text, heavy shadows
```
