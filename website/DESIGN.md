# StimmApp / Vivot Website Design Brief

Status: source of truth for a new Google Stitch website project  
Primary deliverable: responsive public marketing website  
Implementation target: the existing Next.js site in `website/`  
Languages: German and English  
Brands: StimmApp and Vivot

## 1. Project setup in Stitch

Create a **new Stitch project for the website**. Do not add these screens to the
StimmApp mobile-app project: the website has a different canvas, audience,
navigation model, and conversion goal.

Suggested Stitch project name:

`StimmApp + Vivot — Public Website`

Upload this file as the project's `DESIGN.md`. Upload the following visual assets
alongside it:

- `public/icons/Icon-512.png`
- `public/images/3d-background.png`
- `public/store-badges/app-store-de.svg`
- `public/store-badges/app-store-en.svg`
- `public/store-badges/google-play-de.svg`
- `public/store-badges/google-play-en.svg`

The first Stitch task should create only the desktop and mobile versions of the
home page. Review that direction before generating supporting pages.

## 2. Product and website purpose

StimmApp is a working prototype for digital participation. It helps people create
and take part in petitions and polls. The public website should explain the idea,
build trust, send users to the web or mobile apps, and invite potential partners
from municipalities, government, research, foundations, and other public-interest
organizations to make contact.

This is a marketing site, not the product itself. It must not reproduce the full
application interface or imply capabilities that do not exist.

The same implementation serves two domains:

| Host | Brand | Language | Web app |
| --- | --- | --- | --- |
| `stimmapp.net` | StimmApp | German | `https://web.stimmapp.net` |
| `vivot.net` | Vivot | English | `https://web.vivot.net` |

The layout and visual system stay the same between domains. Brand name, copy,
links, metadata, and localized store badges change by host. Design German first
because its copy is usually longer.

## 3. Primary outcomes

The home page should help a visitor answer, in order:

1. What is this?
2. Is it real and credible?
3. Can I try or download it?
4. Why does the project need partners?
5. How can my organization make contact?

Primary conversion: open or download the product.  
Secondary conversion: contact Trainvent about cooperation.

The page should feel credible enough for a public-sector visitor while remaining
clear and welcoming to an ordinary participant.

## 4. Content contract

Use the existing localized copy in:

- `messages/de.json`
- `messages/en.json`

That copy is the factual source of truth. Stitch may improve hierarchy and split
long passages across sections, but it must not invent partners, testimonials,
usage numbers, awards, security certifications, product capabilities, or public
customers. Do not turn aspirational statements into claims.

Keep these production links unchanged:

- Google Play: `https://play.google.com/store/apps/details?id=de.lemarq.stimmapp`
- App Store: `https://apps.apple.com/app/stimmapp/id6759249651`
- German contact: `https://next.trainvent.com/de/contact/`
- English contact: `https://next.trainvent.com/en/contact/`
- Email: `info@trainvent.com`
- Provider: `https://next.trainvent.com/`

Required footer destinations:

- Privacy
- Terms of service
- Support
- FAQ

## 5. Design direction

### Design statement

**A calm, optimistic civic-tech website that makes participation feel clear,
human, and possible.**

### Desired qualities

- Trustworthy without looking bureaucratic
- Contemporary without following short-lived landing-page trends
- Warm, spacious, and direct
- Civic and public-interest oriented without political symbolism
- Visually distinctive but easy to implement responsively
- Honest about the product's prototype stage

### Avoid

- Political party colors, flags, ballot boxes, government seals, or protest imagery
- Fake dashboards, fake signatures, invented charts, or fictional social proof
- Crypto/finance visual language
- Dense enterprise-software layouts
- Excessive glass panels, glowing effects, gradients on every element, or floating
  decorative cards
- A generic stock-photo hero
- Autoplay video, scroll hijacking, or motion required to understand the page
- Hiding essential copy inside carousels or accordions
- Restyling the official App Store and Google Play badges

