---
name: landing-page-design
description: Implement landing pages from existing designs. Use when building a landing page from a Figma design, screenshot, mockup, or reference URL. Use when user says "build this landing page", "implement this design", "add a new section", or "create the hero section".
---

This skill is only applicable when creating or editing a landing page in a Rails app that uses Baseline.

## Process

When implementing a new landing page or adding new sections, always start with a planning phase — do not immediately start implementing. Only begin implementation once the plan has been confirmed by the user. For smaller changes to existing sections (copy updates, style tweaks, etc.), this process is not necessary.

### 1. Analyze the source design

Read the source design the user has supplied (Figma, screenshot, mockup, or URL) and divide the landing page into sections.

### 2. Map sections to Baseline partials

For each section in the source design, find the best matching partial from the catalog below. You MUST use an existing partial unless the section is fundamentally incompatible with ALL of them. **Do not write custom HTML for sections that an existing partial can handle** — even if the fit isn't pixel-perfect, partial reuse always wins.

If no partial fits, use the Baseline `section` helper (`baseline/lib/baseline/helper.rb`) to define a custom section.

**Important:** All partials that use the `section` helper automatically render a `headline` and `intro` from i18n when present. **Never add headline or intro markup manually** — just set the i18n keys and the partial handles it.

#### Partial catalog

- **`custom`** — Generic wrapper section. Renders headline + intro from i18n, then yields for custom content.
- **`cols`** — Column grid layout. Yields columns via `row_cols` component. Used as a base by `cards`.
- **`cards`** — Grid of Bootstrap cards from i18n items. Built on `cols`. Use for: feature grids, benefit lists, pricing tiers, team members.
- **`text_image_columns`** — Two-column text + image. Use for: feature highlights, about sections, any text-with-image layout.
- **`accordion`** — FAQ / collapsible items. Built on `custom`. Use for: FAQs, expandable content lists.

Read each partial's source file for locals and i18n keys during implementation.

### 3. Present the plan

Present the section-by-section plan to the user, showing which partial (or custom section) will be used for each part of the design. Wait for confirmation before proceeding.

### 4. Implement

Once the plan is confirmed, build the landing page section by section.

## Reuse over pixel-perfection

Reusing existing components, partials, helpers, and styles from the app or Baseline is more important than implementing the landing page 100% pixel-perfect to the source design. Before planning, study what the app and Baseline have to offer — check other landing pages in the app for reusable patterns and conventions.

## Image naming

Name images after their section. For background images, append `_bg`. If a section has multiple images, append `_01`, `_02`, etc.

Examples: `hero_bg`, `features_01`, `features_02`.

### Buttons

Use Bootstrap button classes (e.g. `class="btn btn-primary"` or `class="btn btn-secondary"`) instead of generating custom buttons, even if they look slightly different from the buttons in the source design. After implementation, if the buttons differ from the source design, mention this to the user and suggest options to customize the buttons (while keeping the base Bootstrap button classes) in specific sections.

### Colors

Prefer `$primary`, `$secondary`, and any existing hex colors defined in custom Sass variables (check the Sass files in the "web" namespace) over defining new Sass/CSS variables or using hard-coded hex values.
