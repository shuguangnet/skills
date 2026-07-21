# Product Website Design System

## Contents

1. Visual intent
2. Layout and section rhythm
3. Color and typography
4. Product visuals
5. Components and interaction
6. Responsive behavior
7. Motion
8. Anti-patterns

## 1. Visual intent

Create a quiet, precise software-product presentation. The page should feel like the product interface extended into a website: clean white space, thin neutral borders, direct typography, small controls, and evidence-rich visuals.

Extract principles from a reference site, not literal assets. Preserve its composition, density, and interaction behavior while creating an original brand expression.

## 2. Layout and section rhythm

- Use a centered content width near `72rem` (`max-w-6xl`) with `1.5rem` horizontal padding.
- Use a fixed transparent header that becomes an `rgba(255,255,255,.82-.9)` blurred surface after scrolling.
- Build the desktop hero as roughly `1fr 1.1-1.2fr`: copy on the left, product UI on the right.
- Start the hero near `7rem` on mobile, `9rem` on small desktop, and `10rem` on wide desktop.
- Keep the first desktop viewport product-focused and leave a visible hint of the following proof strip or section.
- Use section padding around `5rem` mobile and `7rem` desktop.
- Alternate feature sections between white and very light neutral bands. Alternate text and visual sides where it improves scanning.
- Use borders or dividers to organize adjacent content. Do not turn every section into a floating card.
- Use one high-contrast dark section for a dense capability matrix or technical proof.

Recommended sequence:

1. Fixed navigation
2. Hero with real product view
3. Compact proof strip
4. Two-column primary features
5. Alternating feature bands
6. Dark capability matrix
7. Workflow, deployment, or platform section
8. FAQ
9. Pricing or contact CTA
10. Dark footer

## 3. Color and typography

Use a neutral zinc-like scale:

- Primary text: near `#18181b`
- Body text: near `#71717a`
- Muted text: near `#a1a1aa`
- Border: near `#e4e4e7`
- Light band: near `#fafafa`
- Dark band: near `#18181b` or `#09090b`

Choose one accent from the actual brand. Use it for primary actions, small labels, progress, selected navigation, and focus states. Add semantic emerald, amber, rose, or violet only when the product state requires them. Avoid a page dominated by variants of one hue.

Typography defaults:

- Chinese body: `Noto Sans SC`, system sans fallback
- Display and numbers: `Sora`, then Chinese/system fallback
- Technical labels: `JetBrains Mono`, then monospace fallback
- Hero: approximately `2.6rem` mobile, `3rem` tablet, `3.5rem` desktop
- Section heading: `1.5rem` mobile, `1.875rem` desktop
- Body: `0.95-1.05rem`, relaxed line height
- Navigation and compact UI: `0.75-0.875rem`
- Use font weights 400, 500, 600, and 700. Reserve 800 for rare emphasis.
- Keep letter spacing at `0`. Use capitalization, weight, font family, or color for hierarchy.

## 4. Product visuals

Prefer visuals in this order:

1. Current product screenshot supplied by the repository or running application
2. Browser screenshot captured from the product with safe representative data
3. HTML/CSS reconstruction grounded in real routes, terminology, states, and visual identity
4. Generated raster asset only when the product itself cannot provide the needed subject

Frame a desktop product view with:

- `1px` neutral border
- `16px` outer radius at most
- `4px` outer padding
- small red, amber, and green window controls
- `16:10` stable aspect ratio
- subtle ring and shadow
- optional desktop perspective around `rotateY(-8deg) rotateX(3deg)`, relaxing on hover

Inside the product view, use realistic information density: sidebar, header, three or four metrics, chart or progress state, and a secondary detail panel. Keep tiny copy legible and prevent it from resizing the frame.

Do not use atmospheric stock art, abstract gradient illustrations, decorative SVG scenes, blurred screenshots, or fake interfaces unrelated to the repository.

## 5. Components and interaction

- Buttons: `8px` radius, compact vertical padding, stable height, clear hover and focus states.
- Product panels: `8-12px` radius with `1px` border; avoid heavy shadows.
- Pricing cards: use only when actual tiers or a clear quote model exists.
- FAQ: native `details/summary`, divided rows, plus icon rotating on open.
- Mobile menu: icon button with accessible label and `aria-expanded`; close after navigation.
- Use text buttons only for clear commands. Use familiar icons for menu, download, play, settings, and navigation actions.
- Ensure every visible navigation item resolves to a real section or valid external destination.

## 6. Responsive behavior

Check at least `1440x1000`, `1024x768`, `390x844`, and `360x800`.

- Collapse desktop navigation below `48rem`.
- Stack the hero into text then product visual on mobile.
- Keep primary CTA buttons visible without horizontal scrolling.
- Reduce or hide nonessential labels inside small product mockups while retaining icons and primary metrics.
- Replace desktop vertical dividers with horizontal dividers when columns stack.
- Use stable grid tracks and aspect ratios so loading text, icons, and changing numbers do not shift layout.
- Allow Chinese text to wrap naturally. Break long technical strings when necessary.

## 7. Motion

Use motion to reveal hierarchy, not decorate empty space.

- Scroll reveal: opacity plus `30-40px` vertical movement over `0.8-0.9s` with `cubic-bezier(.16,1,.3,1)`.
- Side reveal: limit horizontal movement to `64-80px`, and convert it to vertical movement on mobile.
- Product frame hover: subtle perspective reduction, not a large lift.
- Charts: optional one-time stroke draw after the hero appears.
- Header: blur and shadow after roughly `16px` scroll.
- Always disable or simplify motion under `prefers-reduced-motion: reduce`.

## 8. Anti-patterns

- Marketing-first splash screen that delays access to the product
- Oversized generic headline with no product visual in the first viewport
- Page sections styled as floating cards
- Cards nested inside decorative cards
- Purple-blue gradient dominance, monochrome navy, beige, or brown themes without brand justification
- Decorative orbs, bokeh, gradient blobs, and empty illustration space
- Copied reference branding, copy, screenshots, or logos
- Claims such as unlimited scale, military-grade encryption, or guaranteed availability without evidence
- Icons made from improvised SVG paths when a Lucide icon exists
- Desktop-only layout that merely shrinks on mobile
- Buttons pointing to missing anchors or private repositories users cannot access
