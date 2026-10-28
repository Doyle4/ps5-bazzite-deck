# Hardware matrix: what applies to which chips

The PS5 comes with two HDMI chips and two Wi-Fi/Bluetooth chips, in any combination:

| | |
|---|---|
| **HDMI chip** | **FLAVA3** (Panasonic MN8647xx family; most consoles) or **Verde** (some later models). The kernel log says which: `HDMI IC Type [FLAVA3]` |
| **Wi-Fi/Bluetooth** | **IW620** (NXP/Marvell; most original PS5s, Bluetooth USB ID `1286:2059`) or **MediaTek** (most Slims, USB ID `0e8d:…`) |

A fix for one chip can break the other when it isn't limited to the chip it's for. This list says,
for every change we carry, which hardware it's for and **how the code limits it** ("all" means it
runs everywhere). When a fix is chip-specific, it must check the chip at runtime, and a release
must be tested on both chips of that kind (docs/release-checklist.md). `tools/ps5-report.sh` tells
which combination a console has.

## Kernel patches (build.sh order)
| Patch | For | Limited by |
|---|---|---|
| `ps5-linux-patches-pr4-s2idle` (sleep) | all | — |
| `linux.patch` (rmux's meower base: PS5 support, IW620 driver, L2CAP, btusb quirks) | all; IW620 parts only load on IW620 | drivers bind by device ID |
| `ps5-bluetooth` (bulk-OUT endpoint) | MediaTek | btusb, MediaTek device IDs |
| `ps5-hdmi-upstream`: #49 HDR | FLAVA3 | `isHdmiHdrSupported()` = FLAVA3 |
| ` ` #50 SCDC scrambling clear | FLAVA3 | FLAVA3 setup path |
| ` ` #54 hotplug back-off | both | — |
| `ps5-hdmi-rearm-pr46` (picture back after the display re-announces) | both | picture-up message differs: Verde `0x03`, FLAVA3 `0x04` |
| `ps5-hdmi-output-fixes` | both; the event sequences part FLAVA3 | `hdmi_ic_type` |
| `ps5-hdmi-modes` (standard modes, 1080p60 preferred, no 4:2:0-only) | both | — |
| `ps5-hdmi-debug-log` | both | dynamic debug, off by default |
| `ps5-hdmi-link-lock` (full-rate DP link to the HDMI chip) | both | bridge connector only (not USB-C) |
| `ps5-gpu-overlay` | all | — |
| `ps5-hdmi-cec-upstream53` (TV remote) | both (tested on FLAVA3) | — |
| `ps5-hdmi-sleep-mute` | both | — |
| `ps5-hdmi-scdc-source-version` (issue #11) | FLAVA3 | FLAVA3 setup path, and only if the TV's EDID has SCDC |
| `ps5-usbc-dp-pr57`: USB-C DisplayPort | all with a unique USB-C route in the VBIOS (tested on fat only) | `ps5_usbc`, routing check; HDMI-only paths guarded |
| ` ` GFX1013 fixes, Salina 1 ms poll, threaded NAPI, HIDP | all | — |
| `ps5-hdmi-rgb-full-range` | FLAVA3 (Verde already sends full range) | FLAVA3 setup path |
| `ps5-hdmi-edid-fallback`, `ps5-hdmi-edid-keep` | both | — |
| `ps5-hdmi-verde-game-content` | Verde | Verde setup path |
| `ps5-hdmi-session-switch` | both | — |
| VRR test builds (parked, not in releases) | FLAVA3 | `hdmi.vrr_test=1` and FLAVA3 |

## Image settings and services
| File / service | For | Limited by |
|---|---|---|
| `ps5-bt-addr` (Linux-only Bluetooth address) | MediaTek: always; IW620: **opt-in** (`ps5-bt-address on`) since it broke IW620 Wi-Fi | checks the chip's USB ID |
| `ps5-bt-connectable`, `bluetooth-ps5-connectable.conf`, `99-ps5-bt-services.rules`, `ps5-bt-revive`, `ps5-hidp.conf` | both | — |
| `99-ps5-bt-phantom.rules`, `btusb-ps5.conf` | MediaTek Bluetooth | udev / module match |
| `99-ps5-usb-power.rules` (no runtime suspend) | both Bluetooth chips + the Salina USB controller | device IDs |
| `99-ps5-iw620.conf` (stable MAC during scans), `ps5-stage-firmware` drop-in | IW620 | — (harmless elsewhere) |
| `90-ps5-wifi-powersave`, `ps5-wifi-powersave.timer` (via `ps5-perf wifi`) | all Wi-Fi; matters most on IW620 | `WIFI_POWERSAVE` in `perf.conf` |
| `ps5-perf` (CPU boost, fan target) | all | `perf.conf` |
| `ps5-first-start` | all | first start only |
| Warm reboot (`ps5-kexec`, `ps5-reboot.service`, `reboot.target`, `kexec-shim`) | all, **opt-in** | `/etc/ps5-bazzite-deck/warm-reboot` |
| `ps5-wifi-repair` (Wi-Fi after a warm reboot) | IW620 | runs after warm reboots, acts only on the IW620 failure |
| `usbcore.autosuspend=-1` in `cmdline.txt` | all | — |

## Lessons so far
- **The Linux-only Bluetooth address (v1.4.0)** was meant for both chips, but its IW620 path (a
  vendor command to the combo chip) broke IW620 **Wi-Fi**: a fix for one function of a chip broke
  another function of the same chip. Since v1.4.1 it's opt-in on IW620.
- **HDR (#49) is FLAVA3-only**, but what the TV can take varies: an older LG with "Ultra Deep
  Colour" showed a garbled picture with HDR at 4K (kishy). Display capabilities need the same care
  as chips.
- **The USB-C port (PR #57) was only tested upstream on fat consoles**; the EDID fallback exists
  for consoles where the routing check finds no unique connector.
