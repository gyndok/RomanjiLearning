RomanjiLearning

A SwiftUI iOS app for learning Japanese travel phrases through flashcards, quizzes, and spaced repetition.

Features

500+ Bundled Phrases — Essential Japanese travel phrases organized by category (Airport, Hotel, Restaurant, Shopping, Transportation, and more)
Flashcard Study — Tap-to-flip cards with 3D animation, audio playback, and swipe navigation
Spaced Repetition (SRS) — SM-2 algorithm schedules reviews at optimal intervals for long-term retention
Quiz Mode — Multiple-choice quizzes with English-to-Japanese and Japanese-to-English directions
Scenario Decks — Real-world context packs (e.g. checking into a hotel, ordering food) with dedicated mini-quizzes
Search — Find phrases by English, Japanese, or romaji
Custom Phrases — Add your own phrases with Apple Translation integration for auto-translation
Progress Tracking — Streak system, category charts, and detailed study statistics
Audio Playback — Native Japanese pronunciation with normal and slow speed options
Onboarding — 3-page walkthrough for first-time users
Dark Mode — Full dark mode support with dynamic color adaptation
Design

Japan-inspired premium aesthetic featuring:

Color palette: deep indigo, cherry blossom pink, vermillion red, matcha green, warm off-white
Rounded sans-serif typography with dedicated Japanese and romaji font styles
Spring animations, haptic feedback, and scale-on-press interactions
Gradient accents and themed card components throughout
Requirements

iOS 17.0+
Xcode 16.0+
Swift 5
Getting Started

Clone the repository
Open RomanjiLearning.xcodeproj in Xcode
Build and run on a simulator or device
Project Structure

RomanjiLearning/
├── RomanjiLearningApp.swift    # App entry point with environment setup
├── Theme.swift                 # Design system (colors, fonts, styles, modifiers)
├── Models/
│   ├── Phrase.swift             # Phrase data model
│   ├── PhraseProgress.swift     # Mastery level tracking
│   ├── ScenarioDeck.swift       # Scenario deck definitions
│   └── SRSData.swift            # Spaced repetition data model
├── Views/
│   ├── MainTabView.swift        # Tab bar navigation
│   ├── FlashcardView.swift      # Flashcard study interface
│   ├── QuizView.swift           # Quiz setup and gameplay
│   ├── QuizResultView.swift     # Quiz results with score ring
│   ├── SearchView.swift         # Phrase search
│   ├── AddPhraseView.swift      # Custom phrase creation
│   ├── SettingsView.swift       # Settings and statistics
│   ├── PhraseDetailView.swift   # Individual phrase detail
│   ├── ScenarioListView.swift   # Scenario browsing and study
│   ├── SRSStudyView.swift       # Spaced repetition review
│   ├── StudyProgressView.swift  # Progress charts and stats
│   └── OnboardingView.swift     # First-launch walkthrough
├── Services/
│   ├── PhraseManager.swift      # Phrase loading, filtering, CRUD
│   ├── AudioService.swift       # Japanese speech synthesis
│   ├── TranslationService.swift # Apple Translation integration
│   ├── ProgressManager.swift    # Streaks, reviews, mastery tracking
│   ├── QuizManager.swift        # Quiz logic and scoring
│   └── SRSManager.swift         # SM-2 spaced repetition algorithm
└── Resources/
    └── japanese_travel_phrases.json  # 500+ bundled phrases
License

This project is for personal/educational use.
