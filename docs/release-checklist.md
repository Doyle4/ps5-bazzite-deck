# Release checklist

We have few testers and one console each, so releases go slower than development:
what goes out has to have been used, not only booted.

## Versions
- **1.X (e.g. 1.6) is a stable release:** new features that went through pre-releases and this
  checklist, with a **full image** and an update bundle. Only these become "latest", so only these
  reach people through the normal update command.
- **1.X.Y (e.g. 1.6.1) is a pre-release:** new features and fixes for testing, as an **update bundle
  only** (`PRERELEASE=1 BUNDLE_ONLY=1 bash tools/release.sh v1.X.Y "title"`). Fresh installs flash
  the latest stable image and update. Testing steps are in each pre-release's notes.

## Rules
- **At most one new feature per release**, plus fixes. A feature is anything a user can notice
  that wasn't there before (a new driver, a new default, a new service). Fixes for open issues
  don't count.
- **Feature freeze on 1.5:** v1.5.x releases are fixes only, until the open issues below are fixed
  or understood and a 1.5.x has gone stable through the checklist. **VRR is the next feature
  (1.6)**, after the freeze; anything else new waits behind it.
- **VRR and other experiments stay in separate test builds** (`vrr-test…`, quick kernels), never
  in a release.
- **New code reaches stable only through pre-releases:** a 1.X comes out once its 1.(X-1).Y
  pre-releases have passed the checklist below and been in testers' hands for about a week
  without a new problem.
- **Releases that don't pass stay pre-releases** (or are removed); fixes go into the next one.
- **The build's test install runs with warm reboot off** (`ps5-warm-reboot off` on the test
  console), so the new kernel always gets a cold start.

## Waiting for after the freeze
- VRR (1.6), in vrr-test builds until then
- Logitech racing wheels: force feedback drivers (rmux's meower 44f4539)

## Checklist before a release goes stable
Tick each one, on the release itself (not a test build), and note who tested what in the
release's Discord thread.

**Installs** (a fresh flash, first boot to the end of the setup, no shortcuts)
- [ ] original PS5 (FLAVA3) with the IW620 (Marvell) chip
- [ ] PS5 Slim (or any MediaTek console)
- [ ] one TV and one PC monitor
- [ ] the first setup is asked only once, ends in the Steam Machine layout (not the Steam Deck
      one), the console doesn't switch off along the way, Bluetooth is on afterwards
- [ ] update from the previous stable release with the update command, then a cold start

**Use** (on at least one of the installs)
- [ ] an hour of actual gaming: two games, one demanding
- [ ] five switches Game Mode → desktop → Game Mode: no hang, no "generic display",
      Wi-Fi speed the same afterwards
- [ ] sleep and wake twice (power button)
- [ ] a DualSense pairs, reconnects with the PS button after a cold start and after sleep
- [ ] Wi-Fi: joins, and a Steam download runs at the usual speed (and after a session switch)
- [ ] HDR on and off on an HDR TV; 1080p, 1440p and 4K60 where the TV has them
- [ ] TV remote (CEC) works, the TV switches on at boot

**Timings** (same console, compared with the previous release; see docs/first-boot-tests.md, test 3)
- [ ] boot to Game Mode, and one session switch each way: not noticeably slower

## Open issues (the 1.5 freeze ends when these are fixed or understood)
- First boot: sometimes the Steam Deck (handheld) variant of Game Mode instead of the Steam
  Machine one, the setup asked twice, Bluetooth off afterwards (ObsessiveRug). Tests: docs/first-boot-tests.md
- First boot: the console sometimes switches off after the Wi-Fi step (ObsessiveRug)
- Boot and session switches possibly getting slower (unmeasured so far)
- Steam download speed drops after a session switch, while the Wi-Fi link stays at full speed
  (Yoshi; power profile suspected)
- Garbled picture in Game Mode on an older LG TV with "HDMI Ultra Deep Colour" on (kishy; HDR
  4:2:2 at 4K suspected)
- Hangs on session switches: GPU page faults from gamescope-xwm, then a stuck graphics queue
  (ObsessiveRug; still there on v1.5.0, the GFX1013 fixes didn't help; suspect: the GPU's compute
  queue on GFX1013, test with RADV_DEBUG=nocompute)
- greenboot-healthcheck, bootloader-update and ublue-os-media-automount fail on every boot (they
  expect Bazzite's own bootloader); harmless as far as we can tell (greenboot can't reboot without
  grub), but noise to remove
- No Wi-Fi on a PS5 Slim 12.20 (loseheaven; chip and log still missing)
