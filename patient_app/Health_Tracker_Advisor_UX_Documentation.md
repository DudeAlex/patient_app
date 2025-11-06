# Health Tracker & Advisor App — UX Documentation

## Overview
The **Health Tracker & Advisor** app is a modern, minimalistic, and accessible mobile application designed to help patients manage their health data, records, and AI-powered advice. The interface prioritizes clarity, simplicity, and accessibility, ensuring usability for people of all ages — including those with visual or cognitive challenges.

---

## 🎨 Design Philosophy
- **Style:** Modern, minimal, and calm
- **Primary Accent:** Gradient Blue (`#60A5FA → #2563EB`)
- **Background:** Soft off-white gradient for subtle depth
- **Typography:** Inter (legible, digital-first typeface)
- **Accessibility:** Large touch targets (48pt+), high contrast, clear visual hierarchy

---

## 📱 Core Screens

### 1. Dashboard (Home)
- **Purpose:** Provides an at-a-glance summary of key health metrics.
- **Layout:**
  - Top bar with “Health” title and profile icon (top-right).
  - Scrollable 2x3 circular grid showing six core health metrics:
    - Steps, Heart Rate, Sleep, Water, Calories, and Stress.
  - Each circle shows:
    - Metric value (e.g., “7,540 steps”)
    - Subtext (e.g., “Today”)
    - Tap → opens detailed view.
  - **Bottom Navigation Bar:** Dashboard • Records • Advisor.
  - **Floating Add Record Button:** Gradient blue with a document + plus icon.
  - Quick action row: "Check Pulse" and "Check Blood Pressure" buttons surface camera-based readings.

---

### 2. Records Screen
- **Purpose:** Displays and manages medical records and personal health entries.
- **Design:**
  - Large title: “Records”
  - Top search bar with rounded corners and shadow.
  - Scrollable **list view** — large, easy-to-read items.
  - Each record has:
    - Minimalistic icon (e.g., 💊 🧾 🩺)
    - Title (e.g., “Blood Test”)
    - Subtitle with date (e.g., “Oct 25, 2025”)
  - Floating **Add Record** button with text label “＋ Add Record” and gradient blue background.
  - Button behavior:
    - Visible by default.
    - Hides when scrolling up.
    - Reappears when scrolling stops.

---

### 3. Add Record Modal (Bottom Sheet)
- **Triggered by:** Tapping the “＋ Add Record” button.
- **Appearance:**
  - White bottom sheet (60% screen height) with rounded top corners.
  - Title: “Add a New Record”
  - Subtitle: “Choose how you’d like to add your record.”
  - **Grid of options (2x3 layout):**
    1. 📷 Take Photo
    2. 🧾 Scan Document
    3. 🎤 Voice Note
    4. 🖊️ Type Note
    5. 📎 Upload File
    6. Email Import
  - Photo flow runs instant clarity/OCR checks and asks for a retake if the text or lighting fails thresholds before proceeding.
  - Scan Document offers guided rescan tips when glare/blur is detected, with manual crop fallback.
  - Email Import connects to a read-only Gmail label or dedicated forwarding inbox and shows source headers for transparency.
  - Cancel button at bottom or swipe down to close.
  - Smooth slide-up + fade-in animation.

---

### 4. Health Advisor Page (AI Assistant)
- **Purpose:** A conversational AI companion that helps analyze, summarize, and interpret health data.
- **Layout:**
  - Header: “Health Advisor” + 🤖 icon.
  - Subtitle: “Your personal AI health companion.”
  - **Chat Interface:**
    - User messages (right-aligned, blue bubbles).
    - Advisor responses (left-aligned, white with blue outline).
    - AI-generated summaries can include:
      - Text explanations
      - Small charts (e.g., weekly steps, heart rate trends)
      - Suggestions or reminders
  - **Input Bar:**
    - Text field for typing.
    - Microphone icon for voice input.
    - Send button.
  - Suggestion chips (optional): “Summarize my records”, “Remind me to take medicine”.
- **Behavior:**
  - AI reads data from stored records.
  - Summarizes, explains, and suggests actions.
  - Friendly, calm conversational tone.

---


### 5. Vitals Quick Actions
- **Purpose:** Enable in-app pulse and blood pressure checks with guided, confidence-graded readings.
- **Pulse Check:**
  - Camera-based photoplethysmography (finger over camera/flash) with live guidance and signal quality meter.
  - Save each reading with timestamp, confidence score, and a 'Not a medical diagnosis' disclaimer.
- **Blood Pressure:**
  - Pair with compatible Bluetooth cuffs or camera-assisted estimation (subject to regional approvals) and prompt calibration retries.
  - Store systolic/diastolic values, method metadata, and allow attaching results to existing records.
- **History & Prompts:** Surface recent vitals on the dashboard with trend indicators and gentle alerts when thresholds are exceeded.

---

## 🧠 AI & LLM Integration
- The Advisor uses a **Large Language Model (LLM)** to interpret medical entries.
- **Pipeline Overview:**
  1. OCR for scanned documents.
  2. ASR for voice recordings.
  3. Gmail label ingestion + header parsing for forwarded/triaged summaries.
  4. Data normalization (vitals, dates, providers).
  5. LLM summarization - insights + recommendations.
  6. Storage: Structured JSON + original media.
---

## 🔒 Accessibility & Safety
- Touch target minimum: 48x48pt.
- Text contrast: WCAG AA compliant (≥4.5:1).
- Clear color feedback for active states.
- On-device processing preferred for privacy (voice, OCR).
- Transparent permissions (camera, mic, storage).

---

## 📘 Summary
The **Health Tracker & Advisor App** combines simplicity, clarity, and intelligence to deliver a seamless patient experience.  
By integrating intuitive design with AI analysis, users can track, store, and understand their health data — all within an elegant, accessible interface.

---

© 2025 Health Tracker UX Documentation — Concept by Samuel & ChatGPT (FigmaGPT)

