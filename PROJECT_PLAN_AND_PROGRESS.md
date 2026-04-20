# Productivitree (ABCD) - Project Plan and Progress

## Document Info
- Project codename: ABCD
- Product name: Productivitree
- Platform: iOS (SwiftUI)
- Backend: Firebase Auth + Cloud Firestore
- Architecture: MVVM
- Last updated: 2026-04-21

---

## 1) Project Summary
Productivitree is a social, gamified productivity app that combines:
- Task management
- Habit tracking
- Focus sessions (Pomodoro + history)
- Study partner sessions (social accountability)
- Profile, XP, and analytics

The app uses Firebase for authentication and persistent cloud data.

---

## 2) Vision and Core Features
### A. Authentication
- Email/password registration and login
- User profile document creation in Firestore
- Auth state handling and logout

### B. Tasks
- Create/read/update/delete tasks
- Priority support (high/medium/low)
- Complete task flow with XP

### C. Habits
- Habit CRUD
- Daily completion toggling
- Streak tracking and best streak
- Habit heatmap visualization

### D. Focus Sessions
- Focus timer modes
- Session save + history
- Total focus minutes updates

### E. Study Sessions (Social)
- Create/join/leave/delete sessions
- Participant tracking with real-time updates
- Creator-only delete validation

### F. Profile + Gamification
- Profile header and level display
- XP progress bar
- Stats cards (tasks, focus time, streak)
- Motivational quote API + local fallback
- Level-up notification flow

### G. Analytics
- Weekly focus minutes chart
- Weekly completed tasks chart
- 7-day XP growth chart

---

## 3) Current Architecture
### MVVM Layers
- Views: SwiftUI screens and reusable components
- ViewModels: state + orchestration
- Services: Firebase/network/data operations
- Models: Codable entities and app domain models

### Data Sources
- Firebase Auth: user sessions
- Firestore collections:
  - users
  - tasks
  - habits
  - focus_sessions
  - study_sessions
- External API: zenquotes
- Local fallback data: Resources/quotes.json

---

## 4) Progress Status (What is done so far)

## Day 1 (Setup + Auth)
Status: Done
- Firebase initialized
- Auth service implemented
- Auth routing and login/register flow in place

## Day 2 (Tasks)
Status: Done
- Task model/service/viewmodel/view flow implemented
- Completion awards XP
- Double-completion XP guard added

## Day 3 (Habits)
Status: Done
- Habit CRUD and streak logic implemented
- XP award flow implemented
- Anti-abuse improvement added (xpAwardedDates)

## Day 4 (Focus)
Status: Done
- Focus timer logic implemented
- Session save/history implemented
- Total focus minute updates implemented

## Day 5 (Study Partner)
Status: Done
- Study session model/service/viewmodel/views implemented
- Join/leave/create/delete validations implemented
- Security rules file added and tightened for study_sessions updates

## Day 6 (Profile + Quotes + Gamification + Analytics)
Status: Implemented
- ProfileView + ProfileViewModel implemented
- QuoteService with API + fallback JSON implemented
- UserStatsService implemented
- XP progress, level display, and level-up feedback implemented
- AnalyticsView implemented with Swift Charts
- Habit heatmap visualization implemented and integrated in habit rows

## Day 7 (Testing + Final Polish)
Status: In progress
- Codebase feature-complete for major flows
- Remaining work is primarily full end-to-end testing, bug-fix pass, and release polish

---

## 5) Important Engineering Improvements Already Applied
- Explicit FirebaseFirestoreSwift imports where Firestore Codable helpers are used
- Real-time user document snapshot handling in AuthService for live profile updates
- Task XP duplication prevention
- Habit XP duplication prevention per day
- Firestore rules file added at firebase/firestore.rules

---

## 6) Current Folder Structure (Workspace Snapshot)

```text
ABCD/
├── .git/
├── .gitignore
├── ABCD.xcodeproj/
├── firebase/
│   └── firestore.rules
└── ABCD/
    ├── ABCDApp.swift
    ├── ContentView.swift
    ├── GoogleService-Info.plist
    ├── Assets.xcassets/
    ├── Models/
    │   ├── AmbientSound.swift
    │   ├── FocusSessionModel.swift
    │   ├── HabitModel.swift
    │   ├── Quote.swift
    │   ├── StudySession.swift
    │   ├── TaskModel.swift
    │   ├── UserModel.swift
    │   └── UserStats.swift
    ├── Resources/
    │   └── quotes.json
    ├── Services/
    │   ├── AmbientSoundService.swift
    │   ├── AuthService.swift
    │   ├── FocusService.swift
    │   ├── GamificationService.swift
    │   ├── HabitService.swift
    │   ├── QuoteService.swift
    │   ├── StudySessionService.swift
    │   ├── TaskService.swift
    │   └── UserStatsService.swift
    ├── Utilities/
    │   ├── Constants.swift
    │   └── Theme.swift
    ├── ViewModels/
    │   ├── FocusViewModel.swift
    │   ├── HabitViewModel.swift
    │   ├── ProfileViewModel.swift
    │   ├── StudySessionViewModel.swift
    │   └── TaskViewModel.swift
    └── Views/
        ├── MainTabView.swift
        ├── Analytics/
        │   └── AnalyticsView.swift
        ├── Auth/
        ├── Components/
        │   ├── EmptyStateView.swift
        │   ├── QuoteCard.swift
        │   ├── StatCard.swift
        │   └── XPProgressBar.swift
        ├── Focus/
        ├── Habits/
        │   ├── AddHabitView.swift
        │   ├── HabitHeatmapView.swift
        │   ├── HabitListView.swift
        │   └── StreakVisualization.swift
        ├── Profile/
        │   └── ProfileView.swift
        ├── StudySessions/
        └── Tasks/
```

---

## 7) Firebase Security Notes
Current rules file exists at:
- firebase/firestore.rules

Current direction:
- user-scoped access for users/tasks/habits/focus_sessions
- authenticated read for study_sessions
- creator-gated deletion for study_sessions
- controlled participant updates on study_sessions

---

## 8) Remaining Plan (Recommended Next Steps)
1. Run full Day 7 QA checklist with two test accounts (A/B flow)
2. Validate analytics numbers against raw Firestore data
3. Perform dark-mode and layout pass on all major screens
4. Add lightweight loading/error polish where needed
5. Prepare demo assets (screenshots/video)

---

## 9) Build and Run
- Open ABCD.xcodeproj in Xcode
- Ensure Firebase config file exists in app target (GoogleService-Info.plist)
- Select iOS 16+ simulator/device
- Build and run

---

## 10) Team Notes
This document is intended as a living project plan + status snapshot. Update this file after each major milestone, bug-fix sprint, or architecture change.
