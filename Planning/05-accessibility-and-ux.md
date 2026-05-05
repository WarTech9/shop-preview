# 05 — Accessibility & UX

Accessibility is part of the spec, not a polish pass. Every screen is designed to be usable with VoiceOver, Switch Control, Voice Control, Dynamic Type, and Reduce Motion enabled.

## Cross-cutting rules

- **Hit targets ≥ 44×44pt** for every tap target (Apple HIG). Steppers, picker chips, and tab bar items are sized accordingly.
- **Dynamic Type** up to `accessibilityXXXLarge`. Text uses semantic styles (`.body`, `.headline`, `.title3`) — never fixed `.system(size:)` for content. Critical labels (price, "Add to Cart") truncate with `.lineLimit(2)` + `.minimumScaleFactor(0.85)` rather than disappearing.
- **Color is never the sole signal.** "Out of stock" carries text + a strikethrough, not just a colour change. AccentColor passes WCAG AA against background in both light and dark mode.
- **Reduce Motion**: image carousel honours `@Environment(\.accessibilityReduceMotion)` — page transitions become crossfades.
- **Reduce Transparency / Increase Contrast** respected automatically by using system materials (`.regularMaterial`) and system colours (`Color(.systemBackground)`).
- **Respect Larger Text safe areas** — content scrolls; nothing critical sits in a fixed bottom bar that gets covered.

## Per-screen specifics

### Catalog

- Each row: `accessibilityElement(children: .combine)` so VoiceOver reads "Unisex Hoodie, $32.09 Canadian dollars, available" as one swipe stop.
- `accessibilityHint("Opens product details")`.
- Loading skeleton has `accessibilityHidden(true)` so VoiceOver doesn't announce empty rows.
- Empty state ("No products yet") is announced once via `accessibilityAddTraits(.isHeader)`.

### Product Details

- Image carousel: each page has `accessibilityLabel("Product image \(i) of \(n)")`. Carousel itself uses `.accessibilityScrollAction` so VoiceOver can flip pages.
- Variant pickers: rendered as horizontal chip rows. Each chip is a `Toggle` semantically (`accessibilityAddTraits(.isButton)`, `accessibilityValue("selected")` when active, `.isNotEnabled` trait when out-of-stock).
- The disabled-chip rule (F3.3) is announced: out-of-stock chips read "Black, out of stock, dimmed."
- Price block: combined into one accessibility element; compare-at price reads as "Was 45 dollars" rather than the literal strikethrough.
- "Add to Cart" button has `accessibilityLabel("Add to cart")` and `accessibilityHint("Adds \(variant.title) to your cart")`. When disabled, hint becomes "Select all options to enable."
- After tap: a haptic + a `.accessibilityAnnouncement` ("Added to cart, \(itemCount) items") so non-visual users get the same confirmation as a toast.

### Cart

- Each line: combined element reading "Unisex Hoodie, Black / Small, quantity 2, line total 64 dollars."
- Quantity stepper uses native `Stepper` (it has correct VoiceOver semantics out of the box: increment/decrement actions, value announcement).
- Totals block: `accessibilityElement(children: .combine)`, label "Subtotal 64 dollars, total 64 dollars, 2 items."
- Empty cart: large, friendly, with a CTA to Catalog. `accessibilityAddTraits(.isHeader)` on the headline.

## State copy

| State | Catalog | Details | Cart |
|---|---|---|---|
| Loading | Skeleton rows (3 visible) | Skeleton image + title + price | Skeleton lines (1) |
| Empty | "No products available right now." + retry | n/a | "Your cart is empty." + "Browse products" |
| Error: offline | "You're offline. Check your connection and try again." + retry | same | n/a (cart is local) |
| Error: server | "Something went wrong. Please try again." + retry | same | n/a |
| Error: notFound | n/a | "We couldn't find that product." + "Browse catalog" | n/a |

Copy is short, blameless, and actionable. No raw error messages are ever surfaced.

## Layout adaptation

- All screens use `ScrollView` / `List` so they remain usable when Dynamic Type pushes content past the viewport.
- iPad: same layouts (one column). A two-column adaptation is out of scope but is called out in the Decision Log under "what I'd improve."
- Landscape: layouts work because they're vertical-scroll first. The Details image carousel constrains to `aspectRatio(1, contentMode: .fit)` so it doesn't dominate landscape.

## Manual QA checklist (run before submission)

1. VoiceOver on, swipe through every screen — every actionable element is reachable and labelled.
2. Dynamic Type set to XXL — no text truncated, no overlap, no buttons clipped.
3. Reduce Motion on — carousel transitions are crossfades, no slide.
4. Increase Contrast on — chips, buttons, and dividers remain visible.
5. Switch Control on — focus visits things in reading order.
6. Tap-target audit: any button below 44pt is a bug.
