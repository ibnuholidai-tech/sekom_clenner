# Sekom UI Sample Refresh Design

## Goal

Refresh the whole modern Sekom Cleaner interface so it follows the provided sample screens more closely while preserving the existing feature set. The new shell should feel like the sample version: a wide light-blue header, centered "SEKOM Group" title, horizontal icon navigation, light gray app background, and large soft cards.

## Scope

- Replace the current left sidebar shell in `ModernMainScreen` with a top navigation shell.
- Keep all seven current modern pages available:
  - System Cleaner
  - Shortcut
  - Battery Health
  - Optimization
  - Info System
  - Testing
  - Reset
- Style the global theme and shared modern widgets toward the sample:
  - Light blue header.
  - Pale gray content background.
  - White or very light cards.
  - Low-radius rounded cards and buttons.
  - Thin borders and subtle shadows.
- Preserve existing screen behavior and services.

## Out Of Scope

- Rewriting cleaning, battery, testing, or shortcut business logic.
- Removing any current page.
- Adding new functionality beyond the visual refresh.
- Rebuilding every legacy embedded screen from scratch.

## Approach

Use a sample-inspired responsive shell:

- `ModernMainScreen` becomes a vertical layout:
  - Top header with title and horizontal nav.
  - Scrollable horizontal navigation when width is tight.
  - Expanded content area below.
- Existing page widgets remain the route targets so their behavior stays intact.
- Shared tokens in `AppTheme` become the source of the sample colors, borders, and shadows.
- Shared widgets such as `ModernCard`, `ModernPageHeader`, badges, and pills are adjusted gently so existing pages inherit the look.

This is safer than a full page-by-page rewrite because it gives the app the requested visual identity first while limiting behavior risk.

## Component Design

### Top Shell

`ModernMainScreen` owns the navigation state and renders a header similar to the sample. Each nav item shows a large icon above a label. Active items use stronger white text/icon opacity and an underline/accent indicator so the selected page is obvious.

### Content Area

The content area uses the sample's pale gray background and minimal padding. Page content should sit directly on that background or inside large cards, not inside the previous rounded white sidebar container.

### Shared Cards

`ModernCard` keeps its API but uses:

- Softer sample-style background.
- Radius around 8-12 px.
- Thin border.
- Very subtle shadow.

### Existing Pages

Pages continue using existing widgets and service calls. Screens currently wrapping legacy pages, such as Battery and Testing, keep their embedded child screens but receive sample-style surrounding layout.

## Responsive Behavior

At desktop width, all seven navigation items try to fit evenly across the header. If the app window becomes narrow, the navigation becomes horizontally scrollable instead of wrapping awkwardly or shrinking text too far.

## Error Handling

No new service calls are introduced, so existing error handling remains unchanged. Visual refactor should not change exception paths, confirmations, or destructive-action warnings.

## Testing

Run Flutter static analysis after changes. If possible, launch the Windows app or run existing widget tests to catch layout/build errors. Visual verification should check:

- Header and navigation resemble the sample.
- All seven pages are reachable.
- Text does not overflow in the top navigation.
- Existing buttons and cards remain usable.

