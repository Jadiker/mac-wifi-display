# Actual Wi-Fi Bars

A tiny native macOS menu bar app that checks whether the internet is actually usable, instead of trusting the system Wi-Fi icon.

Actual Wi-Fi Bars runs as an accessory app in the menu bar. Every 5 seconds it sends a low-bandwidth HTTPS `HEAD` request to Google's `generate_204` endpoint, measures response latency, and scores the last 12 checks for the current status. It keeps the last hour of probes for the graph and bandwidth estimate.

The icon stays compact by drawing a Wi-Fi symbol directly in the menu bar:

- Green: excellent recent reliability and latency
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

## Run

```sh
swift run ActualWifiBars
```

The app does not open a Dock icon. Look for the Wi-Fi-shaped status item in the macOS menu bar.

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

## Bandwidth

The app uses HTTPS `HEAD` requests instead of downloading `google.com`, so each probe only exchanges headers and TLS traffic. At the default 5 second interval, this is designed to stay tiny while still detecting the "Wi-Fi looks connected, but nothing actually responds" case quickly.

The displayed data totals are estimates based on HTTP request and response headers retained in the last-hour history. They do not include every byte of lower-level network overhead such as TCP, TLS, IP, or Wi-Fi framing.

## Notes

- The current probe endpoint is `https://www.google.com/generate_204`.
- A failed probe can mean the internet is unavailable, DNS or HTTPS traffic is blocked, the endpoint is unreachable from the current network, or the request timed out.
- The app uses native AppKit and has no package dependencies.
