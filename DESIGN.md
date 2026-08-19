# StimmApp Product Design Direction

Status: design brief for Google Stitch and the Flutter implementation  
Primary target: iOS and Android phones  
Secondary target: responsive web and tablet  
Languages: German and English  
Implementation: Flutter, Material 3

## 1. Purpose

StimmApp helps people create, discover, sign, and manage petitions, polls, surveys, and private voting groups. This work is a restrained visual refinement of the existing product, not a redesign. It should make the current interface feel calmer, more legible, and more consistent without changing its recognizable identity.

This file is both:

1. the design source of truth for the app; and
2. the brief to use when creating and iterating on a Google Stitch project that can later be connected through MCP.

The refinement must not invent a new backend, remove existing product capabilities, or replace familiar layouts with a new design concept. It should clarify the current product and document the system already present in the Flutter app.

### Fidelity contract — highest-priority instruction

The current app, supplied screenshots, and uploaded assets are the visual source
of truth. All later sections describe boundaries and polish opportunities; they
do not authorize a new visual identity. When an instruction conflicts with a
current screen, preserve the current screen unless the instruction explicitly
labels the change as required.

For every generated screen:

- Preserve the existing information architecture, navigation destinations,
  content order, controls, labels, and interaction model.
- Preserve the current brand colors, Poppins typography, mascot artwork, icon
  style, and overall visual character. Do not introduce a replacement palette.
- Keep the current page composition and component placement recognizable. A
  returning user should not have to relearn the screen.
- Make only low-risk refinements: consistent spacing, alignment, type hierarchy,
  accessible contrast, clearer state treatment, and obvious component
  consistency fixes.
- Do not add, remove, merge, or relocate a feature merely to improve aesthetics.
- Do not turn ordinary lists into dashboards, replace navigation patterns, add
  decorative imagery, or create a new card system without explicit approval.
- If screenshots are supplied, match them closely. Treat each output as a
  polished next version of that screen, not an alternative concept.
- When the current appearance is unclear, keep the area neutral and request a
  reference instead of inventing a solution.

The permitted change budget is deliberately small: aim for roughly 80–90%
visual continuity and 10–20% polish per screen. First generate one representative
screen for approval. Do not propagate a visual change to other screens until
that first screen is approved.

## 2. Product character

### Design statement

**StimmApp is the calm, credible place where a person can understand an issue, make a choice, and see that their participation counted.**

### Desired qualities

- Trustworthy, not institutional or bureaucratic
- Contemporary, not trendy
- Warm, not childish
- Decisive, not aggressive
- Information-rich, not dense
- Inclusive and neutral across political viewpoints
- Native to mobile, not a desktop dashboard squeezed onto a phone

### Avoid

- Neon colors, glassmorphism, strong gradients, and glowing effects
- Oversized rounded cards on every surface
- Excessive shadows, floating layers, and decorative blobs
- Cartoon imagery in core task flows
- Red as the default brand color or a decorative accent; reserve it for destructive and error states
- Overuse of pills and chips
- Tiny metadata, low contrast text, or icon-only actions without labels/tooltips
- Social-media engagement patterns such as like counts, streaks, or manipulative urgency
- Fake charts, invented statistics, or features not supported by the product

## 3. Users and jobs

### Participant

- Find relevant active petitions or polls
- Understand the topic, scope, author, deadline, and current participation
- Sign or vote with confidence
- See confirmation and whether they already participated
- Review past participation

### Creator

- Create a petition, poll, or survey without missing required information
- Preview the result before publishing
- Understand audience scope, visibility, deadline, and publishing limits
- Monitor participation and export results

### Group member or administrator

- Enter a group using an invite, access code, link, or QR code
- See group content, members, activity, permissions, and expiry
- Manage invitations and roles when authorized
- Participate in group-only polls and administrator elections

## 4. Information architecture

Preserve the current core information architecture unless usability testing supports a deliberate change.

### Signed-in root

- Top app bar: current section title; profile avatar; settings only where it is not duplicated in profile
- Primary bottom navigation:
  - `Petitionen` / `Petitions`
  - `Umfragen` / `Polls`
- Contextual create action for the selected content type
- Profile contains identity, inbox, groups, publications, participation history, privacy, account, and settings entry points

