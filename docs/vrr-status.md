# VRR status (FLAVA3 consoles)

VRR doesn't work yet. This page keeps the state of the research in one place, so tests aren't repeated.
The research is hsgodd's (stock-system captures and reverse engineering), with test builds from this repo.

## Where it stands
- **The GPU side works:** with VRR on, amdgpu programs a variable frame length and the measured frame
  intervals follow the game (test 21: about 16.7 ms at a 60 fps cap on a 120 Hz mode).
- **The HDMI chip is the blocker,** and it's software, not hardware: the stock PS5 system gets real HDMI VRR
  through the same chip on the same TV.
  - In its normal mode the chip re-times the GPU's variable signal to a fixed 120 Hz: rolling or flickering
    picture.
  - In its own VRR mode, as Linux programs it, the TV gets no signal.
- **The missing piece:** Sony registers a sequence with the chip's controller (the EMC) at every video setup,
  **sequence `0x30`**, which arms the chip's VRR packet generator (VTEM/EMP). Stored sequences only run when a
  trigger is bound to them (a 4/2 command: sequence id → trigger bit). Linux binds `0x31`–`0x37` but not
  `0x30`, so the arming never runs. The binding most likely comes from Sony's user-space HDMI library at
  initialisation, which the captures so far didn't cover.

## Ruled out (tested, not to be revisited)
GPU timing / DRR (test 21) · a hardware limit (stock works) · the FreeSync InfoFrame's content · a VTEM sent to
the TV (test 17) · `0x7077` (tests 18/19; it's pixel clock / 100) · the CLKUPD latch (stock has none) ·
re-applying the setup on re-announce (test 20) · the unmute · the DRM and SPD InfoFrames (test 24) · the replay
mechanism itself (test 25: the EMC accepts stock's sequence 1:1, it just never runs).

## Test 26 result (v1.5.6, Gilles, LG)
- **The trigger table (4/2) has a fixed size of 7 entries:** 8 entries or a single one are rejected (status `04 10`);
  the last slot (`0x7c00`) also refuses `0x30`.
- **`0x30` in each of the other six slots** (`0x7ab8/08`, `0x7ab0/05`, `0x7aa0/05`, `0x7ae1/01`, `0x7ae2/01`,
  `0x7ae0/01`): registered and bound with status `00`, VRR switched on, **no picture** in any of them.
- So `0x30` isn't triggered by any of the known trigger bits. With the table full at 7, Sony's user-space
  binding most likely uses **a different command** than 4/2 (or a different table).

## Test 27 result (v1.5.6, Gilles, LG)
Sequence `0x30`'s 11 commands run by hand as an ordinary message, 3 s and 8 s after VRR switched on in the chip's
own mode: executed with status `00` both times, **no picture**. So the arming's content alone, at those moments,
doesn't make the chip produce a VRR output. Whatever else Sony does (the trigger moment, other messages around it,
or state in the EMC) isn't visible from Linux.

## Next
From Linux, nothing is left to try without new information from the stock side:
1. **A cold-boot ICC capture on the stock system** (hsgodd): every message from initialisation on, looking for
   anything that mentions `0x30`, any type-4 command other than 4/2 and 4/16, and any 5/x command. Whatever it
   shows can be sent with `hdmi.icc_send` (v1.5.6) without a rebuild.
2. **A decrypted EMC firmware from a firmware version with VRR** (the PS5 got VRR in 2022): it would show what the
   EMC does with sequence `0x30` and how it is triggered. A 4.50 image (pre-VRR) exists for comparison.

## Tools for testers
`hdmi.vrr_test=1` in `cmdline.txt` enables everything; switches under `/sys/module/hdmi/parameters/vrr_*`;
`hdmi.icc_trace=1` logs every message to the chip; `vrr-report` collects a test run in one file. No picture
after switching VRR on: `gamescopectl adaptive_sync 0` over SSH (see the release notes).
