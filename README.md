# PS5 Bazzite Deck

Turn your PS5 into a Steam console: this is [Bazzite](https://bazzite.gg) in Steam Deck mode, adapted for the
PlayStation 5. It boots straight into **Steam Gaming Mode** (the Steam Deck interface), and a full KDE
desktop is one click away.

It runs from a USB drive, started by **rmux's** [PS5 Linux loader](https://github.com/rmuxwashere/ps5-linux-loader/releases).
Your PS5 itself is not modified: unplug the drive and it's a normal PS5 again.

**Download:** [Releases](../../releases) · **Help & testing:** [Discord](https://discord.gg/qGcuTgBBYU) · **Support the project:** [Ko-fi](https://ko-fi.com/vivalavent)

## Prerequisites

- A PS5 on a firmware **rmux's** [PS5 Linux loader](https://github.com/rmuxwashere/ps5-linux-loader/releases) supports (see its releases). Tested on firmware 13.60.
- A USB drive of **32 GB or more**, ideally an external SSD (much faster than a stick).
- A PC to download and flash the image, and for the first setup a USB keyboard is handy.
- **PS5 settings**, in the normal PS5 menu, before the first start (set them again after a PS5 reset or firmware update):
  - `Settings` → `System` → `Power Saving` → `Features Available in Rest Mode` → `Supply Power to USB Ports`: **Always**.
  - `Settings` → `HDMI` → `Enable HDMI Device Link`: **off**. If it's on, you'll typically get a black screen.

## Install

1. **Download** all `ps5-bazzite-deck-vX.Y.Z.img.7z.00*` files from the latest [release](../../releases)
   into one folder.
2. **Extract** the `.001` file with [7-Zip](https://7-zip.org) (Windows), Keka (macOS) or `7z x` (Linux).
   You get `ps5-bazzite-deck.img`.
3. **Flash** it to the USB drive with [Rufus](https://rufus.ie): select the drive, select the `.img`, click Start.
   This erases the drive.
4. **Plug** the drive into a fast USB port. Every PS5 has fast ports (SuperSpeed, 10 Gbit/s) and one slow port
   (Hi-Speed, the older USB 2.0 speed of 480 Mbit/s). A slow port works, but booting, loading and installing
   games become much slower.
   - **Original PS5:** the two **rear** USB-A ports or the **front USB-C** port. The front USB-A port is the slow one.
   - **PS5 Slim:** the two **rear** USB-A ports. One of the two front USB-C ports is the slow one, so the rear
     ports are the safe choice.

   Use the slow port for a controller or keyboard.
5. **Run the jailbreak and the loader** as described in the loader's instructions. The PS5 goes into rest mode;
   wait until the orange light stops blinking, then press the power button. A **white light** means Linux is booting.
6. **First boot is slow.** The screen can stay black for a few minutes. Let it be.
## First boot

- The default password is **`ps5`** (asked for anything that needs admin rights). SSH is on: `ssh ps5@<your PS5's IP>`.
  **Change the password** with `passwd`, since anyone on your network can try `ps5`.
- **After joining Wi-Fi, Steam updates itself** in the background, often behind a blank screen with a blinking cursor
  that looks frozen, for several minutes. Don't power off then: that's the most common reason for a broken first start.
- The first start is at **1080p60**. Pick your resolution in the display settings (Game Mode: Settings → Display); it's remembered.
- Set **RGB range** to **Full**, in both Game Mode and the desktop.

## Updating

From v1.0.3 or newer you can update **without reflashing**; your games and settings stay. On the PS5
(in a terminal or over SSH, password `ps5`):
```
bash <(curl -fsSL https://raw.githubusercontent.com/VivaLaVent/ps5-bazzite-deck/main/tools/update-latest.sh)
```
Then reboot and run the loader. Details: [docs/updating.md](docs/updating.md). Reflashing always works too
(back up anything you want to keep from the drive first).
## Installing to the PS5's internal M.2

The USB drive stays required: the PS5 loader always starts the kernel from its small FAT32
partition. The M.2 holds the system. Install the **same version** on the M.2 as on the USB.
If a step doesn't work for you, tell us in [Discord](https://discord.gg/qGcuTgBBYU).

All steps run on the PS5, booted from the USB, in a terminal (password `ps5`).

1. **Get the tools** ([ps5-linux-tools](https://github.com/ps5-linux/ps5-linux-tools); Bazzite has everything needed to build them).
   If the M.2 isn't prepared for Linux yet, follow their README (`m2_init`) first.
   ```
   git clone https://github.com/ps5-linux/ps5-linux-tools ~/ps5-linux-tools && make -C ~/ps5-linux-tools
   ```

2. **Install.** `m2_install.sh` looks for the boot partition at `/boot/efi`; Bazzite has it at `/efi`, so mount it there too:
   ```
   sudo mkdir -p /boot/efi && (mountpoint -q /boot/efi || sudo mount LABEL=boot /boot/efi)
   cd ~/ps5-linux-tools && sudo ./m2_install.sh --install /path/to/ps5-bazzite-deck.img
   ```
   - Use the extracted `.img`, not the `.7z` files.
   - Keep the `.img` **on the USB system** (e.g. in `~/Downloads`), **not on the M.2**: the M.2 is wiped during the install.
   - Tip: type the command up to `--install ` (with the space), then drag the `.img` from the file manager into the
     terminal to insert its path.
   - **What you'll see:** `Formatting /dev/nvme0n1p1 …`, then `Copying files to M.2...`, and then **nothing for
     10–30 minutes** while it copies the system (there's no progress bar). Wait until it prints `Installation complete.`
   - **It asks for the password and then ends without printing anything:** `/boot/efi` isn't mounted, or it's mounted
     several times (from running a plain `mount` line more than once). Reset it to one mount, then run the install again:
     `while mountpoint -q /boot/efi; do sudo umount /boot/efi; done; sudo mount LABEL=boot /boot/efi`
   - `/dev/nvme0n1p1 not found`: the M.2 isn't prepared for Linux yet, see step 1 (`m2_init`).

3. **Boot from the M.2 from now on:** point `cmdline.txt` at the M.2:
   ```
   sudo sed -i 's/root=LABEL=bazzite-deck /root=LABEL=bazzite-deck-m2 /' /efi/cmdline.txt && sudo cat /efi/cmdline.txt
   ```

4. **Start it:** reboot (`sudo reboot`) and run the loader as usual; it now starts the system on the M.2.
   `cd ~/ps5-linux-tools && sudo ./m2_exec.sh` switches right away without a reboot; if it says `kexec` isn't
   found, just reboot instead.

To go back to the USB system, change `bazzite-deck-m2` back to `bazzite-deck` in `cmdline.txt`.

Notes:
- The first start from the M.2 can show a grey or black screen: reboot once and run the loader again.
- **The USB drive afterwards:** keep its small FAT32 partition (label `boot`): the loader always starts Linux from
  there, and updates put the new kernel there. The big Linux partition on the USB is only a fallback now. You can
  reformat that one for storage (only that partition, not the whole drive), but then you can no longer switch back
  to the USB system via `cmdline.txt`.
- Updating: run the in-place update while booted from the M.2, with the USB drive plugged in. The update script
  finds the USB drive's boot partition by itself: on an M.2 install it is often mounted at `/boot/efi` instead of
  `/efi`, or not at all.
- Commands in this README that edit `/efi/cmdline.txt`: on an M.2 install use `/boot/efi/cmdline.txt` if that's
  where it is mounted, or edit `cmdline.txt` from your PC.
- Stuck in emergency mode when booting the M.2: its `/etc/fstab` may contain a boot-partition line with an empty
  `UUID=`. Replace that line with `LABEL=boot /efi vfat defaults,nofail 0 2` (mount the M.2 from the USB system
  with `sudo mount LABEL=bazzite-deck-m2 /mnt` to edit it).
## 40 GPU compute units

The PS5's GPU has 40 compute units (CUs); Sony ships it with 36 active. The other 4 were switched off at the
factory, partly because on some chips one of them is faulty. That's the **silicon lottery**: on many consoles all
40 work and you get more GPU power, on others the extra units cause green dots and other artifacts, a purple
tint, or crashes. Try it, and switch it back off if you see any of that.

**Switch on** (in a terminal or over SSH), then reboot and run the loader:
```
sudo sed -i -e 's/amdgpu\.ps5_cu_unlock=[0-9]*/amdgpu.ps5_cu_unlock=3/' -e '/ps5_cu_unlock/!s/[[:space:]]*$/ amdgpu.ps5_cu_unlock=3/' /efi/cmdline.txt && sudo cat /efi/cmdline.txt
```
**Check:** `dmesg | grep active_cu_number` shows `40` (36 without it).

**Switch off** again:
```
sudo sed -i 's/ *amdgpu\.ps5_cu_unlock=[0-9]*//' /efi/cmdline.txt && sudo cat /efi/cmdline.txt
```

The setting stays as it is across updates.
## Features

- **One DualSense for the PS5 and Linux:** if the DualSense has pairing profiles (PS + a face button), keep the PS5
  pairing on one profile and pair Linux on another, for example PS + Square. On consoles with the MediaTek chip
  this is always on; on consoles with the IW620 chip (most original PS5s) switch it on with `ps5-bt-address on`.
  See [docs/dualsense-profiles.md](docs/dualsense-profiles.md).
- **Pairing a DualSense:** in Bluetooth settings, start the search, then hold **PS + Create** until the light
  flashes quickly. A controller that's still connected can't enter pairing mode: switch it off first (hold PS for
  10 seconds). After pairing it may disconnect once after a second; press PS and it reconnects. Later, just press PS.
- **TV remote over HDMI CEC:** the arrows, OK and back work in Game Mode and on the desktop, and at boot the PS5
  turns the TV on and switches it to its input; ` ps5-cec.one_touch_play=0` in `cmdline.txt` stops the latter.
- **Sleep:** a short press of the power button (or Steam's Sleep) puts the PS5 to sleep: screen off, orange light,
  the game paused. A short press wakes it. The GPU stays on, so it saves little power.
- **Resolutions:** 1080p60, 1080p120, 1440p60, 1440p120 and 4K60, whenever your TV/monitor can do them. Others
  aren't possible through the PS5's HDMI chip.
- **HDR** at 1080p60 and 4K60 (Game Mode → Settings → Display). If the picture looks wrong with HDR on, switch it off.
- **USB-C display output and PSVR2:** the front USB-C port drives a DisplayPort display or the PSVR2. From v1.6.1 it's
  off by default, because switching it on can reset a boot drive on that port: add ` usbc_dp.enable=1` to
  `cmdline.txt` to use it. For the PSVR2 you also need [PSVR2Toolkit](https://github.com/BnuuySolutions/PSVR2Toolkit).
- **CPU boost** (v1.5): the CPU may boost up to 3.5 GHz under load. `ps5-perf status` shows it and the fan target,
  `ps5-perf off` switches it off, `/etc/ps5-bazzite-deck/perf.conf` (`CPU_BOOST=`, `FAN_TARGET=` 40–90) changes it.
- **Restart straight back into Linux:** `ps5-warm-reboot on` makes every restart go straight back into Linux in about
  20 seconds, without the PS5 system and the loader; `ps5-warm-reboot off` turns it off. Experimental and off by
  default, because the PS5's hardware isn't reset by it: on some consoles the picture comes back garbled
  (Ctrl+Alt+F2, then Ctrl+Alt+F1). If Wi-Fi or Bluetooth is ever missing after one, power off and run the loader.
- **Video:** the PS5's GPU has no AV1 decoder. For YouTube in a browser, an extension like enhanced-h264ify gives
  hardware-decoded H.264 instead.
- **Apps:** use the Discover store / Flatpak. `dnf5 install` works for system packages; `rpm-ostree` and
  `ujust update` don't (this image isn't an ostree install).
- **VRR** isn't working yet; it's in the kernel as an experiment (boot options below). Where the research stands: [docs/vrr-status.md](docs/vrr-status.md).

## Troubleshooting

### Report a problem
Run this on the PS5 (terminal or SSH). It only reads, changes nothing, and saves one file with your hardware and the
relevant logs; post that file in [Discord](https://discord.gg/qGcuTgBBYU) (#bazzite-problems):
```
bash <(curl -fsSL https://raw.githubusercontent.com/VivaLaVent/ps5-bazzite-deck/main/tools/ps5-report.sh)
```
From v1.5.1 it's also built in: just `ps5-report`. Without network, run `ps5-report`, then
`sudo cp ~/ps5-report-*.txt /efi/`, shut down and take the file from the USB drive's small FAT32 partition on your PC.

**Testing VRR:** after each test, in the same boot, `vrr-report` (or
`bash <(curl -fsSL https://raw.githubusercontent.com/VivaLaVent/ps5-bazzite-deck/main/tools/vrr-report.sh)` before v1.5.1).

### 1. PS5 settings
Check the two settings from [Prerequisites](#prerequisites). A reset or a firmware update of the PS5 can change them back.

### 2. Linux loader
Use the latest version of **rmux's** [PS5 Linux loader](https://github.com/rmuxwashere/ps5-linux-loader/releases) for your
firmware. An older version, or one for a different firmware, typically ends up back in the PS5 menu or with no white light.

### 3. Boot options in cmdline.txt
`cmdline.txt` is on the USB drive's small FAT32 partition and must stay **one single line**: add an option at the
end with a space in front of it, or delete it again to undo. Leave the entries that are already there as they are.

| Option | What it does | When to use it |
|---|---|---|
| `amdgpu.force_1080p=1` | Only allows 1080p60 | Black or garbled picture you can't get past, e.g. after picking a resolution your display can't show. Remove it once you've set a working resolution |
| `hdmi.rearm=0` | Turns off the "picture comes back when the TV wakes up" fix | The picture flickers or goes black right after appearing, e.g. after re-plugging HDMI |
| `hdmi.rgb_range=0` | Lets the TV decide the RGB range again | Colours look wrong at 1080p or 4K60 but fine at 1440p |
| `usb-storage.quirks=xxxx:yyyy:u` | Turns off UAS for one USB drive (`xxxx:yyyy` from `lsusb`) | USB-C SSDs or enclosures that disconnect, freeze or show I/O errors (many have buggy UAS) |
| `dyndbg="file drivers/ps5/hdmi.c +p"` | Logs every HDMI chip event | When asked for an HDMI log for a black screen |
| `usbc_dp.enable=1` | Switches on the front USB-C port's DisplayPort output (v1.6.1+) | USB-C displays and the PSVR2. Not with your boot drive on the front USB-C port |
| `hdmi.vrr_test=1` | **Experimental:** VRR (FLAVA3 consoles, from v1.5.1) | Only for VRR testing, it doesn't work yet; the steps are in the v1.5.1 release notes, newer tests in `vrr-test` releases |

### Common problems

**White light but black screen**
- Check HDMI Device Link is off (see [Prerequisites](#prerequisites)).
- Try another TV/monitor or HDMI port, and try HDCP on and off in the PS5 settings.
- Last resort: `amdgpu.force_1080p=1` in `cmdline.txt` (see boot options).

**Black screen, but the PS5 is running** (sound works, or SSH works): with a USB keyboard press
<kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>F2</kbd>, wait 2–3 seconds, then <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>F1</kbd>: that sets the
picture up again. Switching the TV input away and back can also help. Over SSH: `sudo chvt 2; sleep 3; sudo chvt 1`.

**Games crash, freeze, or show green dots, artifacts or a purple tint**: if you switched on all 40 compute units,
switch them off again (see [40 GPU compute units](#40-gpu-compute-units)).

**Boots back into the PS5 menu**: you pressed the power button too early, or the USB power setting isn't
set to `Always`.

**Garbled picture in Game Mode on an older LG TV** (the desktop is fine): switch off "HDMI Ultra Deep Colour" for
that input for now.

## Support the project

This is a hobby project, built and tested in my free time. If it's useful to you, you can support it on
[Ko-fi](https://ko-fi.com/vivalavent). Thank you!
## Credits

- **[ps5-linux](https://github.com/ps5-linux)** (theflow, c0w, resulknad, rmuxnet and contributors) – the PS5 Linux
  loader, kernel patches and image builder this is built on.
- **[rmuxnet](https://github.com/rmuxnet)** – 7.3 PS5 kernel patches, video decoding, the
  [PS5 Linux Guide](https://rmuxnet.gitlab.io/ps5-linux-guide/).
- **[soniciso1](https://github.com/soniciso1)** – loader with firmware 13.60 support.
- **[ps5-linux-mwifiex](https://github.com/ps5-linux/ps5-linux-mwifiex)** contributors – PS5 Wi-Fi driver patches.
- **[WizGery](https://github.com/WizGery/ps5-mediatek-fixes)** – MediaTek Bluetooth patches.
- **[etawen](https://repo.etawen.dev/)** – PS5 package repo and documentation.
- **[Universal Blue / Bazzite](https://github.com/ublue-os/bazzite)** – Bazzite itself.
- **Gilles ([@VivaLaVent](https://github.com/VivaLaVent))** – made Game Mode work on the PS5, the Wi-Fi, Bluetooth and
  boot fixes, and this build.

Not affiliated with Sony, Valve or Universal Blue. Use at your own risk. Scripts and docs: MIT; patches: GPL-2.0.
