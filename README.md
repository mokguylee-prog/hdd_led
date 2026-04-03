# Noti HDD

`Noti HDD` is a macOS menu bar app that monitors disk activity and shows it as an LED-style status item. The app also includes an eye exercise overlay with hamster animation, movement controls, size/speed options, and pause triggers based on circular mouse motion or shake detection.

## Features

- Menu bar LED indicator for disk activity
- Selectable notification LED color styles
- Eye exercise overlay with drawn or photo hamster styles
- Adjustable interval, speed, size, and movement mode
- Pause overlay by circular motion or mouse shake

## Project Layout

- `Noti HDD.xcodeproj`
- `Noti HDD`
- `buildrun.sh`
- `launch.sh`
- `backup.sh`

## Build And Run

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
- Debug logs are written to a writable `debug.log` location near the app or current working directory when possible.
- A source backup zip can be created with `./backup.sh`.
