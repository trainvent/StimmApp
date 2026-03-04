# Going International

## Summary

Prepare a second public-facing international brand for the app while keeping the existing German product intact.

Current target setup:

- German brand: `StimmApp`
- International brand: `Vivot`
- International domain: `vivot.net`
- iOS bundle ID: `com.trainvent.vivot`
- Android package: `com.trainvent.vivot`
- Support: `trainvent.com` / `support@trainvent.com`
- Privacy Policy: `https://vivot.net/privacy`

## Goal

Run German and international app variants from one shared Flutter codebase using flavors/brand configuration, instead of maintaining two separate repositories.

## Why

- Avoid code drift between German and international apps
- Keep one implementation and one bugfix path
- Allow separate branding, store presence, and release metadata
- Preserve flexibility to split later only if product behavior diverges

## Scope

- Add separate app flavors/targets for German and international variants
- Keep brand-specific app names, IDs, assets, and URLs configurable
- Keep bundle/package identifiers distinct for simultaneous store distribution
- Review and clean up current naming/package inconsistencies before rollout

## Proposed Work

1. Audit the current project for naming, package, bundle ID, Firebase, and flavor assumptions.
2. Clean up existing branding/config mistakes before adding a second variant.
3. Introduce flavor-based configuration for:
   - display name
   - bundle/package ID
   - icons and splash assets
   - support/privacy URLs
   - environment-specific constants
4. Add international flavor values for `Vivot`.
5. Verify iOS and Android build, signing, and Firebase configuration per flavor.
6. Prepare store metadata for App Store Connect and Play Console.

## Acceptance Criteria

- One repo builds both `StimmApp` and `Vivot`
- German and international variants have separate app identifiers
- Brand-specific URLs and metadata are not hardcoded globally
- Existing German app behavior remains unchanged
- International variant is ready for store setup

## Open Questions

- Whether German and international variants should use separate Firebase projects
- Whether backend content or moderation rules differ by market
- Whether `support@trainvent.com` remains the public support contact long-term
- Whether `vivot.net/support` should be added before launch

## Store Claim Checklist

- Claim App Store Connect app record for `Vivot`
- Register Apple bundle ID `com.trainvent.vivot`
- Create Play Console app with package `com.trainvent.vivot`
- Publish `https://vivot.net/privacy`
- Add public support/contact presence on `vivot.net`
