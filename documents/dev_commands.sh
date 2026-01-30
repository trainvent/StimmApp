# how to build
flutter clean
flutter build web --release --target lib/main.dart

# how to debug
flutter run --debug -d chrome -t lib/main_dev.dart

# run a single patrol test
patrol test --target integration_test/

# cloud deploy
firebase deploy --only functions --project stimmapp-dev

# sync dev with prod
gcloud scheduler jobs run firebase-schedule-syncProdToDev-us-central1 --project=stimmapp-dev --location=us-central1


