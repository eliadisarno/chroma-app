# Chroma — Color Matching App for Colorblind Users

An iOS application designed to help people with color blindness
match their clothing colors and express themselves freely.
Developed during the **Apple iOS Foundation Program** (Oct–Nov 2025).

---

## The Problem

People affected by color blindness often struggle with choosing
matching outfits, leading to a sense of inadequacy in daily life.
Chroma acts as a personal style assistant: point the camera at two
garments, and the app tells you how well they match — and why.

---

## How It Works

1. Open the app and tap the pulsing Chroma button
2. Take a photo of the first item (or pick from gallery)
3. Take a photo of the second item (or pick from gallery)
4. Chroma analyzes both images and returns:
   - The dominant color of each garment
   - A **matching percentage** based on color theory
5. Save the outfit to your personal Wardrobe

---

## Color Analysis Algorithm

The core of the app lives in `ColorAnalysisView.swift` and works in three stages:

### 1. Central Pixel Sampling
Instead of analyzing the entire image, Chroma crops a **50×50 pixel region**
from the exact center of each photo. This targets the main subject and ignores
background noise.
```swift
let sampleSize: Int = 50
let rect = CGRect(x: (width / 2) - 25, y: (height / 2) - 25, width: 50, height: 50)
```

### 2. Average Color Extraction (CoreImage)
The cropped region is processed using Apple's `CIAreaAverage` filter,
which renders the entire area into a single representative pixel — the
mathematical average of all RGB values in that zone.

### 3. Color Classification (RGB + HSB)
The average color is classified using a two-step approach:

- **Primary pass:** Direct RGB channel dominance check
  (e.g. if `R > G + 30` and `R > B + 30` → RED)
- **Neutral detection:** Brightness average and saturation delta
  to identify WHITE, GRAY, and BLACK
- **Fallback:** Euclidean distance in RGB space against a
  reference palette (RED, BLUE, GREEN, ORANGE, YELLOW, PURPLE, BROWN)

### 4. Match Percentage (Color Theory)
The matching score is calculated using **HSB hue distance** on the color wheel:

| Rule | Hue Distance | Score |
|---|---|---|
| Both neutrals (white/black/gray) | — | 100% |
| One neutral | — | 95% |
| Monochromatic / Analogous | 0° – 30° | 90% |
| Complementary | 150° – 180° | 85% |
| Triadic | 105° – 135° | 80% |
| High brightness contrast | Δbrightness > 0.20 | 65% |
| Clashing (mid-range hues) | 30° – 105° | 45% |

---

## Tech Stack

- **Language:** Swift 5
- **UI Framework:** SwiftUI
- **Camera:** AVFoundation (`AVCaptureSession`, `AVCapturePhotoOutput`)
- **Image Processing:** CoreImage (`CIAreaAverage` filter)
- **Gallery:** PhotosUI (`PHPickerViewController`)
- **Persistence:** `UserDefaults` (JSON-encoded outfit metadata) + `FileManager` (JPEG images)

---

## App Structure

| File | Role |
|---|---|
| `MainView.swift` | Root view, tab navigation, outfit persistence logic |
| `ContentView.swift` | Home screen with animated Chroma button |
| `CustomCameraView.swift` | Two-shot camera flow, flash, pinch-to-zoom |
| `CameraService.swift` | `AVCaptureSession` management, `ObservableObject` |
| `CameraPreview.swift` | `UIViewRepresentable` bridge for live camera feed |
| `ColorAnalysisView.swift` | Color extraction, classification, match scoring |
| `GalleryPickerView.swift` | `PHPickerViewController` wrapper for gallery import |
| `GuardarobaView.swift` | Saved outfits list, rename, delete |

---

## Features

- Custom camera with pinch-to-zoom and flash toggle (off/on/auto)
- Gallery import as alternative to camera
- Red crosshair viewfinder showing the exact sampled area
- Async color analysis on background thread (no UI freeze)
- Wardrobe with saved outfits, rename and delete support
- Full offline — no network requests, no external APIs

---

## Certificate

Apple iOS Foundation Program — Training Certificate, November 2025
