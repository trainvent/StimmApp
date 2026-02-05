# how to prepare deploy
flutter clean
flutter build web --release --target lib/main.dart

# how to debug
flutter run --debug -d chrome -t lib/main_dev.dart


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