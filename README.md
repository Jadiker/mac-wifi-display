# Actual Wi-Fi Bars

A tiny native macOS menu bar app that checks whether the internet is actually usable, instead of trusting the system Wi-Fi icon.

Actual Wi-Fi Bars runs as an accessory app in the menu bar. Every 5 seconds it sends a low-bandwidth HTTPS `HEAD` request to Google's `generate_204` endpoint, measures response latency, and scores the last 12 checks for the menu status. The menu bar color reacts to the latest probe and the last three checks, so failures show up quickly. It keeps the last hour of probes for the graph and bandwidth estimate.

The icon stays compact by drawing a Wi-Fi symbol directly in the menu bar:

- Green: excellent latest latency with three clean recent probes
- Blue: good connection
- Orange: weak connection
- Red: unstable, offline, or blocked

## Features

The menu shows:

- Current status
- Median latency
- Reliability over recent checks
- Estimated data sent and received during the retained history
- Time of the last check

It also includes actions for:

- Checking immediately
- Opening a one-hour connectivity graph
- Quitting the app

## Requirements

- macOS 13 or newer
- Swift 5.9 or newer

## Run from Terminal

Clone or download this repository, open Terminal in the project folder, then run:

```sh
swift run ActualWifiBars
```

The app does not open a Dock icon. Look for the Wi-Fi-shaped status item in the macOS menu bar. To stop it, open the menu bar item and choose **Quit Actual Wi-Fi Bars**, or press `Control-C` in the Terminal window if you are still running it with `swift run`.

## Build

```sh
swift build -c release
```

The release binary will be at:

```text
.build/release/ActualWifiBars
```

You can launch that binary directly:

```sh
.build/release/ActualWifiBars
```

This is useful for development, but it is still just a command-line executable. For a normal macOS app you can keep in Applications, use the app bundle script below.

## Build the macOS App

The repository includes a packaging script that builds a release binary, creates a real `.app` bundle, and generates the green full-bars app icon:

```sh
scripts/build_app.sh
```

The finished app will be created at:

```text
.build/release/Actual Wi-Fi Bars.app
```

You can launch that app directly from Terminal:

```sh
open ".build/release/Actual Wi-Fi Bars.app"
```

## Install into Applications

To build the app and copy it into your Applications folder:

```sh
scripts/build_app.sh --install
```

This installs:

```text
/Applications/Actual Wi-Fi Bars.app
```

Then launch it like any other Mac app:

```sh
open -a "Actual Wi-Fi Bars"
```

If macOS reports that it cannot copy into `/Applications`, build the app with `scripts/build_app.sh` and drag `.build/release/Actual Wi-Fi Bars.app` into Applications in Finder.

## Bandwidth

The app uses HTTPS `HEAD` requests instead of downloading `google.com`, so each probe only exchanges headers and TLS traffic. At the default 5 second interval, this is designed to stay tiny while still detecting the "Wi-Fi looks connected, but nothing actually responds" case quickly.

The displayed data totals are estimates based on HTTP request and response headers retained in the last-hour history. They do not include every byte of lower-level network overhead such as TCP, TLS, IP, or Wi-Fi framing.

## Notes

- The current probe endpoint is `https://www.google.com/generate_204`.
- A failed probe can mean the internet is unavailable, DNS or HTTPS traffic is blocked, the endpoint is unreachable from the current network, or the request timed out.
- The app uses native AppKit and has no package dependencies.

## License

Actual Wi-Fi Bars is licensed under the GNU General Public License v3.0 or later. See [LICENSE](LICENSE) for details.
