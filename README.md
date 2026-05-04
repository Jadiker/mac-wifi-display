# Actual Wi-Fi Bars

A tiny native macOS menu bar app that checks whether the internet is actually usable, instead of trusting the system Wi-Fi icon.

It sends a low-bandwidth HTTPS `HEAD` request to Google's `generate_204` endpoint every 5 seconds, measures response latency, and scores the last 12 checks for the current status. The menu bar uses the standard macOS Wi-Fi symbol and color to stay compact.

The menu includes:

- Current status
- Median latency
- Reliability over recent checks
- Estimated data sent and received over the last hour
- A connectivity graph for the last hour

## Run

```sh
swift run ActualWifiBars
```

## Build

```sh
swift build -c release
```

The release binary will be at:

```text
.build/release/ActualWifiBars
```

## Bandwidth

The app uses HTTPS `HEAD` requests instead of downloading `google.com`, so each probe only exchanges headers and TLS traffic. At the default 5 second interval, this is designed to stay tiny while still detecting the "Wi-Fi looks connected, but nothing actually responds" case quickly.

The displayed data totals are estimates based on HTTP request and response headers. They do not include every byte of lower-level network overhead such as TCP, TLS, IP, or Wi-Fi framing.
# mac-wifi-display