Do not add a third bottom-navigation destination only to make the layout look balanced. Two clear destinations are valid. Groups may remain accessible from Profile until the product explicitly changes its navigation model.

### Core flows to represent in Stitch

1. Welcome and authentication
2. Petition discovery and filtering
3. Petition details and signing
4. Poll discovery and voting
5. Creation flow for a petition or poll
6. Profile and activity
7. Group overview and group dashboard
8. Settings and appearance

## 5. Visual refinement: preserve the existing identity

Retain the colors and Material 3 behavior already used by the app. Improve
consistency and accessibility without imposing a new art direction. The product
should remain recognizably StimmApp rather than becoming a generic civic-service
concept.

### Color tokens

Use semantic names in designs and implementation, but derive their values from
the current Flutter `ColorScheme` and the selected app color theme. Screenshots
take precedence for the active theme. Do not replace the current primary color
with evergreen, teal, blue, or another newly proposed brand palette.

| Token | Source | Use |
| --- | --- | --- |
| `brand.primary` | Current theme `primary` | Existing primary actions and app chrome |
| `brand.onPrimary` | Current theme `onPrimary` | Content on the current primary color |
| `brand.primaryContainer` | Current theme `primaryContainer` | Existing selected and emphasized surfaces |
| `accent.secondary` | Current theme `secondary` | Existing secondary actions and accents |
| `surface.canvas` | Current theme `surface` | Main page background |
| `surface.subtle` | Current theme surface container | Grouped or muted areas where already used |
| `text.primary` | Current theme `onSurface` | Primary content |
| `text.secondary` | Current theme `onSurfaceVariant` | Metadata and supporting copy |
| `border.default` | Current theme `outlineVariant` | Dividers and component boundaries |
| `state.error` | Current theme `error` | Errors and destructive actions only |

### User-selectable color themes

The current product supports multiple theme colors. Retain this capability, but treat it as accent personalization rather than a complete visual identity change:

- Neutral surfaces, typography, spacing, component shapes, and status colors remain stable.
- A chosen theme may replace `brand.primary` and its derived containers.
- Ensure every selectable theme passes contrast requirements in light and dark mode.
- Use the same active theme as the supplied reference screen. Show alternative
  theme colors only on the appearance-settings screen.

### Typography

Use **Poppins** for product UI because it is already the app typeface. Follow
the uploaded-font fallback rules in **Attached asset package** when a requested
weight is unavailable.

| Style | Size / line height | Weight | Use |
| --- | --- | --- | --- |
| Display | 32 / 40 | 600 | Welcome statement only |
| Headline large | 28 / 36 | 600 | High-emphasis detail title |
| Headline medium | 24 / 32 | 600 | Page and major section title |
| Title large | 20 / 28 | 600 | Card and dialog title |
| Title medium | 16 / 24 | 600 | List item title |
| Body large | 16 / 24 | 400 | Reading content and form input |
| Body medium | 14 / 21 | 400 | Supporting content |
| Label large | 14 / 20 | 600 | Buttons and tabs |
| Label medium | 12 / 16 | 500 | Metadata and status labels |

Rules:

- Prefer sentence case.
- Left-align paragraphs and data.
- Center text only in compact empty, loading, confirmation, or onboarding compositions.
- Never use all caps for navigation or ordinary actions.
- Support dynamic text scaling to at least 200% without hiding required actions.
- Design German labels first when checking layout because they are often longer.

### Spacing and layout

Use a 4 px base grid.

- Page horizontal padding: 20 px on phones, 32 px on compact tablets, 40 px on larger canvases
- Section spacing: 24 or 32 px
- Related item spacing: 8 or 12 px
- Standard control height: 48 px minimum
- Minimum touch target: 48 × 48 px
- Compact phone design viewport: 390 × 844 px
- Also validate at 360 × 800 px and with a 200% text scale
- Reading/form content maximum width: 680 px
- Discovery feed maximum width: 760 px
- Wide layouts should center content; do not stretch paragraphs or cards edge to edge

### Shape and elevation

- Small controls and inputs: 10 px radius
- Cards and grouped sections: 16 px radius
- Buttons: 12 px radius; do not use fully pill-shaped primary buttons
- Bottom sheets: 24 px top radius
- Cards use a 1 px border by default
- Use zero elevation for ordinary cards and one subtle shadow only for overlays or sticky controls
- Keep important content visible without relying on blur or transparency

