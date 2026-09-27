# Motion

**Status: approved direction. Spring values are a starting point — tune them by feel on a real device before treating them as settled.**

## Where this comes from

This direction is adapted from a code-driven, spring-physics motion style built for Dribbble-style showcase reels: one shape continuously morphing through UI states (button → loader → checkmark → player → slider → toggle → tabs → chart → command palette → toast), driven entirely by spring math instead of canned easing, with real cursor-driven interaction.

Kombien takes the **physical, restrained motion technique** from that source and leaves behind the **demo-reel choreography** — a fare-lookup app someone's using on the roadside has different needs than a 7-bar, beat-synced showcase video. Specifically, we're **not** taking: camera zooms per state, music-BPM-synced timing, sound design synced to peaks, or "make every element morph into the next" as a goal in itself. A screen transition in Kombien doesn't need to justify its existence by looking impressive — it needs to help someone understand what just happened, fast, standing in the sun, possibly mid-negotiation.

## Principles to keep

1. **Spring-driven, not eased.** Motion is the step-response of a physical spring (mass/stiffness/damping), not a duration + easing curve. It feels alive because it behaves like something with real inertia, not like a designer typed `ease-in-out`.
2. **Shape continuity where it aids understanding.** When a state change is conceptually continuous — a button turning into a loading indicator, a card expanding into a detail view — morph the existing element rather than cutting to a new one. This is a tool for *clarity*, not a rule to apply everywhere; most of Kombien's screens are simple enough that they don't need it (see [Where not to use it](#where-not-to-use-it)).
3. **Content swaps get their own brief cross-fade.** When text or an icon inside a morphing container changes, give it a short independent fade/blur transition (~100–150ms) instead of letting it reflow or overlap while the container is still resizing.
4. **Direct manipulation.** Anything draggable (a range slider, a dismissible card) tracks the finger 1:1 while held, and springs to rest on release — never animates on a fixed timer while being dragged.
5. **Restraint: a tiny overshoot at most.** Springs should feel snappy and settled, not bouncy or cartoonish. No particle bursts, no glow, no gradients on UI chrome — this is already Kombien's rule (see [../strategy/brand-strategy.md](../strategy/brand-strategy.md#what-the-brand-should-avoid)), and it applies just as much to motion as to static visuals.
6. **Drive animation from elapsed time, not accumulated state.** An animation's value at any moment should be computable from "how long has this been running," not from incrementally mutated state — this is what makes motion interruptible and testable instead of fragile. In Flutter, this means driving values from an `AnimationController`'s current value/status, not manual timers plus `setState`.

## Where to use it

- Confirming a fare report was submitted (a button morphing into a checkmark).
- A toggle or switch responding to a tap.
- A value settling into place after a drag (a price-range slider).
- A card or sheet expanding to reveal detail, when that expansion helps someone track *where the detail came from*.

## Where not to use it

- Page-to-page navigation, just because a transition is possible.
- Idle/looping decorative animation — nothing should move on screen without the user having caused it.
- Anything that delays the one thing someone came to do: check a fare, report a fare, fast.

If a motion choice would make the app feel like a showcase reel rather than a tool, don't do it — see the brand's own "avoid" list, which this extends rather than replaces.

## Implementation (Flutter)

Use `package:flutter/physics.dart` — `SpringDescription` + `SpringSimulation`, driving an `AnimationController` via `controller.animateWith(...)`. This is already part of the Flutter SDK, so it introduces no new dependency (consistent with [the project's "no unnecessary dependencies" principle](../../CONTRIBUTING.md)).

```dart
final simulation = SpringSimulation(
  const SpringDescription(mass: 1, stiffness: 180, damping: 20), // "standard" — see ../tokens/motion.json
  controller.value, // starting position
  1.0,              // target
  controller.velocity, // carry over velocity for interrupted/re-triggered springs
);
controller.animateWith(simulation);
```

Carrying over `controller.velocity` when a spring is re-triggered mid-flight (e.g. the user drags again before the last spring settled) is what makes interruptions feel continuous instead of janky.

See [`../tokens/motion.json`](../tokens/motion.json) for the concrete spring presets.
