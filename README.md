# JoyConTouch for LiveContainer / CounterFlame

Prototype tweak for LiveContainer. It reads Nintendo Joy-Con input through GameController and uses PTFakeTouch to synthesize touches **inside the injected app process**.

Target: iPhone + iOS 27 + LiveContainer 3.8.10 + CounterFlame.

## Build without a Mac

1. Create a new empty GitHub repository.
2. Upload this repository's files.
3. Open **Actions → Build JoyConTouch → Run workflow**.
4. Download the `JoyConTouch-dylib` artifact.
5. In LiveContainer 3.8.10, open **Tweaks**, import the dylib, and assign it to CounterFlame.
6. Fully close/relaunch CounterFlame.

LiveContainer's TweakLoader supports app-specific `.dylib` tweaks and can sign imported tweaks.

## Current mapping

Coordinates are normalized to the CounterFlame window:

- A: tap 90%, 86%
- B: tap 78%, 86%
- X: tap 82%, 70%
- Y: tap 92%, 70%
- ZR: tap 92%, 56%
- ZL: tap 82%, 56%
- Right stick: continuous camera drag starting at 70%, 50%
- Left stick: placeholder logging for now

The coordinates are deliberately easy to change in `JoyConTouch.m`. They are only a starting point because CounterFlame's HUD/layout can vary.

## Important

This is an experimental prototype. Synthetic touch APIs on iOS are private/unsupported and may break on a future iOS version. If CounterFlame crashes immediately after enabling the tweak, disable the tweak in LiveContainer.

PTFakeTouch is an archived open-source user-mode touch simulation project. The workflow pulls it during the build rather than bundling its source here.
