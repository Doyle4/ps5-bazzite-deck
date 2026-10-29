# Display problems: what to send us

For a black screen, a picture that blinks or reconnects, VRR that doesn't work, or a mode that doesn't show up.
This collects what we need to fix it: which modes your TV/monitor offers (its EDID), what the console offered and
picked, and what the HDMI chip did.

## 1. Get in
If you have a picture: open a terminal (Desktop Mode), or connect over SSH. If you don't: SSH from a PC
(`ssh ps5@<console IP>`, password `ps5`, IP from your router), or a keyboard and <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>F3</kbd>.
More in [display-recovery.md](display-recovery.md).

## 2. Make it happen, then collect
Pick the mode or switch on the setting that fails (VRR, HDR, 4K120…), wait about 15 seconds, then run this (one line):
```
F=~/display-log-$(date +%H%M).txt; { echo "== version"; cat /etc/ps5-bazzite-deck-version; uname -v; cat /proc/cmdline; echo "== EDID (base64)"; sudo cat /sys/class/drm/card0-DP-1/edid | base64 -w0; echo; echo "== modes offered"; cat /sys/class/drm/card0-DP-1/modes | sort | uniq -c; echo "== current mode and VRR"; sudo grep -E "crtc\[|enable=|active=|mode:|vrr_enabled" /sys/kernel/debug/dri/0/state 2>/dev/null | head -20; echo "== HDMI chip"; sudo dmesg | grep -i -e "hdmi" -e "VRR" -e "FRL" -e "re-arm" | tail -60; echo "== Game Mode"; journalctl --user -b --no-pager -o cat 2>/dev/null | grep -i -e "drm:" -e "modeset" -e "vrr" -e "adaptive" -e "edid" | tail -40; } > $F 2>&1; E=$(for d in /boot/efi /efi; do sudo test -f $d/cmdline.txt && echo $d && break; done); sudo cp $F $E/ 2>/dev/null; echo "saved $F"
```
It only reads. It saves `display-log-<time>.txt` in your home folder, and a copy on the drive's small FAT partition,
so without network you can take it from there on a PC.

## 3. Get the picture back
VRR: `export XDG_RUNTIME_DIR=/run/user/$(id -u) GAMESCOPE_WAYLAND_DISPLAY=gamescope-0; gamescopectl adaptive_sync 0`.
A mode: see [display-recovery.md](display-recovery.md).

## 4. Post it
In #bazzite-problems, attach the file and write:
- the **exact TV/monitor model**, and which HDMI port and cable
- **what you picked** (resolution, refresh rate, VRR on/off, HDR on/off) and **what you saw** (black, blinking,
  reconnecting, wrong colours)
- the display's own settings: VRR/FreeSync/Adaptive-Sync, HDMI enhanced format/Deep Colour, game mode
- whether it worked on an earlier version, and which
