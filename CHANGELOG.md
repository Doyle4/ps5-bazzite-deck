# Changelog

All notable changes to the images. Exact upstream versions are in each release's `VERSIONS.md`.

## [Unreleased]
- **Logitech racing wheels:** force feedback drivers enabled (G29 and others; rmux's meower 44f4539)

## [v1.5.0] – 2026-10-28
- **USB-C DisplayPort output** (ps5-linux-patches #57 by tertiumndatur, ported to 7.3): displays and the PSVR2 on the console's front USB-C port, no adapter. The HDMI EDID is now bound to the one HDMI connector, and all HDMI-bridge-specific paths (HDR, mute, link lock, 1440p fixup, the standard mode set) stay off the USB-C link. PSVR2 also needs userspace that isn't in the image yet (a patched Mesa for reprojection, PSVR2Toolkit)
- **Colours at 1080p:** the AVI InfoFrame now says full-range RGB (what the GPU sends); TVs read the old "default" as limited range for TV timings like 1080p and 4K60, which crushed blacks and oversaturated colours at those resolutions only (`hdmi.rgb_range=0` for the old behaviour)
- **Wi-Fi power saving stays off:** Steam's developer toggle switched it back on; a timer turns it off again within two minutes, and the NetworkManager hook now uses the same code (it ignored the setting and missed the IW620's `mlan` interface name) (`WIFI_POWERSAVE=1` in `/etc/ps5-bazzite-deck/perf.conf` leaves it alone)
- **First-start message:** while Steam sets itself up behind the blank screen with the blinking cursor, the console now says so and asks not to power off (idea: ObsessiveRug, kishy)
- **"Generic display, 1080p only" after leaving the desktop:** a short or invalid EDID announcement from the HDMI chip (around display power changes) no longer replaces the stored EDID; the previous one is kept and the event is logged (NikySantoro)
- **Fewer hangs on the blinking cursor when switching between Game Mode and the desktop** (the HDMI side; the GPU side is the GFX1013 fix below): the console re-arm no longer blanks the screen (under the console lock, for seconds) while a session switch is still settling, and the same TV re-announcing itself no longer fires a hotplug that made the starting session reprobe and modeset in a loop (`hdmi.rearm_quiet_ms`)
- **Verde consoles:** IT content and content type "game" in the AVI InfoFrame, as FLAVA3 already sends, so TVs choose their game/low-latency mode (the full-RGB-range fix isn't needed there: Verde already declares full range, which also confirms the FLAVA3 fix)
- **Warm reboot, IW620 consoles:** Bluetooth now survives a warm reboot as well (two of two in testing on v1.4.1, Wi-Fi too). Most likely because the Linux-only Bluetooth address, which sent a vendor command to the combo chip at every boot, is off there since v1.4.1; the warm-reboot note no longer says Bluetooth stays off
- Safety net for the EDID binding: if amdgpu can't tell which connector is the HDMI bridge (PR #57 was tested on fat consoles only), every DisplayPort connector gets the bridge's EDID as before, instead of none ("generic display")
- GFX1013 fixes from the same PR (GFXOFF around compute idle, MMIO PASID TLB flushes instead of the KIQ): the likely fix for GPU page faults + `ring gfx_0.0.0 timeout` when a session closes (ObsessiveRug's log: gamescope-xwm page faults, then a ring reset, then minutes on the blinking cursor), Salina xHCI 1 ms poll (needed for Sense controllers), threaded NAPI on the Ethernet, Bluetooth HIDP frames sent non-blocking, ICC teardown hardening
- **CPU boost and a fan target by default** (`ps5-perf`; requested by moonman7299, values after NotHavocc's ps5-hwcon-plugin): the CPU's boost clocks are allowed (up to 3.5 GHz under load, the governor still idles down; nothing is locked at max), and the fan aims for 85 °C (the console's own target is saved the first time and shown by `ps5-perf status`). `ps5-perf off` restores both, `/etc/ps5-bazzite-deck/perf.conf` changes the values

## [v1.4.1] – 2026-10-27
- **IW620 (Marvell) consoles: the Linux-only Bluetooth address is off by default** (`ps5-bt-address on` enables it). It sends a vendor command to the Wi-Fi/Bluetooth combo chip at every boot and is the suspect for v1.4.0's "Wi-Fi sees networks but won't connect" on those consoles (three reports; MediaTek consoles, which use the kernel's own path, were fine). Back on by default once the cause is confirmed
- **USB never sleeps by default** (`usbcore.autosuspend=-1` in `cmdline.txt`, added by the image build and the updater): the USB drive, controllers and dongles no longer get suspended; it was the most-recommended fix for disconnects and freezes
- **Wi-Fi power saving off** whenever a Wi-Fi interface comes up (NetworkManager dispatcher): Steam's developer setting can switch it on per connection, and with it on the IW620 throttles to ~100 Mbit/s instead of ~700 (thelonlybud)
- **Wi-Fi repaired automatically after a warm reboot** (IW620 consoles): the chip's firmware keeps running across a warm reboot and the Wi-Fi driver failed to start ("WLAN FW already running" → "Firmware Init Failed"). `ps5-wifi-repair` runs after warm reboots only, and only when that happened: unload `moal`, reset the Wi-Fi PCI function, load `moal` (fresh firmware). Bluetooth on the same chip drops off USB in a warm reboot and can't be brought back that way (port re-enumeration times out); it needs a cold start, and `ps5-warm-reboot on` says so on IW620 consoles
- Warm reboot: the final step is now systemd's own kexec action (`SuccessAction=kexec-force`) instead of `systemctl --force kexec`, which failed at that point ("Transport endpoint is not connected") and only worked through the fallback; documented as experimental (garbled picture after it on some consoles, IW620 Wi-Fi/Bluetooth sometimes off until a cold start)

## [v1.4.0] – 2026-10-26
> Pulled after release: on IW620 consoles Wi-Fi saw networks but wouldn't connect (fixed in v1.4.1).
- **One DualSense for the PS5 and Linux** (PR #9 by Dasloh): `ps5-bt-addr.service` gives the IW620 Bluetooth chip a Linux-only address at boot (`80:..` becomes `82:..`), so a DualSense keeps its PS5 pairing on one profile and the Linux pairing on another. Original PS5 (IW620) only. Existing Linux pairings must be paired once again after the update. See `docs/dualsense-profiles.md`
- **Controllers reconnect by themselves**: `ps5-bt-connectable.service` makes the Bluetooth adapter accept incoming connections (it started as non-connectable); it runs every time the adapter appears and after every bluetoothd start
- The Linux-only address also reaches the kernel and bluetoothd (the adapter is re-initialised with bluetoothd stopped), and is set again whenever the adapter re-appears, so pairings are always stored under the same address
- **DualSense pairing that sticks** (lessons from the ps5-cachyos-setup project): BlueZ `JustWorksRepairing = always` (the pad re-pairs ~1.5 s after pairing; the default rejects that and deletes the bond) and `PairableTimeout = 0` (with pairable off at pair time the bond is thrown away); `hidp` is loaded at boot (the first connection after a boot could drop); `ps5-bt-revive.service` reloads `btusb` if the Bluetooth adapter hangs after a warm reboot (missing, or unpowered with command timeouts; a user who switched Bluetooth off is left alone)
- **Full-rate DP link**: the link from the GPU to the HDMI chip runs at full rate for every resolution; no black screens at any resolution in rc1 testing; if training at full rate ever fails, the fixed rate is released for the session and amdgpu chooses by itself again
- **VRR: not yet.** rc1/rc2 drove VRR from the GPU alone: the HDMI chip locks the frame timing. hsgodd then found the chip's own VRR mode in the stock system (Sony's VSync block with VRR values, written after link training, plus 6224=40,0f); with it the picture comes up, but TVs drop the signal ~3.5 s after the chip enters VRR mode, even at a fixed refresh rate, with every combination of ignore-MSA, VTEM metadata guess and FreeSync InfoFrame (vrr-test8). Most likely the VTEM packet's contents are still missing. Parked in `patches/parked/` (test 8 and hsgodd's test 7)
- No new boot options: the HDMI debug log (rc1's `hdmi.log_notify=1`) is a dynamic-debug log now (`dyndbg="file drivers/ps5/hdmi.c +p"`), the full-rate link and VRR have no switches
- In-place update: `FILES` lines can have a third column, the file mode; the update enables the Bluetooth services
- **Sleep (suspend-to-idle)** (ps5-linux-patches PR #4 by Dasloh, applied on top of meower): a short power-button press (or Steam's Sleep) sleeps the console, a short press wakes it; games, network and Bluetooth continue. Kernel config gains `CONFIG_SUSPEND=y` (+ PM_SLEEP etc., `AMD_PMC` off)
- **Warm reboot into Linux, optional** (`ps5-warm-reboot on`; off by default): every reboot (Steam, the desktop, `sudo reboot`) then goes through `reboot.target` → `ps5-kexec-prepare.service` (loads the kernel from the boot partition via `kexec_file_load`, no kexec-tools needed) → `ps5-reboot.service` (kexec when loaded, a normal reboot otherwise). Off by default because the IW620's Wi-Fi/Bluetooth sometimes didn't survive a warm reboot in testing
- No chip resets around warm reboots: rc7 reset the Bluetooth adapter's USB host controller (the Salina xHCI, which doesn't survive a reset/D3 and can carry the system drive) and froze on boot; the Wi-Fi function reset can take the combo chip's Bluetooth with it
- **HDMI CEC** (ps5-linux-patches #53 by Slip, ported to 7.3): the TV remote's keys arrive as an input device, and at boot the PS5 turns the TV on and switches it to itself (one-touch play; `ps5-cec.one_touch_play=0` turns that off)
- **Fix: 4K60 and 120 Hz modes gone on some TVs since v1.3.0** (issue #11): the TV presented its HDMI 1.4 EDID (340 MHz, no 120 Hz, 4K60 only as 4:2:0) after v1.3.0 began starting at 1080p60 without any SCDC traffic. HDMI 2.x sources write SCDC Source Version = 1 after hotplug; the HDMI chip now does that at every picture setup for TVs that talk SCDC (HDMI Forum block, or 4K / 4:2:0-only modes, which an HDMI 2.x TV in its 1.4 fallback still lists)
- **Bluetooth adapter no longer vanishes** (thanks to Dasloh's s2idle findings): the PS5's Bluetooth chips drop off USB once their port is suspended (U3) and only return after a full power-off, and the Salina xHCI's setup doesn't survive D3. A udev rule keeps both out of runtime suspend (`99-ps5-usb-power.rules`)
- **Same IP after a reflash**: NetworkManager identifies to DHCP by the hardware address (`ipv4.dhcp-client-id=mac`) instead of a client id derived from the machine id, so a fresh image no longer looks like a new device to the router
- **Sleep without a flickering TV**: when the output goes down (sleep, display off) the HDMI chip is muted and HDR is left (SDR InfoFrame), instead of HDR flickering into a dying signal (rc4 report)
- **One DualSense for the PS5 and Linux also on MediaTek consoles**: the kernel sets the MediaTek chip's address itself (`btmgmt public-addr`, powered off), no vendor command needed; the service picks the method by chip
- **GPU load and temperature in the Steam performance overlay** (and MangoHud): `gpu_busy_percent` from the GFX busy time meower already measures for its GPU frequency driver, and a GPU temperature sensor that reports the chip's one temperature (CPU and GPU are one die; the same reading as the CPU's Tctl). The power-management firmware that normally provides both belongs to Sony's firmware

## [v1.3.1] – 2026-10-25
- **Fix: 1440p picture a few lines too high** with displays whose 1440p timing uses positive vsync (e.g. LG TVs at 1440p120): the HDMI chip expects the standard polarity of both syncs (+hsync, -vsync) and moves the picture by the pulse width otherwise. 1440p timings now get the standard vertical polarity too (horizontal since v1.2.0)
- Same drivers (modules) as v1.3.0; the change is built into the kernel
- Updating: `tools/update-latest.sh`, one command that always installs the latest release (`bash <(curl -fsSL …/tools/update-latest.sh)`); generic `docs/updating.md`
- README: Ko-fi link, simpler boot-options table, clearer M.2 steps, rmux's loader named

## [v1.3.0] – 2026-10-25
- Based on rmux's current `meower` (baee34d): includes the IW620 Bluetooth fixes (our quirks-table and L2CAP fixes, now upstream, plus Maitreya25's interface-recipient control requests: controller initialization and power-on). Our Bluetooth patch is down to the MediaTek part
- **HDR** (ps5-linux-patches #49, ported to 7.3): HDR10 at 1080p60 and 4K60, sent as 12-bit YCbCr 4:2:2, on consoles whose HDMI chip supports it. Unlike upstream it doesn't depend on the requested colour depth. RGB output stays at 8 bits on every console
- **Standard display modes**: 1080p60, 1080p120, 1440p60, 4K60 and 1440p120 (where the HDMI chip supports it) in their standard timings, offered whenever the display's limits allow them, even if its EDID doesn't list them. **New displays start at 1080p60**; a higher mode picked in Game Mode or the desktop is remembered, no `cmdline.txt` change needed
- **The desktop only offers what the PS5 can output**: "max bpc" is 8 only (no 10-bit choice), and without the "scaling mode" property compositors don't add generated resolutions
- ps5-linux-patches #50 (clear SCDC scrambling when leaving 4K60, replaces our own fix) and #54 (back off HDMI hotplug retries while link training fails), ported to 7.3
- `hdmi.log_notify=1` (off by default): logs every HDMI chip notification and picture setup, for black-screen reports

## [v1.2.0] – 2026-10-23
- **Fix: rainbow / "disco" colours** (posterized contours in gradients, with TVs that offer deep colour): the output is capped at 8 bits per colour in the DRM core on the PS5. The graphics driver defaulted "max bpc" to 16 and compositors may ask for 10; the HDMI bridges show deeper colour as contours. Also stops the TV re-announcing itself every few seconds on such setups
- **Fix: "timing issue" / no picture after switching displays**: the wake-up re-arm (#46) now only runs when the same display re-announces itself (EDID checksum); a different display is set up by the hotplug path and the desktop with its own mode
- **Fix: link training errors at boot**: the chip's "picture up" notification now cancels a pending re-arm, so it no longer fires during the first picture setup
- **Fix: 1440p picture shifted 32 px to the left** with displays whose 1440p timing uses negative hsync (e.g. Elgato 4K X): the bridge places the picture relative to the rising edge of hsync, so 1440p timings now get the standard sync shape and positive polarity
- Same drivers (modules) as v1.1.1; the kernel changes are all built in

## [v1.1.1] – 2026-10-23
- **40-CU unlock opt-in again** (`amdgpu.ps5_cu_unlock=3` no longer in the image's `cmdline.txt`): on some consoles the 4 extra compute units cause artifacts (green dots), a purple tint or crashes (silicon lottery). The in-place update switches it off once for installs coming from v1.1.0; after that, a setting you add yourself is kept across updates. README: section "40 GPU compute units (optional)" with on/off commands
- Same kernel and drivers as v1.1.0

## [v1.1.0] – 2026-10-23
- Based on rmux's latest PS5 patches (`meower` @ 34bcc15): HDMI audio (#42) and HDMI hotplug (#43) now come from upstream; our own ports of both are dropped
- Kernel patches consolidated by purpose into four files: `ps5-bluetooth`, `ps5-hdmi-rearm-pr46` (kept separate until it is merged upstream), `ps5-hdmi-output-fixes`, `ps5-hdmi-modes` (plus the Wi-Fi driver's `ps5-iw620-kernel73-compat`)
- **1440p120 always available** when the TV/monitor offers it; the `hdmi.allow_1440p120` option is removed
- **1440p60 offered** when a TV/monitor lists 1440p only at other refresh rates, using the standard VESA 1440p60 timing (241.5 MHz)
- **Fix: squeezed, discoloured picture on some 4K TVs** (whole picture in the left half): modes the TV only accepts as YCbCr 4:2:0 are skipped; the next mode (usually 1080p) is used. Turning on the TV's enhanced HDMI mode for that port gives 4K60
- **All 40 GPU compute units enabled by default** (`amdgpu.ps5_cu_unlock=3` in `cmdline.txt`, also added by the in-place update unless a `ps5_cu_unlock` setting is already there); set it to `=0` to go back to 36
- Hotplug detection runs on the kernel's general work queue (removes a "hogged CPU" warning); the 1440p timing adjustment is logged only when it changes
- Build: the in-place update bundle is made before the 7-Zip volumes; `SKIP_7Z=1` for test builds
- In-place update: finds the USB drive's boot partition by itself (`/efi`, `/boot/efi` on M.2 installs, or mounts it by its label)
- README: troubleshooting steps (PS5 settings, loader, `cmdline.txt` options), USB port speeds per model, simpler M.2 installation, loader links to rmuxwashere/ps5-linux-loader

## [v1.0.7] – 2026-10-22
- **Fix: black screen at boot on some TVs.** The two event sequences that v1.0.6 enabled (from ps5-linux-patches #43) are off again: on some TVs they made the chip re-announce the TV during the first picture setup, link training failed and the screen stayed black.
- **Fix: 1440p picture shifted.** The chip places a 1440p picture as if the signal had the back porches of the standard 1440p60 reduced-blanking timing (80 px / 33 lines); other 1440p timings (the desktop's generated 1440p60, a TV's 1440p120) were shifted right or down. The sync pulses are now moved so the back porches match; resolution, totals and refresh rate are unchanged
- SSH is enabled by default (user `ps5`, password `ps5`; change it with `passwd`)
- Kernel: `CONFIG_MODULE_ALLOW_BTF_MISMATCH=y`, so kernel-only hotfixes keep loading the release's modules

## [v1.0.6] – 2026-10-22
- **HDMI: picture comes back when the display wakes up** (display already on at boot, woken from standby, power-cycled): the HDMI bridge is set up again after the display re-announces itself. ps5-linux-patches #46 (rdmrocha), merged by hand onto #43. Off switch: add `hdmi.rearm=0` to `cmdline.txt`
- **HDMI hotplug**: switching to a different display or re-plugging the cable is detected, and the picture and HDMI audio are set up again. ps5-linux-patches #43, ported to the 7.3 display code
- **Fix: no signal after switching down from 4K** (e.g. to 1080p or 1080p120): 4K60 turns HDMI 2.0 scrambling on in the TV, and it was never turned off again for lower modes. Now it is. 1080p120 works
- **1440p120, experimental and opt-in**: add `hdmi.allow_1440p120=1` to `cmdline.txt`. Uses the 4K60 high-bandwidth setup
- **In-place updates**: an update bundle (`tools/update.sh`) brings earlier installs to the new version without reflashing; kernel, modules and settings, with a backup

## [v1.0.5] – 2026-10-22
- **Fix: services randomly missing after the first reboot** (no Wi-Fi/Ethernet because NetworkManager never started, Switch to Desktop dropping back to Game Mode). Cause: the image builder's `ps5-stage-firmware.service` creates a systemd ordering cycle (`Before=systemd-modules-load` with default dependencies, i.e. also after `basic.target`); systemd breaks it by deleting a different job each boot. Fixed with a drop-in setting `DefaultDependencies=no`. Affected v1.0.3 and v1.0.4 on all models
- MediaTek Wi-Fi (PS5 Slim) confirmed working by a tester; MediaTek Bluetooth still unconfirmed

## [v1.0.4] – 2026-10-21
- Rebuilt on current Bazzite Deck stable and rmux's latest 7.3 PS5 patches (`meower` HEAD): fan autoservo fix, boot fan target set by the kernel
- HDMI audio stability fix (upstream ps5-linux-patches #42, ported to 7.3)
- Wi-Fi (NXP IW620): driver rebuilt with the upstream HE capability + TX fixes; built with objtool metadata (removes the kernel warning at boot)
- Wi-Fi: NetworkManager keeps the permanent MAC during scans (fixes GUI Wi-Fi joins and the first-boot "connect to the internet" failure)
- **MediaTek MT7921 (PS5 Slim / newer) support, untested:** Wi-Fi driver enabled (`CONFIG_MT7921E=m`); Bluetooth: WizGery's btusb bulk-OUT fix (ported to 7.3) and L2CAP defer-security patch, plus udev/modprobe rules. One image for all models; drivers bind by hardware ID
- Boot: dropped the ignored `video=DP-1:1920x1080@60` from `cmdline.txt` (was logging "User-defined mode not supported" on every boot)

## [v1.0.3] – 2026-10-20
- **Bluetooth works**: the 7.3 PS5 patch registered the IW620 Bluetooth device (`1286:2059`) in the wrong `btusb` table, so its quirks never applied (two `hci` devices, `Opcode 0x2031 failed`). The fix (now part of `patches/ps5-bluetooth.patch`) moves the entry to `quirks_table` and the interface-0 check after the quirks lookup. Only `btusb.ko` changed; a hotfix module for v1.0.2 is attached to the release.

## [v1.0.2] – 2026-10-20
First working public release.
- Linux 7.3 with rmuxnet 7.3 PS5 patches (`meower` @ 36f173f): VCN video decode/encode, Bluetooth re-enabled
- **Game Mode works**: `bpf` added to `CONFIG_LSM`, `CONFIG_DEBUG_INFO_BTF=y` (fixes `cardwired`), `lsm=…,bpf` also in `cmdline.txt`
- Wi-Fi: PS5 IW620 driver with kernel 7.2/RTNL patches + new kernel 7.3 compat patch, `ps_mode=0` (firmware is staged at boot from the loader by the builder's ps5-stage-firmware service, not shipped in the image)
- Builder: ps5-linux-image @ 52db0a4 + fixes (VCN firmware mount, Wi-Fi patch order)

## [v1.0.0] – 2026-10-20 (withdrawn)
Same image plus a first-boot service running external Wi-Fi/Bluetooth fix scripts; the Wi-Fi script reloads the driver and can hang the first boot. Do not use.

## [v0.1.0] – 2026-10-19 (not published)
- Kernel 7.2.3 (ps5-linux-patches `main` @ 753c793) build; first image with working Game Mode (cmdline `lsm=` fix only)
