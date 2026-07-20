# Book Mate

Book Mate is a high-performance cross-platform mobile application that provides a reading experience similar to iBooks or Google Books for PDF documents. It focuses on fluid, realistic animations and reader-centric customization features.

## Features

- **Bookshelf Interface**: A grid view to manage and select imported PDF files.
- **Interactive Reader Screen**: A viewer that renders PDFs with support for swipe-based page-flip gestures.
- **Theme Management**: Global switching between premium light and dark modes.
- **Color Adaptation**: Dynamic color inversion of PDF pages in dark mode to improve readability (dark text becomes light on dark backgrounds).

## Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: `provider`
- **PDF Rendering**: `pdfx`
- **File Access**: `file_picker`

## Getting Started

### Prerequisites

- Flutter SDK (version 3.0.0 or higher)
- Dart SDK

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/Siddhesh-Birewar/Book-Mate.git
   ```
2. Navigate to the project directory:
   ```bash
   cd Book-Mate
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```

### Running the App

To run the application on an emulator or a connected device, use:

```bash
flutter run
```

*Note for macOS developers: This app uses `file_picker`, which requires specific macOS entitlements (already configured in this project) for accessing the file system and network (needed for `pdfx` web workers on macOS).*
