# No picture? Getting in, and changing the display mode by command

When the console is running but the TV shows nothing (wrong mode, a mode the TV doesn't take), you can still reach it
and change the mode. Default user and password: `ps5` / `ps5`.

## 1. Get a shell

**With a keyboard on the PS5 (TTY):** press <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>F3</kbd> for a text login (user `ps5`,
password `ps5`). Back to the picture: <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>F1</kbd> or <kbd>F2</kbd>. If the TV shows
nothing at all, the text console won't show either; use SSH.

**Over the network (SSH):** from a PC on the same network (Windows: PowerShell; macOS/Linux: a terminal):
```
ssh ps5@<console IP>
```
Password `ps5`. The console's IP is in your router's list of devices (often named `bazzite`).

## 2. Game Mode

**VRR off or on:**
```
export XDG_RUNTIME_DIR=/run/user/$(id -u) GAMESCOPE_WAYLAND_DISPLAY=gamescope-0
gamescopectl adaptive_sync 0      # off (1 = on)
```
The picture comes back within a few seconds.

**Resolution:** Game Mode takes its resolution from Steam's settings, which have no command. If it remembered a mode
the TV can't show, take that mode away for one boot, so Game Mode falls back to one that works:
```
E=$(for d in /boot/efi /efi; do sudo test -f $d/cmdline.txt && echo $d && break; done)
sudo sed -i 's/[[:space:]]*$/ amdgpu.force_1080p=1/' $E/cmdline.txt && sudo systemctl poweroff
```
Start with the loader: Game Mode comes up at 1080p60. Set the mode you want in Settings → Display, then remove the
option again and power off:
```
E=$(for d in /boot/efi /efi; do sudo test -f $d/cmdline.txt && echo $d && break; done)
sudo sed -i 's/ *amdgpu\.force_1080p=1//' $E/cmdline.txt && sudo systemctl poweroff
```
For **4K120** only: ` hdmi.frl_4k120=0` instead of ` amdgpu.force_1080p=1` takes just that mode away.

**Switch to the desktop instead:** `steamos-session-select plasma` (back: `steamos-session-select gamescope`).

## 3. Desktop Mode

KDE's `kscreen-doctor` changes the mode directly. Over SSH, first:
```
export XDG_RUNTIME_DIR=/run/user/$(id -u) DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus
```
Then:
```
kscreen-doctor -o                                   # outputs and their modes (the HDMI output is DP-1)
kscreen-doctor output.DP-1.mode.3840x2160@60        # resolution@refresh
kscreen-doctor output.DP-1.hdr.disable              # HDR off (enable = on)
kscreen-doctor output.DP-1.vrrpolicy.never          # VRR off (automatic = only fullscreen apps, always)
```
Unlike System Settings, `kscreen-doctor` applies the change at once, without a "keep this mode?" question, so check
the TV after each change; to undo, run it again with the previous mode.

## 4. The TV itself

After a failed 4K120 attempt some TVs stay dark at every mode. Unplug the TV's power for a minute (standby isn't
enough), then start the console again.
