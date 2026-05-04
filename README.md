# Actual Wi-Fi Bars

A tiny native macOS menu bar app that checks whether the internet is actually usable, instead of trusting the system Wi-Fi icon.

It sends a low-bandwidth HTTPS `HEAD` request to Google's `generate_204` endpoint every 5 seconds, measures response latency, and scores the last 12 checks. The menu bar shows a compact connection indicator:

- `▰▰▰▰` excellent
- `▰▰▰▱` good
- `▰▰▱▱` weak
- `▰▱▱▱` unstable
- `x` offline or blocked

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
