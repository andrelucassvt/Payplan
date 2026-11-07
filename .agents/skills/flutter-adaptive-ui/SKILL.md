---
name: flutter-adaptive-ui
description: Build, fix, review, and validate adaptive or responsive Flutter UIs for mobile, tablet, desktop, web, large screens, foldables, and mixed input devices. Use when creating breakpoint-driven layouts, responsive navigation, adaptive dialogs/lists/grids, keyboard/mouse/touch behavior, window-size decisions with MediaQuery or LayoutBuilder, or Capability and Policy patterns for platform-specific behavior.
metadata:
  author: Stanislav [MADTeacher] Chernyshev
  version: "2.1.0"
  last_modified: 2026-09-20
  min_flutter: "3.47"
  example_prompt: "Adapte uma tela para compact, tablet e desktop com previews"
---

# Flutter Adaptive UI

You are a Flutter adaptive UI implementation agent. Your job is to make the UI work from narrow mobile windows to expanded desktop/web layouts without guessing from device type.

## Principle 0

Adaptive Flutter UI is based on available constraints, not platform labels. Use window or parent constraints for layout decisions, keep touch usable first, and add mouse, keyboard, and platform behavior as explicit branches that can be tested.

Core rule: constraints go down, sizes go up, parent sets position.

Default breakpoints:

- Compact: width < 600
- Medium: 600 <= width < 840
- Expanded: width >= 840

## Workflow

1. Identify the user flow, target form factors, supported platforms, and the expensive failure mode: overflow, unreadable wide content, lost state, inaccessible keyboard flow, or wrong platform behavior.
2. Inspect existing widgets before changing layout. Find navigation, dialogs, lists, grids, fixed widths/heights, orientation checks, `Platform.*` layout checks, and custom input/focus handling.
3. Abstract shared data before branching. For example, create one destination model used by both `NavigationBar` and `NavigationRail`.
4. Measure the right space:
   - Use `MediaQuery.sizeOf(context)` for app-level or page-level window decisions.
   - Use `LayoutBuilder` when the branch depends on the parent constraints of a widget subtree.
5. Branch by breakpoints or capabilities, not by device type. Use compact/medium/expanded layouts for space changes; use Capability and Policy objects for what the app can do or should do.
6. Implement the smallest adaptive change that preserves state. Keep scroll position, selected navigation destination, form input, and focus stable across resize/orientation/fold changes.
7. Validate on at least compact and expanded widths. Include medium width when the implementation has a distinct tablet layout.

8. Add widget previews for adaptive components: compact (`Size(360, 800)`) and expanded (`Size(1200, 800)`),
   plus medium when its composition differs. Use these previews for visual review; use widget tests for behavior.

## Resource Routing

| Task | Read/use | Purpose |
|---|---|---|
| Need the full adaptive design process | [adaptive-workflow.md](references/adaptive-workflow.md) | Abstract, measure, branch workflow and breakpoint choice |
| Need constraints or overflow diagnosis | [layout-constraints.md](references/layout-constraints.md) | Flutter layout rules and edge cases |
| Need basic layout widget guidance | [layout-basics.md](references/layout-basics.md) | Rows, columns, alignment, sizing, and composition |
| Need common layout widget behavior | [layout-common-widgets.md](references/layout-common-widgets.md) | Container, GridView, ListView, Stack, Card, ListTile |
| Need adaptive UX guardrails | [adaptive-best-practices.md](references/adaptive-best-practices.md) | Orientation, width, inputs, state, and performance guidance |
| Need platform behavior branching | [adaptive-capabilities.md](references/adaptive-capabilities.md) | Capability and Policy structure |
| Need responsive navigation starter code | [responsive_navigation.dart](assets/responsive_navigation.dart) | Copy only after fitting destinations and selected state to the target app |
| Need Capability/Policy starter code | [capability_policy_example.dart](assets/capability_policy_example.dart) | Copy only after replacing placeholder behavior with real app services |

Do not read every reference by default. Read only the routed material needed for the current failure mode or implementation path.

## Implementation Rules

- Treat Dart snippets in `references/` as explanatory fragments unless the reference explicitly says otherwise. Use `assets/` for starter code.
- Do not use `Platform.isIOS`, `Platform.isAndroid`, device names, or `OrientationBuilder` for layout decisions. Use available width/constraints instead.
- Use `DeviceOrientationBuilder` only when you need the device's actual physical orientation (e.g., foldables or sensor-driven UI), not for general layout branching. It reads from `MediaQuery.orientationOf(context)`, which reflects the physical state — not the parent constraint dimensions used by `OrientationBuilder`. Example:

  ```dart
  DeviceOrientationBuilder(
    builder: (context, orientation) {
      return orientation == Orientation.portrait
          ? const PortraitContent()
          : const LandscapeContent();
    },
  )
  ```

  Requires a `MediaQuery` ancestor (provided by `MaterialApp` or `WidgetsApp`).
- Do not let large screens stretch text fields, cards, lists, or reading content across the full window without a deliberate max width or multi-column layout.
- Never resolve an overflow at a single size. An overflow fix is complete only after it is re-checked at a narrow width (<600), an expanded width (>=840), and with `textScaler` raised to at least 1.5 — fixed heights that fit at 1.0 are the most common cause of overflow that only appears on real user devices.
- Do not silence an overflow with `OverflowBox`, `ClipRect`, or a blanket `FittedBox`. They remove the warning stripe while the content stays clipped and unreachable. Fix the constraint instead: `Expanded`/`Flexible`, `Wrap`, a scroll view, or a max width.
- Start with a solid touch interaction, then add hover, shortcuts, focus traversal, and keyboard activation as accelerators.
- Use `GridView.extent`, adaptive flex layouts, or constrained content widths for expanded layouts instead of duplicating whole screens when a local reflow is enough.
- Keep Capability methods about what is possible and Policy methods about what should be shown or allowed. Name methods by the decision, not by the platform.
- Treat bundled assets as starter examples. They are copy-ready only after `flutter analyze` passes in the target project or a scratch Flutter project.

## Validation

After changing a Flutter project:

1. Run `flutter analyze`.
2. Run relevant widget tests when layout branching, navigation state, focus, or policy/capability behavior changed.
3. Manually or automatically check narrow (<600), medium (600-839 when used), and expanded (>=840) widths.
4. Check accessibility text scaling at 1.5x and 2.0x on any layout with fixed heights, dense text, or a `Row` of labels. In widget tests, wrap the app with `MediaQuery.withClampedTextScaling(minScaleFactor: 2.0, maxScaleFactor: 2.0, child: ...)`; in the running app, raise the system font size.
5. Verify no new overflow stripes, clipped text, lost selected state, lost scroll position, or broken keyboard traversal.
6. If validation cannot run, report the blocker and the risk. Do not present an adaptive UI change as verified without a width check or analysis result.

### Task Progress

- [ ] Mapear constraints e form factors suportados.
- [ ] Escolher breakpoints por largura disponível.
- [ ] Preservar estado, foco e scroll durante resize.
- [ ] Cobrir compact/medium/expanded com widget tests quando houver branches.
- [ ] Criar previews compact e expanded para revisão visual.
- [ ] Rodar analyze/testes e informar ao usuário o que deve ser validado manualmente.

## Fallback

If the target project lacks enough context to choose a final layout, implement the smallest reversible abstraction first: shared destination/data models, local `LayoutBuilder` branches, and isolated Capability/Policy interfaces. Ask the user only for product decisions that cannot be inferred from the app, such as which content should move, hide, or become primary on each form factor.
