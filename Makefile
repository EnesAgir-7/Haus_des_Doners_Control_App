dev:
	flutter run --dart-define=environment=dev --dart-define-from-file=config/dev.json
prod:
	flutter run --dart-define=environment=prod --dart-define-from-file=config/prod.json

build-dev-android:
	flutter build apk --dart-define=environment=dev --dart-define-from-file=config/dev.json

build-prod-android:
	flutter build apk --dart-define=environment=prod --dart-define-from-file=config/prod.json

build-prod-ios:
	flutter build ios --dart-define=environment=prod --dart-define-from-file=config/prod.json