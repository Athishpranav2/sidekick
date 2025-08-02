# Sidekick

**A comprehensive social networking Flutter app that brings people together through meaningful connections, discussions, and shared experiences.**

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-039BE5?style=for-the-badge&logo=Firebase&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)

## 🌟 Overview

Sidekick is a modern social networking application built with Flutter that facilitates real connections between users through multiple interactive features. Whether you want to meet new people, engage in meaningful discussions, share your thoughts anonymously, or chat with matched users, Sidekick provides a comprehensive platform for social interaction.

## ✨ Key Features

### 🍽️ Side Table - Smart Matching System

- **Time-based Matching**: Select specific time slots when you're available to meet others
- **Intelligent Queue System**: Join matching queues and get paired with compatible users
- **Gender Preferences**: Option to match with users of the same gender or any gender
- **Real-time Match Tracking**: Monitor your queue status and view recent matches
- **Match Progress**: Visual interface showing active matches and meeting schedules
- **Chat Integration**: Seamlessly transition from matching to conversation

### 💬 SideTalk - Community Discussions

- **Public Feed**: Browse and engage with posts from the community
- **Anonymous & Public Posts**: Choose to post anonymously or with your identity
- **Interactive Engagement**: Like, comment, and discuss various topics
- **Smart Filtering**: Filter posts by type (all, anonymous, non-anonymous)
- **Real-time Updates**: Live feed updates with new posts and interactions
- **Character Limit**: Twitter-like 280 character limit for concise communication
- **Colorful Cards**: Visually appealing post cards with varied color schemes

### 🗣️ Vent Corner - Safe Space for Expression

- **Anonymous Confessions**: Share your thoughts and feelings anonymously
- **Public Venting**: Option to post with your identity for open discussions
- **Comment Threads**: Engage in supportive conversations on posts
- **Filtering Options**: Browse all posts or filter by specific criteria
- **How It Works Guide**: Built-in tutorial for new users
- **Safe Environment**: Moderated space for respectful sharing

### 💬 Real-time Chat System

- **Matched User Messaging**: Chat with users you've been matched with
- **Time-based Chat Access**: Chats unlock at specific meeting times
- **Professional UI**: Modern, WhatsApp-style messaging interface
- **Message Status**: Read receipts and delivery confirmations
- **Rich Text Support**: Send formatted text messages
- **Auto-scroll**: Automatic scrolling to latest messages
- **Keyboard Integration**: Smooth keyboard handling and animations

### 👤 Profile Management

- **Google Authentication**: Secure login with Google Sign-In
- **User Profiles**: Complete profile setup with display name and photo
- **Edit Profile**: Update your information anytime
- **Onboarding Flow**: Guided setup for new users
- **Settings & Support**: Help and support options
- **Account Management**: Sign out and account disconnection options

## 🛠️ Technical Stack

### Frontend

- **Flutter**: Cross-platform mobile development framework
- **Dart**: Programming language
- **Provider**: State management solution
- **Material Design**: Modern UI components

### Backend & Services

- **Firebase Authentication**: Secure user authentication
- **Cloud Firestore**: Real-time NoSQL database
- **Firebase Core**: Core Firebase functionality
- **Google Sign-In**: OAuth authentication

### Additional Libraries

- **flutter_svg**: SVG rendering support
- **shared_preferences**: Local data storage
- **intl**: Internationalization and date formatting
- **url_launcher**: External URL handling

## 🏗️ App Architecture

The app follows a clean architecture pattern with clear separation of concerns:

```
lib/
├── auth_service.dart           # Authentication service
├── main.dart                   # App entry point
├── core/                       # Core utilities and constants
│   ├── constants/              # App-wide constants
│   ├── services/               # Core services
│   └── utils/                  # Helper utilities
├── models/                     # Data models
│   ├── user_model.dart
│   ├── post.dart
│   ├── comment.dart
│   ├── confession.dart
│   └── filter_options.dart
├── providers/                  # State management
│   └── user_provider.dart
├── routes/                     # Navigation
│   └── app_routes.dart
├── views/                      # UI screens
│   ├── splash/                 # Splash screen
│   ├── login/                  # Authentication
│   ├── onboarding/             # User setup
│   ├── navigation/             # Bottom navigation
│   ├── home/                   # Home screen
│   ├── side_table/             # Matching system
│   ├── sidetalk/               # Discussion feed
│   ├── vent_corner/            # Confession space
│   ├── chat/                   # Messaging
│   ├── compose/                # Post creation
│   ├── profile/                # User profiles
│   └── matched_screen.dart     # Match notifications
└── widgets/                    # Reusable components
    └── custom_button.dart
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Android Studio / VS Code
- Firebase project setup
- Google Sign-In configuration

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/your-username/sidekick.git
   cd sidekick
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Firebase Setup**

   - Create a new Firebase project
   - Add Android/iOS apps to your Firebase project
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place the configuration files in the appropriate directories
   - Enable Authentication, Firestore, and Google Sign-In in Firebase Console

4. **Configure Google Sign-In**

   - Set up OAuth 2.0 credentials in Google Cloud Console
   - Add your SHA-1 fingerprint for Android
   - Configure bundle ID for iOS

5. **Run the app**
   ```bash
   flutter run
   ```

### Platform Support

- ✅ Android
- ✅ iOS
- ✅ Web (limited features)
- ✅ Windows (desktop)
- ✅ macOS (desktop)
- ✅ Linux (desktop)

## 🔒 Privacy & Security

- **Secure Authentication**: Google OAuth 2.0 implementation
- **Anonymous Options**: Choose to post anonymously in supported features
- **Data Protection**: Firebase security rules protect user data
- **Local Storage**: Minimal local data storage with encryption
- **No Email Restrictions**: Open to all users (PSG restriction currently disabled)

## 🎨 Design System

### Color Palette

- **Primary**: Black (#000000)
- **Accent**: Red (#DC2626)
- **Secondary**: Dark Gray (#1E1E1E)
- **Text**: White (#FFFFFF)
- **Cards**: Various muted colors for visual distinction

### UI Principles

- **Dark Theme**: Consistent dark theme throughout the app
- **Minimal Design**: Clean, uncluttered interface
- **Haptic Feedback**: Tactile responses for user interactions
- **Smooth Animations**: Fluid transitions and micro-interactions
- **Responsive Design**: Adaptive layouts for different screen sizes

## 🔄 App Flow

1. **Authentication**: Google Sign-In
2. **Onboarding**: Profile setup for new users
3. **Main Navigation**: Bottom tab navigation between features
4. **Side Table**: Select time slots → Join queue → Get matched → Chat
5. **SideTalk**: Browse feed → Create posts → Engage with community
6. **Vent Corner**: Share anonymously → Comment on posts → Find support
7. **Profile**: Manage account → Edit information → Access settings

## 📱 Screenshots & Demo

_Add screenshots of key features here when available_

## 🤝 Contributing

We welcome contributions! Please read our contributing guidelines before submitting pull requests.

### Development Guidelines

- Follow Flutter/Dart best practices
- Maintain consistent code style
- Write meaningful commit messages
- Test on multiple devices/platforms
- Update documentation for new features

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🐛 Issue Reporting

Found a bug or have a feature request? Please open an issue on our GitHub repository with:

- Detailed description of the issue
- Steps to reproduce
- Device/platform information
- Screenshots (if applicable)

## 📞 Support

For support and questions:

- Open an issue on GitHub
- Check the in-app Help & Support section
- Contact the development team

---

**Built with ❤️ using Flutter**

_Sidekick - Connecting people, one conversation at a time._
