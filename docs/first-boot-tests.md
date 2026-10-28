# First-boot tests

Small, separate tests for the open first-boot issues. Each one answers one question; run them
one at a time and post the output in Discord. Commands run over SSH or in a terminal
(Ctrl+Alt+F2 on the console, user `ps5`, password `ps5`).

## Test 1: Steam Deck or Steam Machine variant
Bazzite-Deck is made for handhelds and TV setups alike. For TV setups its documentation sets
`SteamDeck=0` (in `~/.config/environment.d/10-gamescope-session.conf`) to switch the Steam Deck
behaviour off. Question: does that alone make the first setup go straight to the Steam Machine
variant?

**Which variant is running right now** (in Game Mode):
```
tr '\0' '\n' < /proc/$(pgrep -f -o gamescope-session)/environ 2>/dev/null | grep -i -e '^SteamDeck' -e '^STEAM_'; pgrep -a steam | grep -o -e '-steamdeck' -e '-steamos3' -e '-gamepadui' | sort -u; cat ~/.config/environment.d/*.conf 2>/dev/null
```

**A/B test without reflashing:** Bazzite's `ujust fix-reset-steam` puts Steam back to its first
start.
1. Without the setting: `rm -f ~/.config/environment.d/10-gamescope-session.conf; ujust fix-reset-steam`,
   restart into Game Mode, go through the setup. Note: asked once or twice? Steam Deck or Steam
   Machine layout (Settings looks like a Deck's)? Bluetooth on afterwards? Run the command above.
2. With the setting: `mkdir -p ~/.config/environment.d && echo SteamDeck=0 > ~/.config/environment.d/10-gamescope-session.conf; ujust fix-reset-steam`,
   restart into Game Mode, same notes, same command.

If 2 is always the Steam Machine variant and 1 sometimes isn't, the image ships the setting.

## Test 2: the console switching off after the Wi-Fi step
Question: does something request a reboot or a power-off there (most likely Steam finishing its
update)? On the PS5 a reboot goes through the PS5 system, which can look like switching off.

After it happened, start Linux again (cold, with the loader) and run:
```
journalctl -b -1 --no-pager | grep -i -e "system is rebooting" -e "system is powering" -e "power key" -e "reboot" -e "poweroff" -e "shutdown" | tail -15; journalctl --list-boots | tail -3
```
A line naming `reboot` with Steam or steamos-session nearby means Steam restarted the system.
`Power key` means a button press; nothing at all means it really switched off (then a photo of
the last screen helps).

## Test 3: boot and session-switch timings
Question: are boots and Game Mode ↔ desktop switches getting slower between releases? Run on the
same console on each release you have (for example 1.3.1, 1.4.1, 1.5.0), each time after a cold
start, then do one switch Game Mode → desktop → Game Mode and run:
```
cat /etc/ps5-bazzite-deck-version; systemd-analyze | head -2; systemd-analyze blame | head -8; journalctl -b -o short-precise --no-pager | grep -e "Starting Wayland user session" -e "Reached target Graphical" | tail -6
```
`systemd-analyze` gives the boot time; the "Starting Wayland user session" lines are the moments
each session was started, so the switch time is the gap between one switch and the next line.
Add how long it took until you saw the picture (a phone stopwatch is fine).

## Test 4: the first-start message
Question: is the "Steam is setting itself up, don't power off" message visible anywhere? After
`ujust fix-reset-steam` (test 1) and a cold start, watch the screen with the blinking cursor.
Then: `systemctl status ps5-first-start --no-pager | tail -5`. If the service ran but nothing
showed, the screen is covered by the boot splash and the message needs another place.
