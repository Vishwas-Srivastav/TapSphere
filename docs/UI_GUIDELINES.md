# User Interface & User Experience Guidelines

These guidelines define the baseline standards for any frontend interface, web page, or user-facing application in this project.

The goal is to maintain a professional, clean, consistent, and functional interface while avoiding unnecessary visual bloat and complexity.

---

## 1. Core Design Philosophy

1. **Function over Decoration:** Every visual element must serve a clear purpose. If an element does not improve clarity or usability, remove it.
2. **Clarity and Hierarchy:** Use typographic hierarchy and whitespace rather than borders, boxes, and heavy background colors to structure content.
3. **Consistency:** Replicate existing component patterns, spacing scales, and color tokens across all pages.
4. **Predictability:** Common interactions (navigation, form submission, dialogs, buttons) should follow standard platform conventions.

---

## 2. Iconography Standards

Interface icons must be crisp, semantic, and render reliably across all operating systems and devices.

### Mandatory Rules

- **Use SVG Icons Exclusively:** Interface icons must be SVG assets (either inline SVGs, an SVG sprite, or a curated icon component).
- **Strictly No Emojis as UI Icons:**
  - **NEVER** use emoji characters (e.g., :rocket: `🚀`, :gear: `⚙`, :x: `❌`, :star: `⭐`, :white_check_mark: `✅`, :bell: `🔔`, :pencil: `📝`) as substitutes for UI buttons, status indicators, or action icons.
  - *Why?* Emojis render inconsistently across operating systems (Apple, Google, Microsoft, Linux), break visual cohesion, cannot be styled via CSS `currentColor`, and carry confusing accessibility semantics.
- **Centralized Asset Management:** Use a single source of truth for icons (e.g., an icon component or `assets/icons/` folder) instead of scattering raw SVG markup across multiple files.
- **Icon Sizing & Alignment:** Standardize on consistent viewBoxes (e.g., `24x24` or `20x20`) and ensure optical alignment with adjacent text.

| Correct Practice | Prohibited Practice |
| :--- | :--- |
| `<Icon name="settings" size={20} />` (renders SVG) | `<span>⚙ Settings</span>` |
| `<Icon name="check-circle" className="text-success" />` | `<span>✅ Completed</span>` |
| `<Icon name="trash" aria-label="Delete" />` | `<button>🗑</button>` |

---

## 3. Visual Styling & Restraint

Keep styling clean and professional. Avoid visual distractions that detract from the core product experience.

### What to Embrace

- **High-contrast, accessible typography:** Ensure text meets WCAG AA contrast standards (minimum 4.5:1 for normal text).
- **Consistent spacing scale:** Use standard 4px / 8px spacing increments (e.g., 4px, 8px, 12px, 16px, 24px, 32px, 48px).
- **Subtle borders and neutral backgrounds:** Use muted neutral tones for card borders and surface backgrounds.
- **Meaningful interactive states:** Clear hover, focus-visible, active, and disabled states for all interactive controls.

### What to Avoid

- **Excessive Animations:** Avoid non-essential bounce, parallax, spinning, or continuous looping animations. Limit transitions to fast, subtle micro-interactions (< 200ms) for state changes.
- **Loud Gradients & Neon Colors:** Avoid gratuitous multi-color background gradients and decorative glows.
- **Heavy Drop Shadows:** Use flat design with subtle single-layer box-shadows where depth is necessary (e.g., dropdown menus and modals).
- **Visual Clutter:** Avoid unnecessary decorative ribbons, badges, borders-within-borders, and ornamental dividers.

---

## 4. Accessibility & Usability

- **Keyboard Navigation:** All interactive elements (`<button>`, `<a>`, `<input>`, `<select>`) must be accessible via Tab key navigation and show a visible focus indicator (`:focus-visible`).
- **Semantic HTML:** Use native elements (`<main>`, `<nav>`, `<header>`, `<article>`, `<section>`, `<button>`) instead of nested `<div>` tags with `onClick` handlers.
- **Descriptive Labels:** Form inputs must have associated `<label>` elements. Icon-only buttons must have `aria-label` or `title` attributes.
- **Responsive Layouts:** Interfaces should scale cleanly across mobile, tablet, and desktop viewports without horizontal scrolling or broken layouts.

---

## 5. Summary Checklist for Code Reviews

When reviewing UI changes, verify:

- [ ] All icons are SVGs; no emojis are used as UI icons.
- [ ] Visual hierarchy is clear and legible.
- [ ] No extraneous animations or decorative clutter were added.
- [ ] Contrast meets accessibility standards.
- [ ] Interactive elements work with keyboard navigation.
- [ ] Layout behaves responsively across standard screen sizes.
