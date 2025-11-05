📁 1. Add New Keys to Translation Files
All translation files are located here:
assets/translations/
├── en.json   // English
├── tr.json   // Turkish
└── de.json   // German
Whenever you add a new UI text or label, make sure to add the same key in all three files:

✅ Example:

// en.json
{
  "welcome": "Welcome",
  "login_to_account": "Login to your account"
}

// tr.json
{
  "welcome": "Hoş Geldiniz",
  "login_to_account": "Hesabınıza giriş yapın"
}

// de.json
{
  "welcome": "Willkommen",
  "login_to_account": "Melden Sie sich bei Ihrem Konto an"
}


⚠️ Important:
Use identical keys in every language file.
Keep the structure consistent.
Double-check for missing commas or invalid JSON syntax.

⚙️ 2. Generate Translations for the App:
After updating the JSON files, run this command to generate translation data in Dart:

dart run easy_localization:generate -S "assets/translations" -O "lib/translations"
✅ This will generate a Dart file that the app can use internally for loading translations.

🗝️ 3. Generate Translation Keys (CodeGen):
Next, run this command to create the strongly-typed keys file:

dart run easy_localization:generate -S "assets/translations" -O "lib/translations" -o "locale_keys.g.dart" -f keys


✅ This will create a locale_keys.g.dart file in lib/translations/
Now you can reference translation keys in code with autocomplete and type safety.

💻 4. Use the Translations in Your UI

Import the keys file and call the translation like this:

import 'package:easy_localization/easy_localization.dart';
import 'package:haus_des_control/translations/locale_keys.g.dart';

Text(LocaleKeys.welcome.tr()); // ✅ Translated text




# For Building APKs: 
# Android
flutter build apk --dart-define=environment=prod --dart-define-from-file=config/prod.json
# iOS
flutter build ios --dart-define=environment=prod --dart-define-from-file=config/prod.json


# For App Run: 
flutter run --dart-define=environment=dev --dart-define-from-file=config/dev.json
flutter run --dart-define=environment=prod --dart-define-from-file=config/prod.json


# Using Make CLI:

make dev
make prod
make build-dev-android
make build-prod-android
make build-prod-ios



# Setup Firebase CLI Aliases
Make sure your Firebase CLI is configured with aliases:
bash# Navigate to your project root
cd /path/to/your/flutter/project

# Add dev project with alias
firebase use --add
# Select: controlapp-23df2
# Alias: dev

# Add prod project with alias
firebase use --add
# Select: controlapp-production
# Alias: prod

# Verify aliases
firebase projects:list


# For Deploying Functions:
cd functions// then run -    npm run lint -- --fix
firebase use dev
firebase use prod
firebase deploy --only functions

firebase deploy --only functions:cleanupExpiredStops
