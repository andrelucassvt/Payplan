---
name: "flutter-animating-apps"
description: "Implements animated effects, transitions, and motion in a Flutter app. Covers implicit animations (AnimatedContainer, AnimatedOpacity, TweenAnimationBuilder), explicit animations (AnimationController, Tween, CurvedAnimation, AnimatedBuilder), Hero transitions, staggered animations, physics-based animations (SpringSimulation), page route transitions, and AnimatedList. Use when adding visual feedback, shared element transitions, physics-based animations, loading skeletons, shimmer effects, or animated onboarding flows. Activate even when the user says 'animate this widget', 'smooth transition between screens', 'fade in on load', 'slide from bottom', 'bouncy button effect', 'Hero animation between pages', 'make this feel more fluid', or 'animate a list item appearing' without explicitly mentioning AnimationController or Tween."


---
# Implementing Flutter Animations

## Core Concepts

Manage Flutter animations using the core typed `Animation` system. Do not manually calculate frames; rely on the framework's ticker and interpolation classes.

*   **`Animation<T>`**: Treat this as an abstract representation of a value that changes over time. It holds state (completed, dismissed) and notifies listeners, but knows nothing about the UI.
*   **`AnimationController`**: Instantiate this to drive the animation. It generates values (typically 0.0 to 1.0) tied to the screen refresh rate. Always provide a `vsync` (usually via `SingleTickerProviderStateMixin`) to prevent offscreen resource consumption. Always `dispose()` controllers to prevent memory leaks.
*   **`Tween<T>`**: Define a stateless mapping from an input range (usually 0.0-1.0) to an output type (e.g., `Color`, `Offset`, `double`). Chain tweens with curves using `.animate()`.
*   **`Curve`**: Apply non-linear timing (e.g., `Curves.easeIn`, `Curves.bounceOut`) to an animation using a `CurvedAnimation` or `CurveTween`.

## Animation Strategies

Apply conditional logic to select the correct animation approach:

*   **If animating simple property changes (size, color, opacity) without playback control:** Use **Implicit Animations** (e.g., `AnimatedContainer`, `AnimatedOpacity`, `TweenAnimationBuilder`).
*   **If requiring playback control (play, pause, reverse, loop) or coordinating multiple properties:** Use **Explicit Animations** (e.g., `AnimationController` with `AnimatedBuilder` or `AnimatedWidget`).
*   **If animating elements between two distinct routes:** Use **Hero Animations** (Shared Element Transitions).
*   **If modeling real-world motion (e.g., snapping back after a drag):** Use **Physics-Based Animations** (e.g., `SpringSimulation`).
*   **If animating a sequence of overlapping or delayed motions:** Use **Staggered Animations** (multiple `Tween`s driven by a single `AnimationController` using `Interval` curves).

## Workflows

### Implementing Implicit Animations

Use this workflow for "fire-and-forget" state-driven animations.

- [ ] **Task Progress:**
  - [ ] Identify the target properties to animate (e.g., width, color).
  - [ ] Replace the static widget (e.g., `Container`) with its animated counterpart (e.g., `AnimatedContainer`).
  - [ ] Define the `duration` property.
  - [ ] (Optional) Define the `curve` property for non-linear motion.
  - [ ] Trigger the animation by updating the properties inside a `setState()` call.
  - [ ] Run validator -> review UI for jank -> adjust duration/curve if necessary.

### Implementing Explicit Animations

Use this workflow when you need granular control over the animation lifecycle.

- [ ] **Task Progress:**
  - [ ] Add `SingleTickerProviderStateMixin` (or `TickerProviderStateMixin` for multiple controllers) to the `State` class.
  - [ ] Initialize an `AnimationController` in `initState()`, providing `vsync: this` and a `duration`.
  - [ ] Define a `Tween` and chain it to the controller using `.animate()`.
  - [ ] Wrap the target UI in an `AnimatedBuilder` (preferred for complex trees) or subclass `AnimatedWidget`.
  - [ ] Pass the `Animation` object to the `AnimatedBuilder`'s `animation` property.
  - [ ] Control playback using `controller.forward()`, `controller.reverse()`, or `controller.repeat()`.
  - [ ] Call `controller.dispose()` in the `dispose()` method.
  - [ ] Run validator -> check for memory leaks -> ensure `dispose()` is called.

### Implementing Hero Transitions