### Icons and illustration

- Use one consistent rounded Material icon family.
- Pair unfamiliar icons with labels.
- Use the existing Lemm mascot only on welcome, education, meaningful empty states, and occasional success moments.
- Do not show the mascot in every list, app bar, settings row, or serious confirmation dialog.
- Content thumbnails use documentary or topic-relevant imagery with a consistent crop and a neutral placeholder when missing.

### Attached asset package

The `assets/` folder is part of this design brief. When this document and that
folder are uploaded together, preserve the relative paths below and use the
provided files instead of redrawing, tracing, or stylistically reinterpreting
the brand assets.

#### Brand and product assets

| Relative path | Intended use |
| --- | --- |
| `assets/images/AppIcon_transparent.png` | Preferred transparent app mark for design compositions |
| `assets/images/AppIcon.png` | App icon when an opaque icon tile is required |
| `assets/images/StimmApp_Logo_512.png` | StimmApp logo/wordmark reference |
| `assets/images/LeLogo.png` | Lemm mascot mark or compact mascot reference |
| `assets/images/Lemm_login.png` | Welcome and sign-in illustration |
| `assets/images/Lemm_waving.png` | Friendly first-use empty state or onboarding |
| `assets/images/Lemm_pen.png` | Petition/poll creation education |
| `assets/images/Lemm_pen_location.png` | Location or regional-scope education |
| `assets/images/Lemm_teaching.png` | Explanatory or educational state |
| `assets/images/Lemm_selling.png` | Subscription explanation only; not ordinary civic flows |
| `assets/images/default_avatar.png` | Neutral fallback profile avatar |

Use only one mascot illustration in a screen, keep its original aspect ratio,
and place it on a simple neutral surface. Do not crop off the face or hands,
recolor it to match a theme, use it as a repeating background, or generate new
mascot poses. The app icons and logos are identity assets and must not be used
as generic decorative illustrations.

The files in `assets/images/old/` are legacy references and must be ignored.
Store badges and Apple/Google sign-in artwork are platform-provided assets: use
them only for their named purpose and do not restyle them. `assets/images/tiles.png`
and `assets/lotties/` are implementation assets, not the visual direction for
new screens; do not use them unless a screen requirement explicitly calls for
one of them.

#### Fonts

Use the uploaded Poppins files in `assets/fonts/`:

- `Poppins-Regular.ttf` — 400
- `Poppins-Italic.ttf` — 400 italic
- `Poppins-Bold.ttf` — 700
- `Poppins-Black.ttf` — 900, exceptional display use only

Do not substitute Google Sans or Roboto for ordinary StimmApp product UI. The
provided package does not contain Poppins 500 or 600. For generated design
previews, use Poppins 700 where this brief specifies a semibold emphasis; the
production implementation should add real Poppins 500/600 files before using
those weights and must not synthesize missing weights.

#### Upload contract

- Upload this `DESIGN.md` file through the dedicated DESIGN.md input.
- Upload the repository's `assets/` directory through the adjacent code,
  images, fonts, and logos input. If the file picker does not select folders,
  drag the folder onto that drop zone or select the listed files in batches
  while keeping their filenames.
- Relative paths are identifiers. Do not flatten or rename files when the
  uploader preserves folders.
- The written design rules take precedence over visual cues in an asset.
- Missing assets must use a neutral placeholder; do not invent a replacement
  logo, mascot, partner badge, or product screenshot.

## 6. Core components

### App bar

- 56 px compact height, with a larger 96–112 px treatment only where the page benefits from a prominent title
- Left-aligned page titles for content-heavy root pages
- One clear leading navigation action on child pages
- No more than two high-frequency trailing actions; place the rest in an overflow menu
- Profile avatar is 36 px with a visible focus/tap state

### Bottom navigation

- Stable surface separated by a subtle top border
- Selected item uses `primaryContainer` and a strong label
- Unselected icons and labels retain sufficient contrast
- Support safe-area insets
- Do not use a central oversized create button

### Buttons