## 6. Visual system

The existing website is a useful brand reference, but Stitch may refine its
composition substantially. Preserve recognizable identity through the app icon,
dark green, warm neutrals, and restrained blue accents.

### Color tokens

| Token | Value | Use |
| --- | --- | --- |
| `canvas` | `#F6F6EF` | Main warm page background |
| `surface` | `#FFFFFF` | Cards and high-contrast content areas |
| `surface.subtle` | `#EEF4EA` | Alternating sections and quiet highlights |
| `ink` | `#102018` | Primary text |
| `ink.muted` | `#5B6F63` | Supporting text |
| `brand.green` | `#164F2B` | Primary actions and strong brand moments |
| `brand.greenSoft` | `#DCEFDC` | Selected or supporting brand surfaces |
| `accent.blue` | `#1570EF` | Links, small highlights, and cooperation cues |
| `border` | `rgba(16, 32, 24, 0.12)` | Dividers and component boundaries |

Use blue as an accent, not as a second competing primary color. Ensure normal
text and interactive states meet WCAG AA contrast. Reserve red for errors.

### Typography

Use **Space Grotesk** for the website when available, with `Segoe UI` or a modern
system sans-serif fallback. The website may feel more editorial than the Flutter
app, but readability comes before visual novelty.

- Hero display: 64–80 px desktop, 42–52 px mobile; compact line height
- Section heading: 36–48 px desktop, 30–36 px mobile
- Card heading: 20–24 px
- Body: 17–19 px with 1.55–1.7 line height
- Supporting text: no smaller than 14 px
- Buttons and navigation: 15–16 px, strong weight
- Use sentence case; do not set whole headings in uppercase
- Keep paragraphs around 55–65 characters wide

### Spacing, shape, and elevation

- Use an 8 px spacing grid with 4 px adjustments where needed
- Desktop content width: 1180–1240 px
- Tablet side padding: 32 px
- Mobile side padding: 20 px
- Section spacing: 96–128 px desktop, 64–80 px mobile
- Button height: at least 48 px
- Card radius: 20–28 px
- Button radius: 12–16 px; primary buttons should not look like tiny pills
- Prefer borders and tonal separation over heavy shadows
- Use at most one subtle elevation level for prominent floating surfaces

### Imagery and 3D background

`public/images/3d-background.png` and the current Spline scene may be used as a hero
atmosphere, but content cannot depend on WebGL. The static image is the required
fallback and should still produce a complete design.

- Treat the abstract 3D visual as atmosphere, not a product screenshot
- Keep sufficient contrast behind all text and controls
- Do not put important text directly on a visually busy portion of the image
- Reduce or remove animation when `prefers-reduced-motion` is enabled
- Do not introduce new AI-generated civic imagery or redraw the product icon

## 7. Home page structure

### A. Header

Use a clear, compact header with:

- App icon and current host brand name on the left
- Navigation anchors for `Mission` and `Kontakt` / `Contact` on wider screens
- A prominent `Webapp` / `web app` action on the right
- A simple mobile menu only if the anchors no longer fit

The header may be lightly translucent over the hero, but it must remain readable
without backdrop blur. Keep it sticky only if it does not obscure content.

### B. Hero

The hero must contain:

- The exact localized hero title
- The exact localized hero lede
- App Store and Google Play badges
- A clear link to the web app
- One visual focal point using the supplied app icon and/or abstract 3D artwork
- A visible but secondary cue that the project is seeking cooperation

On desktop, use a balanced two-column composition or a carefully layered
editorial composition. On mobile, stack content in reading order with the title
and primary actions visible before the visual. Do not force the whole page into
one viewport; natural scrolling is preferred.

### C. What the product enables

Create a concise explanation of the product using only established capabilities:

- Petitions
- Polls
- Clear digital participation

