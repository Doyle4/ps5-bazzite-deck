# Testers

Who can test which hardware combination. A change for one chip needs a test on the other chip
of the same kind before a release goes stable (docs/release-checklist.md). To add yourself, run
`bash <(curl -fsSL https://raw.githubusercontent.com/VivaLaVent/ps5-bazzite-deck/main/tools/ps5-report.sh)`
and paste its SUMMARY line in Discord.

Fields marked `?` aren't confirmed yet; the SUMMARY line fills them in.

| Tester | Model / firmware | HDMI | Wi-Fi/BT | Display | Install | Good for |
|---|---|---|---|---|---|---|
| Gilles | original PS5 | FLAVA3 | IW620 | ? | USB | builds, warm reboot, Bluetooth |
| ObsessiveRug | original PS5, 13.00 | ? | IW620 | monitor, 75 Hz | ? | fresh installs, first boot |
| kishy (Yoshi) | Slim, 13.60 | FLAVA3? | ? | LG C4; older LG (Deep Colour) | M.2 + spare USB-C M.2 | Slim tests, HDR |
| hsgodd | original PS5 | FLAVA3 | ? | LG OLED (HDMI 2.1) | ? | VRR, stock-system research |
| pukason | Slim | FLAVA3 | ? | Samsung (VRR) | ? | VRR, DPCD data |
| furbs | original PS5, 12.70 | FLAVA3 | ? | LG C1 | ? | VRR |
| loseheaven | Slim, 12.20 | ? | ? | ? | M.2 | Slim Wi-Fi problem |
| Max | original PS5 | ? | IW620 | ? | ? | Bluetooth |

Missing so far: anyone with a **Verde** HDMI chip, and a confirmed **MediaTek** console that
tests regularly.