Use this workflow to fly a widget between two routes.

- [ ] **Task Progress:**
  - [ ] Wrap the source widget in a `Hero` widget.
  - [ ] Assign a unique, data-driven `tag` to the source `Hero`.
  - [ ] Wrap the destination widget in a `Hero` widget.
  - [ ] Assign the *exact same* `tag` to the destination `Hero`.
  - [ ] Ensure the widget trees inside both `Hero` widgets are visually similar to prevent jarring jumps.
  - [ ] Trigger the transition by pushing the destination route via `Navigator`.

### Implementing Physics-Based Animations

Use this workflow for gesture-driven, natural motion.

- [ ] **Task Progress:**
  - [ ] Set up an `AnimationController` (do not set a fixed duration).
  - [ ] Capture gesture velocity using a `GestureDetector` (e.g., `onPanEnd` providing `DragEndDetails`).
  - [ ] Convert the pixel velocity to the coordinate space of the animating property.
  - [ ] Instantiate a `SpringSimulation` with mass, stiffness, damping, and the calculated velocity.
  - [ ] Drive the controller using `controller.animateWith(simulation)`.

## Examples

<details>
<summary><b>Example: Explicit Animation (Staggered with AnimatedBuilder)</b></summary>

```dart
class StaggeredAnimationDemo extends StatefulWidget {
  @override
  State<StaggeredAnimationDemo> createState() => _StaggeredAnimationDemoState();
}

class _StaggeredAnimationDemoState extends State<StaggeredAnimationDemo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Staggered width animation (0.0 to 0.5 interval)
    _widthAnimation = Tween<double>(begin: 50.0, end: 200.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Staggered color animation (0.5 to 1.0 interval)
    _colorAnimation = ColorTween(begin: Colors.blue, end: Colors.red).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose(); // CRITICAL: Prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: _widthAnimation.value,
          height: 50.0,
          color: _colorAnimation.value,
        );
      },
    );
  }
}
```
</details>

<details>
<summary><b>Example: Custom Page Route Transition</b></summary>

```dart
Route createCustomRoute(Widget destination) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => destination,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0); // Start from bottom
      const end = Offset.zero;
      const curve = Curves.easeOut;

      final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      final offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
  );
}

// Usage: Navigator.of(context).push(createCustomRoute(const NextPage()));
```
</details>


## Anti-patterns

Evite estes erros comuns ao implementar animações:

| Anti-pattern | Por quê é ruim | Correto |
|---|---|---|
| Esquecer `controller.dispose()` no `dispose()` | Vazamento de memória — ticker continua rodando após widget ser desmontado | Sempre chame `controller.dispose()` em `dispose()` |
| Criar `AnimationController` sem `vsync` | Animação continua consumindo recursos mesmo quando a tela não está visível | Use `SingleTickerProviderStateMixin` e passe `vsync: this` |
| `TickerProviderStateMixin` com um único controller | Funciona, mas indica uso incorreto do mixin | Use `SingleTickerProviderStateMixin` para 1 controller; `TickerProviderStateMixin` para 2+ |
| Usar `setState()` com `addListener()` para rebuildar UI | Reconstrói toda a subárvore — causa jank em árvores complexas | Use `AnimatedBuilder` que reconstrói apenas o builder |
| Animar dentro de `build()` (`controller.forward()` no build) | Cria loop infinito de builds ou reinicia a animação a cada rebuild | Inicie animações em `initState()`, callbacks ou `BlocListener` |
| `Duration.zero` ou duração extremamente curta | Animação imperceptível, transição brusca — igual a não animar | Use pelo menos `Duration(milliseconds: 150)` para feedback visual |
| Animação implícita para sequências complexas | Sem controle de playback, sem stagger, sem reverse sincronizado | Use `AnimationController` + `Interval` para coreografar sequências |
| `Hero` com tags duplicadas na mesma rota | Crash ou comportamento inesperado na transição | Garanta tags únicos por rota (use ID do dado, não string fixa) |
| `AnimationController` com `duration` fixo para physics | Ignora velocidade real do gesto, movimento artificial | Omita `duration` e use `controller.animateWith(simulation)` |
| Múltiplos `RepaintBoundary` desnecessários | Custo de memória para cada layer extra sem ganho real de performance | Use `RepaintBoundary` apenas em animações que causam repaint do pai |

---

**Última atualização**: 11 de abril de 2026
