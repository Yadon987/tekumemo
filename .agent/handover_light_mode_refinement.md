# Handover: Light Mode Design Refinement

## 📜 Basic Rules

**Start by reading `.cursorrules` to understand the project's core guidelines.**
This file contains essential rules for coding style, language (Japanese), and behavior.

## 🎯 Objective

Refine the **Light Mode** design to match the new "Crystal Claymorphism" standard, specifically focusing on the **Home Dashboard (`/home`)** and **Post Timeline**.
The goal is to align the shapes and textures with the Stats/Rankings pages while maintaining the "Pop & Candy" feel of the light mode.

## 📍 Current Status

- **Stats (`/stats`) & Rankings (`/rankings`):**
  - Design Refinement Complete ✅
  - Shape: `rounded-[3.75rem]` (Capsule)
  - Texture: Glass Cover + Soft Shadow
- **Home (`/home`) & Posts:**
  - **Pending Update 🚧**
  - Currently uses older styles (smaller border-radius, stronger shadows).
  - Needs to be updated to the new "Premium Shape" and "Soft Shadow" standards.

## 🛠️ Design Guidelines (Light Mode)

Refer to `.docs/DESIGN_SYSTEM_LIGHT.md` for detailed rules.

### Key Changes to Apply:

1.  **Shape Unification:**
    - Update cards to `rounded-[3.75rem]` (60px) where appropriate (e.g., Post Cards).
    - Ensure consistency with Dark Mode shapes.
2.  **Texture Upgrade:**
    - Apply "Glass Cover" (subtle top gloss) to cards.
    - Reduce shadow opacity (`shadow-clay-card`) for a lighter, floating feel.
3.  **Candy Feel:**
    - Maintain vivid colors for icons and accents.
    - Ensure the "Pop" atmosphere is preserved even with the new shapes.

## 📂 Relevant Files

- `.docs/DESIGN_SYSTEM_LIGHT.md` (Design Rules)
- `app/views/home/index.html.erb` (Dashboard)
- `app/views/posts/_post.html.erb` (Post Card)
- `tailwind.config.js` (Shadow & Color definitions)

## ✅ Definition of Done

- Home dashboard cards and Post timeline cards match the "Premium Crystal" style.
- Light mode feels cohesive with Stats/Rankings pages.
- No regression in Dark Mode (God Mode).
