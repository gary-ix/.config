# TCL TV Volume Control From Mac

This folder contains a Mac-side helper script for controlling a TCL Google TV speaker volume from macOS.

The script is:

```bash
./tv-volume
```

It is designed to be called by BetterDisplay, a keyboard shortcut tool, or Terminal.

## What This Does

The volume path is:

```text
Mac / BetterDisplay
  -> .home-assistant/tv-volume
  -> Home Assistant REST API
  -> Home Assistant Android TV Remote integration
  -> TCL Google TV speaker volume
```

This does not use HDMI DDC volume. The BetterDisplay slider can appear even when the TV does not expose real speaker volume control over DDC. This script sends real Android/Google TV remote commands instead.

## External Requirements

You need these before this script can work:

1. A running Home Assistant instance on the same network as the Mac and TV.
2. The TCL TV added to Home Assistant with the **Android TV Remote** integration.
3. A Home Assistant long-lived access token.
4. The TCL `remote.*` entity ID from Home Assistant.
5. `curl` and `python3` on the Mac. macOS normally has both available, but Command Line Tools may be needed for `python3` on a fresh machine.

Home Assistant docs:

```text
https://www.home-assistant.io/installation/
https://www.home-assistant.io/integrations/androidtv_remote/
https://developers.home-assistant.io/docs/api/rest/
```

BetterDisplay integration docs:

```text
https://github.com/waydabber/BetterDisplay/wiki/Integration-features,-CLI
```

## Home Assistant Setup From Scratch

Install and run Home Assistant first. The simplest beginner-friendly options are:

1. Home Assistant Green hardware appliance.
2. Home Assistant OS on a spare Raspberry Pi or mini PC.
3. Home Assistant Container on an always-on machine.

Once Home Assistant is running, open it in a browser. It is usually one of these:

```text
http://homeassistant.local:8123
http://YOUR_HOME_ASSISTANT_IP:8123
```

Create your Home Assistant account when prompted.

## Add The TCL TV To Home Assistant

In Home Assistant:

1. Go to `Settings > Devices & services`.
2. Click `Add Integration`.
3. Search for `Android TV Remote`.
4. Select the TCL TV if it is auto-discovered, or enter the TV IP address manually.
5. When the TV shows a pairing code, enter it in Home Assistant.
6. Finish setup.

If the TV becomes unavailable after it is turned off, enable the TCL wake/network setting on the TV:

```text
Settings > System > Power and energy > Screenless service
```

The Google Home app working is a good sign. Home Assistant's Android TV Remote integration uses the same general local remote-control path.

## Create A Home Assistant Token

The script needs a token so it can call Home Assistant.

In Home Assistant:

1. Click your user/profile icon.
2. Open `Security`.
3. Find `Long-lived access tokens`.
4. Click `Create token`.
5. Name it something like `mac-mini-tv-volume`.
6. Copy the token immediately.

Treat this token like a password. Anyone with it can call your Home Assistant API as your user.

## Configure This Script

From this folder:

```bash
cp tv-volume.env.example tv-volume.env
```

Edit `tv-volume.env`:

```bash
nano tv-volume.env
```

Fill in:

```bash
HA_URL="http://YOUR_HOME_ASSISTANT_IP:8123"
HA_TOKEN="YOUR_LONG_LIVED_ACCESS_TOKEN"
TV_REMOTE_ENTITY="remote.YOUR_TCL_REMOTE_ENTITY"
```

Use a fixed Home Assistant IP address if possible. `homeassistant.local` can work, but a fixed IP is usually more reliable.

`tv-volume.env` is intentionally ignored by git because it contains `HA_TOKEN`.

## Find The TCL Entity

After `HA_URL` and `HA_TOKEN` are filled in, run:

```bash
./tv-volume test
```

Expected output:

```json
{"message":"API running."}
```

Then list possible TV entities:

```bash
./tv-volume entities
```

Look for a `remote.*` entity that matches the TCL TV. Example:

```text
remote.living_room_tv    Living Room TV
media_player.living_room_tv    Living Room TV
```

Use the `remote.*` entity in `tv-volume.env`:

```bash
TV_REMOTE_ENTITY="remote.living_room_tv"
```

Do not use the `media_player.*` entity for this script unless you intentionally rewrite it. The script calls `remote.send_command`.

## Test Volume Control

Run:

```bash
./tv-volume up
./tv-volume down
./tv-volume mute
```

If the TV volume changes, the Mac-to-TV control path works.

## BetterDisplay Setup

Once Terminal tests work, point BetterDisplay at the script.

BetterDisplay command examples:

```bash
/Users/garrett/.config/.home-assistant/tv-volume up
/Users/garrett/.config/.home-assistant/tv-volume down
/Users/garrett/.config/.home-assistant/tv-volume mute
```

In BetterDisplay, look for integration/custom control settings around:

```text
Settings > Application > Integration
Display settings > Control integration
Display settings > Custom controls
```

Enable integration features if they are disabled.

Use shell/script custom controls if BetterDisplay asks for an integration type. If it asks for a shell, use:

```bash
/bin/zsh
```

The exact BetterDisplay UI can change by version, but the goal is simple: make BetterDisplay run one of the three commands above for volume up, volume down, and mute.

## Environment Variable Alternative

You do not have to use `tv-volume.env`. The script also accepts environment variables.

One-off example:

```bash
HA_URL="http://192.168.1.50:8123" \
HA_TOKEN="YOUR_TOKEN" \
TV_REMOTE_ENTITY="remote.living_room_tv" \
./tv-volume up
```

Custom config file example:

```bash
TV_VOLUME_CONFIG="/path/to/other.env" ./tv-volume up
```

For BetterDisplay, the normal `tv-volume.env` file is simpler and safer because BetterDisplay only needs to know the script path.

## Git Notes

Files intended to be committed:

```text
.home-assistant/README.md
.home-assistant/tv-volume
.home-assistant/tv-volume.env.example
```

File intentionally not committed:

```text
.home-assistant/tv-volume.env
```

That file contains the real Home Assistant token.

## Troubleshooting

If `./tv-volume test` fails with `401`, the token is wrong or incomplete.

If `./tv-volume test` cannot connect, `HA_URL` is wrong or Home Assistant is not reachable from this Mac.

If `./tv-volume entities` works but volume does nothing, confirm `TV_REMOTE_ENTITY` is the `remote.*` entity from the Android TV Remote integration.

If the TV stops responding after being off, re-check TCL `Screenless service` and confirm Google Home can still control the TV.

If BetterDisplay does nothing but Terminal works, the issue is BetterDisplay command configuration. Use the absolute script path:

```bash
/Users/garrett/.config/.home-assistant/tv-volume up
```