This section can use three restrained feature blocks or one product-story
composition. Use meaningful icons only; no fictional screenshots. If real product
screenshots are not provided, use abstract interface fragments or neutral
placeholders clearly presented as illustrative.

### D. Public-interest mission

Explain why calmer participation tools matter, using the existing mission copy.
The section should feel editorial and credible rather than promotional. Give the
words room; do not bury them in three identical marketing cards.

### E. Prototype and cooperation

Clearly state that the product is currently a prototype and is looking for
partners, support, and institutional contacts. Highlight the existing next-step
themes without claiming they already exist:

- Stronger identity verification and possible e-ID support
- Responsible privacy and security work
- Integration into real participation processes
- Cooperation with government, municipalities, research, foundations, or funding
  programs

This is the main secondary-conversion section. Include the localized contact-page
button and `info@trainvent.com`.

### F. Final call to action

End with a concise choice:

- Try the web app / download the app
- Discuss cooperation

Make the two paths visually distinct. Trying the product remains primary for
general visitors; cooperation may become primary when the surrounding section is
explicitly addressed to institutions.

### G. Footer

Include:

- Current host brand
- “provided by Trainvent” relationship using the existing localized wording
- Privacy, terms, support, and FAQ links
- No newsletter field or social icons unless those channels actually exist

## 8. Responsive behavior

Create and review designs at these widths:

- Desktop: 1440 px
- Compact desktop/laptop: 1024 px
- Mobile: 390 px
- Small mobile validation: 360 px

Requirements:

- No horizontal scrolling
- German navigation and calls to action must fit without truncation
- Store badges retain their official aspect ratios and remain legible
- Touch targets are at least 48 × 48 px
- Content order stays logical when columns collapse
- Decorative visuals may crop, simplify, or disappear on small screens
- Primary actions and legal links may not disappear
- The page must remain usable at 200% browser zoom

## 9. Interaction and accessibility

- Use a visible keyboard focus treatment on every interactive element
- Provide descriptive alternative text for meaningful images; decorative imagery
  uses empty alt text
- Never rely on color alone to communicate state
- Respect `prefers-reduced-motion`
- Keep scroll and hover motion subtle, optional, and under roughly 250 ms
- Navigation anchors should land below any sticky header
- External destinations should be visually clear and use secure links
- The site must remain complete if Spline or JavaScript fails

## 10. Supporting routes

After the home page direction is approved, derive restrained templates for:

1. Group-invite redirect/fallback state
2. Privacy policy
3. Terms of service
4. Support
5. FAQ
6. Account deletion

Legal pages prioritize reading comfort: simple header, 680–760 px text column,
clear heading hierarchy, table-of-contents treatment only when useful, and the
same footer. Do not use the 3D hero background behind long legal text.

The group-invite route is a utility state, not a campaign landing page. It needs
only the app icon, short status message, fallback explanation, and return action.

## 11. Stitch generation sequence

1. Generate the German home page at 1440 px and 390 px.
2. Check fidelity to the supplied app icon, colors, exact copy, and required links.
3. Approve the overall direction before expanding it.
4. Generate the English/Vivot variants using the same components and layout.
5. Generate the legal/content template and group-invite utility screen.
6. Use the approved screens as implementation references for the existing
   Next.js code; do not replace working localization or host detection with
   hardcoded mock content.

## 12. Starter prompt for Stitch

Use this after uploading the brief and assets:

> Design the responsive German home page for StimmApp from the attached
> DESIGN.md. Create a 1440 px desktop version and a 390 px mobile version. Follow
> the exact content and factual constraints, reuse the supplied app icon, store
> badges, and abstract 3D background, and keep the experience calm, credible,
> warm, and suitable for both ordinary participants and public-sector partners.
> Use natural vertical scrolling. Clearly distinguish the primary path to try the
> product from the secondary cooperation path. Do not invent screenshots,
> statistics, partners, testimonials, or capabilities. Stop after the home page
> so the direction can be reviewed before generating other routes.
