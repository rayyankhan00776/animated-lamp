# Animated Lamp UI Documentation

## Visual Design

The animated lamp UI features the following components:

### Layout (Top to Bottom)

1. **Lamp Fixture** (Top)
   - Gray rounded rectangle (100x20px)
   - Represents the ceiling mount

2. **Pull String** (Interactive Element)
   - Thin vertical line (2px wide, 40px base height + drag offset)
   - Gray color (#757575 approximately)
   - Circular handle at the bottom (20px diameter)
   - **Interactive**: User can drag down on this string to pull it
   - Extends up to 50px when pulled
   - Trigger threshold: 20px pull distance

3. **Lamp Bulb** (Main Visual Element)
   - Rounded shape (120x160px)
   - OFF state: Dark gray (#616161)
   - ON state: Amber glow (#FFA726)
   - **Glow Effect**: 
     - Amber shadow with 60px blur radius
     - Yellow shadow with 100px blur radius
     - Animated with smooth 300ms transition
   - Filament effect when lit (radial gradient)
   - Metal base at bottom (dark gray, 40px height)

4. **Status Text**
   - "Lamp is ON" (amber color) or "Lamp is OFF" (gray)
   - 24px font size, light weight
   - Letter spacing: 2px
   - Animated opacity: 0.7

5. **Instruction Text**
   - "Pull the string to toggle"
   - 14px font size, italic
   - Gray color
   - Positioned at bottom

### Background
- Dark gradient background
- OFF state: Very dark (#0A0A0A to #1A1A1A)
- ON state: Slightly lighter (#2C2C2C to #1A1A1A)
- Smooth 300ms transition between states

### Animations
1. **Glow Animation** (300ms duration)
   - Ease-in-out curve
   - Animates opacity and spread of lamp glow
   - Animates lamp color from gray to amber

2. **String Pull Animation** (200ms duration)
   - Real-time feedback during drag
   - Resets to original position after release

### Interaction Flow
1. User drags down on the string handle
2. String visually extends (up to 50px)
3. If pulled more than 20px and released:
   - Lamp toggles state (ON ↔ OFF)
   - Glow animation plays
   - Background transitions
   - Status text updates
4. String returns to original position

## Color Palette

**Lamp OFF:**
- Background: #0A0A0A → #1A1A1A (gradient)
- Lamp bulb: #616161
- Fixture/base: #424242
- String: #757575
- Handle: #BDBDBD
- Status text: #757575

**Lamp ON:**
- Background: #2C2C2C → #1A1A1A (gradient)
- Lamp bulb: #FFA726
- Glow: Amber (#FFA726 60% opacity) + Yellow (40% opacity)
- Status text: #FFE082

## Code Structure

- `AnimatedLampApp`: Root widget (MaterialApp)
- `LampScreen`: StatefulWidget for the main screen
- `_LampScreenState`: State management
  - `_isLampOn`: Boolean for lamp state
  - `_glowController`: AnimationController for glow effect
  - `_stringController`: AnimationController for string reset
  - `_glowAnimation`: Animation for smooth glow transition
  - `_stringPullOffset`: Current pull distance
  - `_toggleLamp()`: Toggles lamp state
  - `_onStringDragUpdate()`: Handles string drag motion
  - `_onStringDragEnd()`: Handles string release