- Filled primary: one dominant action per view or dialog
- Tonal: secondary constructive action
- Outlined: lower-priority alternative
- Text: low-emphasis, cancel, or inline action
- Destructive: error color and an explicit verb
- Loading: preserve the button width and label context; use the project-standard `TriangleLoadingIndicator` in a constrained slot
- Disabled controls remain legible and cannot rely on opacity alone to communicate why they are unavailable

### Petition or poll card

An ordinary feed item is a bordered surface, not a bare list tile with a divider.

Order of content:

1. optional 16:9 or 4:3 thumbnail
2. content type and scope metadata
3. title, maximum three lines
4. short description, maximum two lines
5. status row: participation count, deadline, and participation state
6. at most two visible topic tags, then `+N`

Use icons plus text for important status. Show `Bereits teilgenommen` / `Participated` as a clear success state. Group-only content must show its group name. Never use color alone to distinguish active, closed, or participated content.

### Search and filters

- Search field and filter action appear as one visual toolbar
- Use a trailing clear action when text exists
- Show active filters as removable chips below the toolbar
- Open filters in a full-height bottom sheet on phones rather than a cramped alert dialog
- Group filter sections: scope, region, topics, group, content state, and own publications where applicable
- Always provide `Zurücksetzen` / `Reset` and `Ergebnisse anzeigen` / `Show results`

### Form fields

- Persistent visible label; placeholder is an example, not the only label
- Supporting text below fields for limits, privacy implications, and validation
- Error appears near the relevant input and is announced to accessibility services
- Use grouped sections in long creator forms
- Place destructive or irreversible options away from ordinary toggles

### Status, feedback, and progress

- Use determinate progress when a known petition goal or upload progress exists
- The profile image upload keeps its determinate circular indicator around the circular image preview
- Use the project-standard triangle indicator for other loading states
- Snackbar copy says what happened and, where useful, offers a recovery action
- Confirmation states show what was recorded and what the user can do next

### Empty and error states

Every data screen should define:

- loading
- populated
- empty-first-use
- empty-after-filter
- recoverable error
- offline/stale-data state where relevant

Empty states contain a concise title, one sentence, and at most one primary action. A small mascot illustration is allowed only when it helps the tone.

## 7. Reference screens for the Stitch project

Refine these screens one at a time, using the existing screen or screenshot as
the starting frame. Preserve its structure and existing components. Use
realistic German content in the first pass and duplicate key screens in English
only after the system is stable. Do not generate the full set in one pass: begin
with one representative screen, compare it with the reference, and wait for
approval before carrying its refinements into another screen.

### Screen 01 — Welcome

- Small StimmApp wordmark at top
- Restrained Lemm illustration occupying no more than one third of the viewport
- Headline: `Deine Stimme. Deine Entscheidung.`
- Supporting copy: `Petitionen starten, gemeinsam abstimmen und Veränderungen sichtbar machen.`
- Primary action: `Konto erstellen`
- Secondary action: `Anmelden`
- Divider and compact Google/Apple sign-in buttons
- Privacy and terms links in quiet footer text
- Avoid a red headline and avoid making the mascot the entire product identity

### Screen 02 — Petition discovery

- Left-aligned title `Petitionen`
- Avatar action in the app bar
- Search/filter toolbar
- Active/closed segmented tabs
- Two or three petition cards showing varied states:
  - active local petition with image and `482 Unterschriften`
  - active national petition without image
  - already-signed petition with success status
- Contextual create action labeled `Petition starten`
- Bottom navigation with Petitions selected and Polls unselected

### Screen 03 — Filter sheet

- Full-height mobile bottom sheet
- Clear title and close affordance
- Scope choices: Global, EU, Deutschland, Bundesland, Stadt
- Topic tags
- Toggle for own publications
- Sticky bottom actions for reset and showing results
- Include selected, unselected, and disabled examples

### Screen 04 — Petition details

- Back, share, and overflow actions
- Optional wide topic image
- Scope and active-state metadata above the title
- Long readable title and author/created date line
- Description with comfortable reading measure
- Topic tags
- Participation summary with signature count and close date
- Sticky bottom action `Petition unterschreiben`
- Secondary text explaining what signing means
- Include an alternate signed state: confirmation, timestamp, and disabled/replaced primary action

### Screen 05 — Poll discovery

