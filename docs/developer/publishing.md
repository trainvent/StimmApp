# App screens
## which we post
1. creating survey
2. creating survey groups
3. seeing surveys with filter
4. filling survey
5. profile page
6. settings - dark mode
7. create petitions
8. sign petition

## Google Play draft upload

The repository uses Fastlane to build the signed StimmApp production AAB and
upload it with German and English release notes as a production-track **draft**.
Review and publish the draft in Play Console. The command does not send it for
review automatically.

### One-time setup

1. Install Ruby 3.2 or newer and Bundler, then run `bundle config set --local path vendor/bundle` followed by
   `bundle install` at the repo root
   (`bundle3.2` is the executable on some Linux installations). On Debian/Ubuntu,
   install `ruby-dev` and `build-essential` for native gem dependencies.
2. Enable the Google Play Android Developer API in your Google Cloud project.
   Create a dedicated publishing service account, and invite its email under
   Play Console → Users and permissions with access to `de.lemarq.stimmapp`
   and the release permissions needed to create production drafts.
3. Store the service account JSON outside the repository, or at the ignored path
   `fastlane/play-service-account.json`. Set `GOOGLE_PLAY_JSON_KEY` to its absolute
   path. Do not paste the JSON into a tracked file.
4. Configure the existing Android release signing in `android/key.properties`
   and its upload keystore. Use the Flutter version in `.flutter-version`.

Google's setup instructions:
https://developers.google.com/android-publisher/getting_started

### Each release

1. Set the version in `pubspec.yaml`. The number after `+` must be unused on Play.
2. Add user-facing release notes in both files, named after that build number:
   - `fastlane/metadata/android/de-DE/changelogs/<buildNumber>.txt`
   - `fastlane/metadata/android/en-GB/changelogs/<buildNumber>.txt`
   Each must contain 1–500 Unicode characters. The current notes cover the filter
   reset change; expand them if the release contains other changes.
3. From the repository root run:

   ```bash
   export GOOGLE_PLAY_JSON_KEY="$HOME/.config/stimmapp/play-service-account.json"
   bundle exec fastlane android draft
   ```

The lane validates the notes and credential path, runs
`flutter pub get --enforce-lockfile`, builds `--flavor prod -t lib/main.dart`,
and uploads the AAB plus notes. It includes `.env` as Dart defines when present,
matching the existing local build instructions. It leaves store descriptions and
screenshots untouched. An existing Play draft may need to be discarded before
another draft can be created; already uploaded version codes cannot be reused.

Fastlane reference: https://docs.fastlane.tools/actions/upload_to_play_store/

### VS Code

Run **Tasks: Run Task → Google Play: Build and Upload Production Draft**.
The task builds the app and uploads the draft with release notes. It uses
`GOOGLE_PLAY_JSON_KEY` inherited by VS Code, or defaults to the ignored
`fastlane/play-service-account.json`. One-time signing, credentials, and Bundler
setup above still apply. The wrapper supports both `bundle` and `bundle3.2`.
