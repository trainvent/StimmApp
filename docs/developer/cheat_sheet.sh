# quick rules
# - dev host: https://stimmapp-dev.web.app
# - prod host: https://stimmapp.eu
# - vivot host: https://vivot.net
# - dev web must be built with lib/main_dev.dart
# - prod web must be built with lib/main.dart
# - vivot mobile must be built with lib/main_vivot.dart
# - firebase aliases: dev, prod, vivotProd

# dev: local web debug
flutter run --debug -d chrome -t lib/main_dev.dart

# dev: build web bundle for deploy
./ci_scripts/build_web_dev.sh

# dev: deploy web bundle
firebase deploy --only hosting --project stimmapp-dev

# dev: android app debug run
flutter run --debug --flavor stimmappDev -t lib/main_dev.dart

# dev: test links with
# https://stimmapp-dev.web.app/petition/<id>
# https://stimmapp-dev.web.app/poll/<id>

# prod: build web bundle for deploy
./ci_scripts/build_web_prod.sh

# prod: deploy web bundle
firebase deploy --only hosting --project stimmapp-f0141

# prod: build Android release bundle
flutter build appbundle --release --flavor stimmappProd -t lib/main.dart

# prod: test links with
# https://stimmapp.eu/petition/<id>
# https://stimmapp.eu/poll/<id>

# vivot: android debug run
flutter run --debug --flavor vivotProd -t lib/main_vivot.dart

# vivot: build Android release bundle
flutter build appbundle --release --flavor vivotProd -t lib/main_vivot.dart

# vivot: build iOS archive/ipa on macOS
flutter build ipa --release --flavor vivotProd -t lib/main_vivot.dart

# vivot: test links with
# https://vivot.net/petition/<id>
# https://vivot.net/poll/<id>

# common: run a single patrol test
patrol test --target integration_test/

# common: set a secret to store hidden data
firebase functions:secrets:set

# firebase: add project aliases once
firebase use --add

# firebase: deploy functions per project
firebase deploy --only functions --project stimmapp-dev
firebase deploy --only functions --project stimmapp-f0141
firebase deploy --only functions --project vivot-prod

# firebase: deploy functions per alias
firebase deploy --only functions --project dev
firebase deploy --only functions --project prod
firebase deploy --only functions --project vivotProd

# firebase: set SMTP secret for Vivot
firebase functions:secrets:set SMTP_PASSWORD --project vivot-prod

# firebase: typecheck functions without writing build output
cd functions && npx tsc --noEmit && cd ..

# sync dev with prod
gcloud scheduler jobs run firebase-schedule-syncProdToDev-us-central1 --project=stimmapp-dev --location=us-central1

# clean up job
gcloud scheduler jobs run firebase-schedule-cleanupOrphanedUsers-us-central1 --location=us-central1 --project=stimmapp-dev

# ios complete reset
flutter clean
cd ios
rm -rf Pods/ Podfile.lock .symlinks
pod deintegrate
cd ..
flutter pub get
cd ios
pod install --repo-update
cd ..

# How to set up a dev channel
## Setting up i did not like for emailservice
gcloud projects add-iam-policy-binding stimmapp-dev \
  --member="serviceAccount:$(gcloud projects describe stimmapp-dev --format='value(projectNumber)')-compute@developer.gserviceaccount.com" \
  --role="roles/iam.serviceAccountTokenCreator"

## this weird shit on todo
gcloud projects add-iam-policy-binding stimmapp-f0141 \
  --member="serviceAccount:$(gcloud projects describe stimmapp-f0141 --format='value(projectNumber)')-compute@developer.gserviceaccount.com" \
  --role="roles/iam.serviceAccountTokenCreator"

# google stuff ie setup for a development-project mirror
## setup data sync from prod to dev
PROD_PROJECT_ID="stimmapp-f0141"

## Create the service account
gcloud iam service-accounts create dev-data-sync-reader \
    --display-name="Dev Data Sync Reader" \
    --project=$PROD_PROJECT_ID

## Grant Firestore Read Access
gcloud projects add-iam-policy-binding $PROD_PROJECT_ID \
    --member="serviceAccount:dev-data-sync-reader@$PROD_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/datastore.viewer"

## Grant Storage Read Access
gcloud projects add-iam-policy-binding $PROD_PROJECT_ID \
    --member="serviceAccount:dev-data-sync-reader@$PROD_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/storage.objectViewer"

## Create the key file locally (it will be saved as prod-key.json)
gcloud iam service-accounts keys create prod-key.json \
    --iam-account=dev-data-sync-reader@$PROD_PROJECT_ID.iam.gserviceaccount.com \
    --project=$PROD_PROJECT_ID

## extract key and delete keyfile
firebase functions:secrets:set PROD_SERVICE_ACCOUNT_KEY < prod-key.json --project=stimmapp-dev
rm prod-key.json

## run the sync
gcloud scheduler jobs run firebase-schedule-checkSubscriptions-us-central1 --location=us-central1

# test SMPT
swaks --server smtp.strato.de --port 465 --tls-on-connect --auth LOGIN \
  --auth-user 'noreply@trainvent.com' --auth-password 'CFp9v8*)zRBFt8cogA%wIZPT' \
  --from 'noreply@trainvent.com' --to 'leon.marquardt@mail.de'

  swaks --server mail.example.com:465 \
      --tls-on-connect \
      --auth noreply@trainvent.com \
      --auth-user noreply \
      --auth-password 'CFp9v8*)zRBFt8cogA%wIZPT' \
      --from noreply@trainvent.com \
      --to leon.marquardt@mail.de \
      --suppress-data