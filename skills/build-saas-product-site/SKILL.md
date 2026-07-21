---
name: build-saas-product-site
description: Build or redesign polished, product-led SaaS and software websites with a restrained Novaix-like visual language using Astro, Tailwind CSS, Lucide icons, real product visuals, responsive layouts, and production verification. Use when Codex needs to create a product homepage or official website, imitate a clean reference site's UI and page rhythm without copying its brand, turn an existing application into a marketing site, build an Astro/Tailwind landing page, present a dashboard or desktop product convincingly, or validate and launch the finished site on a requested port.
---

# Build SaaS Product Site

Build the real product website as the first screen. Preserve the reference site's visual logic while replacing its brand, copy, assets, product UI, and product claims with evidence from the target repository.

## Required workflow

1. Inspect repository instructions, the current frontend stack, product documentation, existing icons, screenshots, routes, and visible product copy.
2. Inspect the reference site with source HTML, compiled CSS, public assets, and screenshots. Identify its framework, spacing system, typography, palette, section rhythm, responsive behavior, and motion.
3. Summarize the inferred design system before editing. Separate reusable design rules from reference-specific content.
4. Choose the implementation in sympathy with the repository. For a new standalone static product site, default to Astro + Tailwind CSS v4 + `@lucide/astro`.
5. Design the information architecture around the real product: navigation, hero, proof strip, primary capabilities, workflow, platform or deployment support, FAQ, pricing or contact CTA, and footer.
6. Implement feature-complete desktop and mobile states. Use actual product screenshots when available; otherwise construct a faithful HTML/CSS product view from real application screens and data concepts.
7. Build, audit, run, screenshot, and inspect the result. Correct overflow, blank media, weak hierarchy, excessive whitespace, overlapping content, and mobile regressions before handoff.
8. When requested, start the server on `0.0.0.0:<port>`, verify the public address, commit only scoped files, and push to the requested repository.

## Design requirements

Read [references/design-system.md](references/design-system.md) before writing UI or CSS.

Apply these non-negotiable rules:

- Make the product name and product interface visible in the first viewport.
- Use a quiet neutral foundation with one brand accent and a few semantic support colors.
- Prefer full-width sections and divided layouts. Use cards only for repeated items, modals, pricing options, or genuine tool frames.
- Treat the hero product view as a real interface, not a decorative illustration.
- Match the reference's density, spacing, border treatment, and section sequence without copying its logo, text, screenshots, or proprietary assets.
- Use Lucide icons for interface actions and concepts. Do not draw substitute SVG icons when a suitable Lucide icon exists.
- Keep headings proportionate to their containers. Do not scale typography continuously with viewport width or use negative letter spacing.
- Keep all controls, labels, and long Chinese or English strings inside their containers at common desktop and mobile widths.
- Include subtle scroll and interface motion, plus `prefers-reduced-motion` fallbacks.
- Do not invent product capabilities, prices, integrations, security claims, or platform support. Derive claims from repository evidence.

## Build requirements

Read [references/build-validation.md](references/build-validation.md) before selecting dependencies, starting a server, or declaring completion.

- Prefer the repository's existing framework when extending an existing site.
- For a new static site, use a small dependency surface and static output.
- Put the site in the directory requested by the user and keep it independently buildable.
- Use structured components for complex product visuals; do not place the entire implementation in one unreadable file when clear component boundaries exist.
- Reuse existing product icons and screenshots. Do not expose secrets, internal credentials, private API responses, or production-only URLs in the page.
- Ensure navigation targets exist and calls to action have meaningful destinations.
- Run the production build and dependency audit.
- Verify desktop and mobile screenshots with a real browser. Inspect at least the hero, a middle feature section, the dark or high-contrast section, and the final CTA or FAQ.
- Verify the requested local and public URL with an HTTP request after launch.

## Reference routing

- Read [references/design-system.md](references/design-system.md) for layout dimensions, color use, typography, product-frame composition, motion, responsive rules, and anti-patterns.
- Read [references/build-validation.md](references/build-validation.md) for Astro/Tailwind setup, project organization, SEO, accessibility, browser verification, deployment, and Git handoff.

## Completion report

Report the public or local URL, implementation directory, framework, build result, browser viewports checked, commit identifier, and push status. State any unavailable destination, missing product asset, or unverified external behavior explicitly.
