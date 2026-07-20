# Product Requirements Document (PRD) & Technical Requirements Document (TRD)

## Project: PDF Book Reader Application (Flutter)

---

## 1. Product Requirements Document (PRD)

### 1.1 Overview
The project aims to build a high-performance cross-platform mobile application that provides a reading experience similar to iBooks or Google Books for PDF documents. It focuses on fluid, realistic animations and reader-centric customization features.

### 1.2 User Goals
* **Import**: Users want to import local PDF files into the application.
* **Reading Experience**: Users desire an interface that simulates real-world book reading with page-turning animations.
* **Customization**: Users require support for light and dark themes, including the ability to invert colors for a better reading experience in low light.

### 1.3 Key Features
* **Bookshelf Interface**: A list view to manage and select imported PDF files.
* **Interactive Reader Screen**: A viewer that renders PDFs with support for swipe-based page-flip gestures.
* **Theme Management**: Global switching between light and dark modes.
* **Color Adaptation**: Dynamic color inversion of PDF pages in dark mode to improve readability.

---

## 2. Technical Requirements Document (TRD)

### 2.1 Technology Stack
* **Framework**: Flutter (Dart)
* **State Management**: `Provider` or `Riverpod` for theme toggling.
* **PDF Rendering**: `pdfx` or `syncfusion_flutter_pdfviewer`.
* **Animation**: `flutter_pdf_flipbook` for 3D page-turn physics.
* **File Access**: `file_picker` for local file selection.

### 2.2 System Architecture
The application architecture is structured into four primary layers:
1.  **File Picker**: Manages importing PDF files from device storage.
2.  **PDF Controller**: Handles loading the PDF document into memory.
3.  **View Layer**:
    * **Main Container**: Manages global theme state.
    * **PDF Renderer**: Renders the document canvas.
    * **Filter Layer**: Applies `ColorFiltered` for dynamic dark mode inversion.
    * **Interaction Layer**: Tracks gesture inputs for the `PageFlip` animation.

### 2.3 Implementation Details
* **Theme Switching**: Utilize `ThemeData.light()` and `ThemeData.dark()`. A toggle boolean will trigger a rebuild of the widget tree.
* **Color Inversion**: Since PDFs are static image formats, individual text color cannot be changed. The application will use a `ColorFiltered` widget with a matrix transformation to invert colors dynamically on the rendering layer.
* **Page Turning**: Integrate `flutter_pdf_flipbook` to wrap the PDF rendering. This plugin calculates gesture-based 3D page curls without requiring custom physics implementation.
