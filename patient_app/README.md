# Patient App

A comprehensive patient management application with AI-powered features for health tracking, record management, and personalized assistance.

## Features

- **Multi-Space Organization**: Organize records across different spaces (Health, Finance, Education, Travel)
- **Smart Record Management**: Capture, store, and manage various types of health records
- **AI-Powered Assistance**: Natural language queries to retrieve and analyze your records
- **Secure Privacy**: End-to-end encryption and privacy controls for sensitive data
- **Cross-Platform Sync**: Seamless synchronization across all your devices
- **Stage 6 Intent-Driven Retrieval**: Smart record retrieval based on user queries
  - Language-agnostic keyword extraction works in any language
  - Relevance scoring combines keyword matching and recency
  - 30% token savings compared to Stage 4 date-based retrieval
 - Automatic fallback to Stage 4 when needed
  - Supports multiple Spaces (Health, Finance, Education, Travel)

## Architecture

The application follows clean architecture principles with:
- Domain layer for business logic
- Data layer for persistence and external services
- Presentation layer for UI and user interactions
- Core services for shared functionality

## Getting Started

1. Clone the repository
2. Install dependencies with `flutter pub get`
3. Run the application with `flutter run`

## Documentation

For detailed documentation, see the `docs/` directory:
- Core architecture: `docs/core/`
- Feature modules: `docs/modules/`
- Specifications: `.kiro/specs/`

## Contributing

See our contributing guidelines in the documentation.

## License

This project is licensed under the MIT License.