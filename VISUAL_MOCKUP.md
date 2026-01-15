# Animated Lamp - Visual Mockup

## Lamp OFF State
```
┌─────────────────────────────────────────────┐
│                                             │
│         ╔═══════════════════╗               │
│         ║  LAMP FIXTURE     ║               │
│         ╚═══════════════════╝               │
│                  ║                          │
│                  ║  ← Pull String           │
│                  ●  ← Handle (draggable)    │
│                                             │
│                                             │
│              ╔═══════╗                      │
│             ╔═════════╗                     │
│             ║         ║                     │
│             ║ [BULB]  ║  ← Dark gray bulb   │
│             ║         ║                     │
│             ╚═════════╝                     │
│              ╚═══════╝                      │
│                                             │
│                                             │
│           Lamp is OFF                       │
│                                             │
│      Pull the string to toggle              │
│                                             │
└─────────────────────────────────────────────┘
```

## Lamp ON State (with glow effect)
```
┌─────────────────────────────────────────────┐
│                                             │
│         ╔═══════════════════╗               │
│         ║  LAMP FIXTURE     ║               │
│         ╚═══════════════════╝               │
│                  ║                          │
│                  ║  ← Pull String           │
│                  ●  ← Handle (draggable)    │
│                                             │
│           .:*~*:..                          │
│         .         .                         │
│        .  ╔═══════╗  .                      │
│       :  ╔═════════╗  :                     │
│      :   ║ ⚡ ⚡ ⚡ ║   :  ← Glowing amber   │
│      *   ║ [BULB]  ║   *                    │
│      :   ║ ⚡ ⚡ ⚡ ║   :                     │
│       :  ╚═════════╝  :                     │
│        .  ╚═══════╝  .                      │
│         .    |||    .  ← Glow effect        │
│           :*~*:.                            │
│                                             │
│           Lamp is ON                        │
│                                             │
│      Pull the string to toggle              │
│                                             │
└─────────────────────────────────────────────┘
```

## String Pull Interaction
```
Step 1: Initial state
     ║
     ●  ← Handle at rest

Step 2: User drags down
     ║
     ║  ← String extends
     ║
     ●  ← Handle pulled down

Step 3: Release (if pulled > 20px)
     ║
     ●  ← Snaps back & toggles lamp

Result: Lamp changes state (ON ↔ OFF)
```

## Animation Sequence

**When Lamp Turns ON:**
1. User pulls string > 20px and releases
2. String snaps back (200ms)
3. Glow effect fades in (300ms, ease-in-out)
4. Bulb color transitions from gray → amber
5. Background lightens slightly
6. Text updates: "Lamp is OFF" → "Lamp is ON"

**When Lamp Turns OFF:**
1. User pulls string > 20px and releases
2. String snaps back (200ms)
3. Glow effect fades out (300ms, ease-in-out)
4. Bulb color transitions from amber → gray
5. Background darkens
6. Text updates: "Lamp is ON" → "Lamp is OFF"

## Technical Features

✅ **Gesture Detection**: Vertical drag with delta tracking
✅ **State Management**: StatefulWidget with setState
✅ **Smooth Animations**: AnimationController with curves
✅ **Visual Feedback**: Real-time string extension
✅ **Threshold-based Toggle**: Requires 20px+ pull
✅ **Color Interpolation**: Smooth color transitions
✅ **Shadow Effects**: Multiple BoxShadow layers for glow
✅ **Responsive Layout**: Center-aligned with flexible spacing
✅ **Material Design 3**: Modern Flutter theming
