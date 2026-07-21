# Build and Validation Guide

## Contents

1. Repository discovery
2. Default Astro stack
3. Project organization
4. Content and implementation
5. Accessibility and SEO
6. Build and browser verification
7. Launch and handoff

## 1. Repository discovery

Before editing:

- Read `AGENTS.md` and repository-local instructions.
- Inspect the existing package manager, framework, build output, and deployment conventions.
- Search product documentation, UI routes, visible labels, icons, screenshots, supported platforms, integrations, and download locations.
- Check Git status and preserve unrelated user changes.
- Inspect the reference website's HTML and CSS to identify its actual framework. Do not infer a component library from appearance alone.

When a reference uses Astro and utility classes without a runtime component framework, describe it accurately as Astro + Tailwind with custom components.

## 2. Default Astro stack

For a standalone static site, prefer:

```json
{
  "scripts": {
    "dev": "astro dev --host 0.0.0.0",
    "build": "astro build",
    "preview": "astro preview --host 0.0.0.0"
  },
  "dependencies": {
    "@lucide/astro": "<current-compatible-version>",
    "@tailwindcss/vite": "<current-compatible-version>",
    "astro": "<current-stable-version>",
    "tailwindcss": "<current-compatible-version>"
  }
}
```

Configure Tailwind v4 through the Vite plugin and import it from a global stylesheet:

```js
import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  vite: { plugins: [tailwindcss()] }
});
```

```css
@import "tailwindcss";
```

Check current package versions and audit results instead of copying stale versions from this reference.

## 3. Project organization

Use a small structure:

```text
site-directory/
├── astro.config.mjs
├── package.json
├── public/
│   └── product-assets
└── src/
    ├── components/
    │   └── ProductFrame.astro
    ├── pages/
    │   └── index.astro
    └── styles/
        └── global.css
```

Extract a component when it has substantial internal structure, repeated use, or independent responsive behavior. Keep small one-off content sections in the page when extraction would only add indirection.

Add local ignore rules for `node_modules/`, `dist/`, and `.astro/` when the repository does not already cover them.

## 4. Content and implementation

- Build copy from repository evidence and the user's positioning.
- Use concise Chinese product language: direct headline, one supporting paragraph, one primary action, one secondary action.
- Make the primary action a real destination such as download, trial, deployment, or contact.
- If the user asks for pricing but no prices exist, present an explicit quote model rather than inventing currency values.
- Reuse the current product icon and visual identity. Copy binary assets without re-encoding when appropriate.
- Avoid external runtime dependencies for essential layout. External fonts may use system fallbacks.
- Use semantic sections, headings in order, native links and buttons, and structured data where useful.

## 5. Accessibility and SEO

Include:

- Unique page title and concise description
- Favicon and theme color
- Canonical and Open Graph metadata when a final domain is known
- Meaningful image alternative text; empty alt only for decorative assets
- Accessible menu label and state
- Visible keyboard focus states
- Sufficient text and control contrast
- Reduced-motion behavior
- Native disclosure controls for FAQ when possible

Do not publish credentials, internal hostnames, private API endpoints, analytics identifiers copied from the reference, or reference-site tracking scripts.

## 6. Build and browser verification

Run the repository-appropriate equivalents of:

```bash
npm install
npm run build
npm audit --omit=dev
```

Then launch the production output or preview server and verify:

- Local HTTP status is 200
- Requested public HTTP status is 200
- Static assets return successfully
- Navigation anchors exist
- Browser console has no relevant errors
- Product media is nonblank
- No horizontal overflow at desktop or mobile sizes
- No text, icons, controls, or sections overlap
- The next section is hinted at beneath the hero on normal desktop viewports

Capture real-browser screenshots at representative desktop and mobile sizes. Wait for fonts, animations, and product images before capture. Inspect screenshots visually rather than relying only on build success.

For canvas or 3D work, use Playwright and verify nonblank pixels, framing, animation, and interaction across desktop and mobile.

## 7. Launch and handoff

- Bind to `0.0.0.0` when the user requests public access.
- Use the requested port; if occupied, report and use a nearby port only when allowed.
- Confirm the listener with `ss` or the platform equivalent.
- Confirm public access with an HTTP request from the host.
- Keep the server process running through handoff.
- Stage only the requested directory and related files.
- Run `git diff --check`, commit with a scoped message, push, and verify branch synchronization.
- Remove credentials embedded temporarily in Git remote URLs after pushing.
- Report URL, directory, build result, audit result, checked viewports, commit, and push status.