- Same discovery framework as petitions
- Poll cards use vote count and option count, not signature language
- Include public, group-only, participated, and closed states
- Create action labeled `Umfrage erstellen`

### Screen 06 — Poll details and vote

- Question, context, author, scope, group visibility, and deadline
- Large radio selection rows with clear selected and pressed states
- Primary action `Stimme abgeben`
- Pre-submit note about whether a vote can be changed
- Result state with labeled horizontal bars, values, percentages, total votes, and the user's selected option
- Charts must remain understandable without color

### Screen 07 — Creator flow

Represent creation as a focused multi-step flow, even if implementation begins with the current single-page form:

1. Basics: title, description, optional image
2. Audience: geographic scope, public or group-only visibility, group selection
3. Choices: poll options or petition settings
4. Timing and topics: close behavior, date, tags
5. Review: preview plus clear publish action

Show progress (`Schritt 2 von 5`), save-and-exit behavior, validation, and a review summary. Do not make every field visible at once in the reference design.

### Screen 08 — Profile

- Compact identity header with avatar, name, username, location, and edit action
- Small status/plan label if applicable; no oversized subscription advertising
- Grouped navigation sections:
  - Activity: inbox, running forms, publications, history
  - Community: groups, signed petitions, blocked users
  - Account: personal data, synchronization, privacy, export
- Settings entry and sign-out at the bottom
- Administrative tools appear only for eligible users

### Screen 09 — Groups overview

- Title, explanatory subtitle, create group action, and scan QR action
- Group cards show name, role, member count, access mode, and expiry
- First-use empty state explains why private groups are useful
- Provide an invitation-pending banner or row when relevant

### Screen 10 — Group dashboard

- Group identity header with name, role, access, members, and expiry
- Strong section hierarchy rather than a wall of equal cards
- Sections for group content, members, invitations, activity, and administration
- Show an active administrator-election notice as a time-sensitive but non-alarming banner
- Destructive group actions live in a separate danger section

### Screen 11 — Settings

- Group settings into Appearance, Language, Notifications/Privacy where supported, Help, and About
- Theme mode selector for system/light/dark
- Color accent selector with accessible swatches and selected indicators
- App version in a quiet footer
- Avoid nesting every setting in a separate card

### Screen 12 — System states sheet

Create a design-system canvas showing:

- colors and type styles
- buttons and icon buttons in all states
- inputs, search, filter chips, and segmented tabs
- content cards
- list rows and settings rows
- banners, snackbars, dialogs, and bottom sheets
- light and dark modes
- loading, empty, error, offline, active, closed, group-only, and participated states

## 8. Representative content

Use realistic content so layouts are tested against real constraints.

### Petition examples

- `Sichere Radwege zwischen Innenstadt und Universität`
- `Mehr Schattenplätze auf öffentlichen Spielplätzen`
- `Nachtzüge zwischen europäischen Hauptstädten ausbauen`

Example description:

`Die tägliche Strecke wird von vielen Menschen genutzt, ist an mehreren Kreuzungen aber nicht sicher. Wir fordern eine durchgängige, baulich getrennte Verbindung.`

### Poll examples

- `Welche Öffnungszeiten soll der Nachbarschaftsraum haben?`
- `Soll die Marktstraße an Samstagen autofrei sein?`
- `Welches Projekt soll die Gruppe als Nächstes unterstützen?`

### Metadata examples

- `Freiburg · Verkehr`
- `Deutschland · Bildung`
- `Gruppe: Quartiersrat West`
- `482 Unterschriften`
- `Noch 12 Tage`
- `Bereits teilgenommen`
- `Geschlossen am 18. August 2026`

## 9. Responsive behavior

- Phone is the primary composition.
- At widths below 600 px, use one column and bottom sheets for filters and secondary controls.
- From 600–899 px, keep a centered content column and allow a two-column card grid only when cards remain readable.
- At 900 px and above, navigation may move to a compact rail and detail views may use a supporting side panel.
- Never scale the phone UI uniformly to fill a desktop browser.
- Preserve the app's existing centered maximum-width behavior while allowing the design to use space intentionally.
- Respect safe areas, keyboard insets, landscape, and foldable display features.

## 10. Accessibility and trust requirements

