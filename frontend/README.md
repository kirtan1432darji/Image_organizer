# 📱 ContextVault - Flutter Mobile App

**Tagline**: *Turn Screenshots into Searchable Knowledge*

A production-ready Flutter mobile application that creates an intelligent organizational layer over screenshots stored on the user's phone.

**Non-Destructive Guarantee**: The app **NEVER moves, edits, duplicates, or deletes original image files** in the device photo library. It reads image metadata, extracts optical text (OCR), and provides intelligent AI-powered categorization and search backed by SQLite and an ASP.NET Core backend.

---

## 🏗 Architecture Overview

The app is built using **Clean Architecture** with **Riverpod 2.x** state management:

```
lib/
├── core/
│   ├── constants/           # API endpoints, DB config, Color palettes
│   ├── theme/               # Material 3 Light & Dark themes (Plus Jakarta Sans)
│   ├── services/            # SQLite DatabaseService, Dio ApiClient, OCR, PhotoManager Scanner
│   ├── utils/               # DateFormatter, FileUtils, Result<T> sealed monad
│   └── widgets/             # ModernCard, ConfidenceBadge, Shimmer, TagChip, AnimatedCounter
├── features/
│   ├── splash/              # Animated branding & initialization
│   ├── onboarding/          # Permission request & privacy guarantees
│   ├── navigation/          # MainScaffold with 4-tab persistent BottomNavigationBar
│   ├── home/                # StatsHeader, RecentCarousel, AICategoryGrid, NeedsReview
│   ├── folders/             # FolderDetailScreen, MasonryGrid, SubcategoryFilterChips
│   ├── screenshot_detail/   # Zoomable preview, OCR text viewer, Tag editor, Re-analyze
│   ├── search/              # Real-time multi-facet search (OCR text, Tags, App)
│   ├── favorites/           # Starred screenshots gallery
│   ├── settings/            # Theme switcher, Backend URL config, Cache purge, Privacy policy
│   └── scanner/             # Scan progress dialog & state notifier
├── models/                  # Immutable models (Screenshot, Category, Tag, OCR, Classification)
├── repositories/            # Clean architecture Repository implementations
├── providers/               # Riverpod StateNotifiers, AsyncNotifiers, FutureProviders
├── routes/                  # Typed GoRouter configuration
└── mock/                    # Rich realistic sample dataset for testing
```

---

## 🎨 UI & Design Highlights

- **Material 3 Design**: Rounded cards, dynamic color highlights, elevation tints.
- **Dark & Light Modes**: System-adaptive theme with custom contrast and typography.
- **4 Core Bottom Tabs**:
  1. 🏠 **Home**: Quick stats, Recent carousel, Needs Review strip, AI categories.
  2. 🔍 **Search**: Instant live search across OCR text snippets and tags.
  3. ❤️ **Favorites**: Bookmarked screenshots in a masonry grid.
  4. ⚙️ **Settings**: Dark mode toggle, ASP.NET Core backend URL, clear cache.
- **Interactive Detail View**: Pinch-to-zoom preview, selectable OCR text card with one-tap copy, AI match score badge, tag manager.

---

## 🔗 ASP.NET Core Backend Integration Contract

The mobile app connects to the ASP.NET Core backend using `Dio` with automatic offline queue fallback:

### 1. Classification Endpoint
- **URL**: `POST /api/screenshots/classify`
- **Request Payload**:
  ```json
  {
    "screenshot_id": "uuid-v4",
    "file_name": "Screenshot_20260830_Apple_Receipt.png",
    "ocr_text": "Apple Inc. Subscription Confirmation: iCloud+ Total: $9.99",
    "existing_category": null
  }
  ```
- **Response**:
  ```json
  {
    "screenshot_id": "uuid-v4",
    "category_id": "receipts",
    "category_name": "Receipts & Invoices",
    "subcategory": "Digital Services",
    "confidence": 0.96,
    "source_app": "Apple Wallet",
    "suggested_tags": ["Tax 2026", "Reimbursement"],
    "summary": "Apple iCloud subscription receipt"
  }
  ```

### 2. Categories Sync
- **URL**: `GET /api/categories`
- **Response**: List of predefined taxonomy categories with colors and icons.

---

## 💾 Local SQLite Database Schema

The app uses an embedded SQLite database (`ai_screenshot_organizer.db`) with tables:
- `screenshots`: Metadata, dimensions, category ID, confidence, sync status.
- `categories`: Category taxonomy, icon names, color hex codes.
- `tags`: Tag dictionary.
- `screenshot_tags`: Many-to-many relationship mapping.
- `ocr_cache`: Stored OCR text blocks to prevent redundant recognition computation.
- `sync_queue`: Queued offline transactions dispatched when network is restored.

---

## 🚀 Getting Started

### 1. Install Dependencies
```bash
cd frontend
flutter pub get
```

### 2. Run the App
```bash
# Android emulator / device
flutter run -d android

# iOS simulator / device
flutter run -d ios

# Web / Desktop preview (uses built-in mock mode)
flutter run -d chrome
```

---

## 🔒 Privacy & Permissions

- **Android**: `READ_MEDIA_IMAGES` / `READ_EXTERNAL_STORAGE`
- **iOS**: `NSPhotoLibraryUsageDescription`
- **Principle**: Only text OCR and metadata are queried. Full-size photo binaries are **never** uploaded to servers.
