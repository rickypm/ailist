# AiList

**AI-Powered Hyperlocal Services Platform**

WeList connects users with local service providers using AI-powered search and chat.  Find electricians, plumbers, tutors, and more in your area.

## Features

- 🤖 **AI Chat Search** - Natural language search for services
- 📍 **Hyperlocal** - Find services near you
- 💬 **Direct Messaging** - Chat with service providers
- 🔓 **Unlock System** - Pay-per-contact monetization
- 👥 **Referral Program** - Earn unlocks by referring friends
- 📊 **Partner Dashboard** - Analytics for service providers

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / VS Code
- Supabase account
- OpenAI API key (for AI chat)
- Razorpay account (for payments)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/ailist.git
   cd welist
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment**
   - Copy `lib/config/app_config.dart. example` to `lib/config/app_config.dart`
   - Add your API keys: 
     - Supabase URL and Anon Key
     - OpenAI API Key
     - Razorpay Key ID

4. **Setup Supabase**
   - Create a new Supabase project
   - Run `supabase/schema.sql` in the SQL Editor
   - Configure Row Level Security policies

5. **Run the app**
   ```bash
   flutter run
   ```

### Build for Production

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
```

## Project Structure

```
lib/
├── config/          # App configuration
├── models/          # Data models
├── services/        # API and business logic
├── providers/       # State management
├── screens/         # UI screens
├── widgets/         # Reusable widgets
└── utils/           # Utility functions
```

## Tech Stack

- **Frontend**: Flutter, Dart
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Realtime)
- **AI**: OpenAI GPT-3.5
- **Payments**: Razorpay
- **State Management**: Provider

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is proprietary software. All rights reserved. 

## Contact

- **Email**: support@welist.app
- **Website**: https://welist.app

---

Made with ❤️=======
# ailist_01