- Meet WCAG 2.2 AA contrast for text and interactive components.
- Maintain a 48 × 48 px minimum touch target.
- Provide visible keyboard focus on web and desktop.
- Every icon-only control has an accessible label and tooltip where applicable.
- Never communicate status by color alone.
- Images have meaningful alternatives or are marked decorative.
- Error messages explain how to recover.
- Confirm destructive actions and name the affected object.
- Make author, visibility, group context, deadline, and participation state easy to find.
- Avoid dark patterns in account deletion, privacy consent, publishing limits, and subscription prompts.
- Do not expose personal voting choices unless the product's privacy rules explicitly allow it.

## 11. Motion

- Motion is functional and brief: 150–250 ms for standard transitions.
- Use subtle container/opacity transitions for filtering and status changes.
- Respect reduced-motion preferences.
- Do not animate vote bars before the submitted result is confirmed.
- No bouncing primary actions, ambient floating shapes, confetti in routine flows, or infinite decorative motion.

## 12. Flutter implementation constraints

- Build on Material 3 and the existing Riverpod architecture.
- Use semantic theme extensions/tokens instead of scattered literal colors.
- Reuse `TriangleLoadingIndicator` for ordinary loading states.
- Keep the determinate `CircularProgressIndicator` exception for profile-picture upload.
- All user-facing copy must come from `AppLocalizations` (`context.l10n`).
- Preserve domain behavior, permissions, Firebase flows, analytics events, test
  keys, screen structure, and recognizable component styling while refining widgets.
- Prefer reusable components for content cards, metadata rows, filter controls, section headers, and state views.
- Remove obsolete visual widgets only after all consumers are migrated.
- Treat Stitch output as a visual specification, not production Flutter code. Rebuild the design using repository components and architecture.

## 13. Google Stitch master prompt

Paste the following into a new Stitch project. Attach screenshots of the current app only when they help communicate data and behavior; instruct Stitch not to copy their visual styling.

```text
Refine the existing StimmApp mobile interface. This is a fidelity-first polish
pass, not a redesign or a request for an alternative concept. The uploaded
screenshots, existing app structure, current theme, and supplied assets are the
visual source of truth.

Keep each screen immediately recognizable: preserve its layout, content order,
navigation, labels, actions, brand colors, Poppins typography, mascot artwork,
icon style, and component character. Aim for 80–90% visual continuity and only
10–20% refinement. Improve spacing consistency, alignment, hierarchy, contrast,
touch targets, and state clarity where necessary. Do not introduce a new color
palette, navigation model, dashboard layout, illustration style, card system,
or decorative motif. Do not add, remove, merge, or relocate features.

Work on one supplied screen at a time. Produce one close, polished revision for
approval before applying any visual decision elsewhere. If no screenshot or
current-screen reference is supplied, ask for one rather than inventing the
screen. Use uploaded assets exactly as directed in DESIGN.md; do not redraw or
reinterpret the logo or Lemm mascot.

Design for the reference screen's viewport, with 390 × 844 px as the default,
in German and with Android/iOS-safe layouts. Retain existing dimensions when
they work. Treat the spacing, radius, and typography values in DESIGN.md as
consistency checks, not permission to reconstruct a screen. Ensure WCAG 2.2 AA
contrast, 48 px touch targets where practical, long German-label support, and
200% text scaling. Never communicate important status through color alone.

The existing product includes these screens; refine only the screen currently
supplied for the active task:
1. Welcome/authentication
2. Petition discovery with search, active/closed tabs, filters, petition cards, profile avatar, create action, and two-item bottom navigation
3. Full-height filter bottom sheet
4. Petition detail before signing and after signing
5. Poll discovery including public, group-only, participated, and closed cards
6. Poll detail before voting and result view with accessible labeled result bars
7. Five-step creator flow: basics, audience, choices/settings, timing/topics, review
8. Profile with grouped activity, community, and account destinations
9. Groups overview
10. Group dashboard with content, members, invitations, activity, admin-election notice, and separate danger section
11. Settings with theme mode and accessible accent selection
12. Component and system-state sheet in light and dark mode

The core bottom navigation has exactly two destinations: Petitionen and
Umfragen. Do not add a third destination or restyle the navigation into a new
pattern. Creation remains contextual and Groups remain accessed from Profile.
Preserve the current list/card treatment unless the supplied screen shows a
specific usability problem. The Lemm mascot may appear only where it already
appears or where explicitly requested; it must not dominate the working interface.

Show realistic German content such as “Sichere Radwege zwischen Innenstadt und Universität”, “482 Unterschriften”, “Noch 12 Tage”, “Bereits teilgenommen”, and “Gruppe: Quartiersrat West”. Include loading, first-use empty, no-filter-results, recoverable error, offline, active, closed, group-only, and participated states.

Do not invent backend capabilities, social feeds, likes, chat, maps,
fundraising, public vote identity, or unrequested interface elements. Make
author, scope, visibility, deadline, privacy context, and participation status
easy to understand while retaining the current composition.
```

