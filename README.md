# Noti HDD

`Noti HDD` is a macOS menu bar app that monitors disk activity and shows it as an LED-style status item. The app also includes an eye exercise overlay with a small animated Naro-style rocket, movement controls, size/speed options, and pause triggers based on circular mouse motion or shake detection.

## Features

- Menu bar LED indicator for disk activity
- Selectable notification LED color styles
- Naro-style rocket preview in the menu and a moving rocket in the exercise overlay
- Adjustable interval, speed, rocket size (10–100%, 50pt by default), and movement mode
- Synchronized speed slider and numeric controls with saved preferences
- Pause overlay by circular motion or mouse shake

## Eye Exercise Movement Speed

The default is **level 3**, taking about **6 seconds** to cross the longer dimension of the screen. Movement duration scales with distance so horizontal, vertical, and diagonal paths have the same speed. The rocket pauses for one second at each target.

Adjust levels 1–10 with the menu slider, numeric input, or stepper. Crossing the longer dimension takes about 18 seconds at level 1 and 1.8 seconds at level 10. Settings are saved and changes take effect on the next movement. Preferences from the previous timing scale start with the new default.

[CHOP's eye tracking instructions](https://chopib.staywellsolutionsonline.com/Library/Encyclopedia/22%2C36023) suggest starting with three-second movements to each side, and [Mersey Care NHS](https://www.merseycare.nhs.uk/patient-leaflets/balance-and-gait) describes slowly tracking a target. These informed the app's six-second starting value. Actual angular eye velocity depends on display size and viewing distance; this default is not a clinically validated optimal speed.

## Project Layout

- `Noti HDD.xcodeproj`
- `Noti HDD`
- `buildrun.sh`
- `launch.sh`
- `backup.sh`

## Build And Run

Requires macOS 13 or later and Xcode.

Build in `Release`, copy the app to the project root, and launch it:

```bash
./buildrun.sh
```

Launch the copied app again later:

```bash
./launch.sh
```

The copied app bundle will be created at:

```text
./Noti HDD.app
```

## Notes

- The main app target and scheme name are `Noti HDD`.
- Debug logs currently go to the console; file logging is disabled.
- A source backup zip can be created with `./backup.sh`.