## 14. Stitch iteration prompts

Use focused follow-up prompts and refine one screen at a time.

### Conservative polish pass

```text
Polish this exact screen without redesigning it. Preserve its layout, component
placement, colors, assets, content, and actions. Fix only inconsistent spacing,
alignment, hierarchy, contrast, and clearly awkward states. Return one close
revision, not a new concept.
```

### Consistency pass

```text
Rebuild this screen only with the established StimmApp tokens and components. Match the discovery card, app bar, spacing, button hierarchy, metadata styles, and status language already used in the approved screens.
```

### Accessibility pass

```text
Audit this screen for WCAG 2.2 AA contrast, 48 px touch targets, visible focus, non-color status cues, long German labels, screen-reader order, and 200% text scaling. Fix issues without changing product behavior.
```

### Density pass

```text
Improve information density for a 390 px-wide phone. Keep all required metadata, remove redundant containers, align labels and values, and preserve comfortable reading. Do not shrink body text below 14 px or touch targets below 48 px.
```

## 15. Stitch project and MCP handoff

Keep connection-specific identifiers out of source control unless they are intentionally public.

Record the following in a local, uncommitted note or MCP configuration after creating the project:

```text
Stitch project title: StimmApp — Civic Confidence
Stitch project ID: <PROJECT_ID>
Approved screen IDs: <SCREEN_ID_LIST>
Design baseline date: <YYYY-MM-DD>
```

The official Google Cloud Stitch remote MCP endpoint is currently:

```text
https://stitch.googleapis.com/mcp
```

Google documents Stitch as a beta Google Cloud MCP server. Configure authentication and enablement according to the current Google Cloud MCP documentation rather than committing API keys or access tokens to this repository. After connection, the implementation workflow should be:

1. Ask the MCP server to list the Stitch project and screens.
2. Select one approved screen and retrieve its design context/assets.
3. Map its values to this document's semantic tokens and existing Flutter theme.
4. Implement one reusable component or screen slice at a time.
5. Compare at 390 × 844 px, dark mode, narrow 360 px width, German copy, and large text.
6. Run analyzer and relevant widget/integration tests.
7. Record any intentional deviation in this file or a design decision note.

Do not treat exported HTML/CSS as production Flutter code. It is reference material for structure, spacing, type, color, component states, and assets.

## 16. Definition of done for the refinement

- Each approved screen remains immediately recognizable beside its original,
  while the full set forms one consistent system in light and dark mode.
- A participant can identify content type, scope, author, deadline, group context, and participation state without opening secondary menus.
- Primary actions are visually unambiguous and remain reachable with the keyboard open.
- Search and filtering have clear selected and reset states.
- Petition signing and poll voting include review, submission, loading, success, error, and already-participated states.
- Creator forms explain audience and privacy before publishing.
- Group roles and destructive permissions are clear.
- Components work with German and English localization and large text.
- No screen depends on decorative imagery, color alone, or hidden gestures.
- Flutter implementation uses shared semantic tokens/components and passes analyzer and relevant tests.

## 17. External references

Connection details were verified on 2026-08-19. Recheck them before initial MCP setup because Stitch and its MCP support are beta services.

- [Google Cloud MCP supported products](https://docs.cloud.google.com/mcp/supported-products)
- [Google Cloud MCP server management and authentication](https://docs.cloud.google.com/mcp/manage-mcp-servers)
- [Google Developers: Introducing Stitch](https://developers.googleblog.com/en/stitch-a-new-way-to-design-uis/)
