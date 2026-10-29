# Porting Slip's HDMI test candidate (native FRL, 4K120, ALLM)

Source: [Slip-Up/ps5-linux-patches `88649db`](https://github.com/Slip-Up/ps5-linux-patches/commit/88649db40a66c9988374e6ebdffe89aa4b996673)
("add HDMI test candidate and make USB-C DP opt-in"), on upstream `730b80e` and Linux 7.2.3. Not yet submitted
upstream: it can still change before Slip's PR, so the port follows his candidate and gets re-synced later.

## Scope (what his commit changes in the kernel)
| Part | Size | State in our tree |
|---|---|---|
| `drivers/ps5/hdmi.c` | +950 lines | 3-way merge (base upstream `730b80e`, ours v1.7.1, his): **15 conflicts** |
| `frl-plan.inc`, `frl-native.inc`, `frl-native-msgs.h`, `frl-detect.inc`, `frl-recovery.inc` | ~1,050 lines, new | taken as-is, included from `hdmi.c` |
| `include/linux/ps5.h` | +74 | merge |
| `amdgpu_dm.c` / `amdgpu_dm.h` | +540 / +17 | port by hand: his patch is against 7.2.3, ours is 7.3 with our own PS5 changes |
| `spcie.c` | small | robustness fixes (zero-initialised notification, bounded length): take |
| `usbc_dp.c` | small | **done** (v1.6.1, USB-C DP opt-in) |
| `drm_edid.c`, Pro-related comment rewording (gfx_v10, SMU, mp1, thermal) | small | check / not needed |

## hdmi.c conflicts
Most are small (his functions returning `int` errors, an `i2c_lock` mutex around the shared I2C context, AVI and
range handling). The two large ones:
- **#10, before the FLAVA3 video setup:** our VRR block (follow mode, timing packet range, mute deferral) vs his
  FRL setup hooks. Both stay; VRR has to work with his output plan (FRL modes go through a different chip setup,
  and Lawson saw VRR at 4K120 over FRL).
- **#15, the notification handler:** our EDID keep, re-arm, session-switch and VRR EDID save vs his FRL detection
  and recovery. Needs the handler rebuilt carefully on both sets of behaviour.

His `i2c_lock` is worth keeping on its own: our VRR follow work deliberately avoided the shared I2C context because
nothing protected it.

## Order of work
1. **hdmi.c core:** the small conflicts, `i2c_lock`, the `int` error returns, his mode/colour/range handling next to
   our RGB fix (his "colour handling" overlaps v1.6.0's RGB range fix: one implementation, tested on an LG with
   "Auto").
2. **FRL files + amdgpu output plan:** native FRL behind his `hdmi.frl_4k120` (off by default, as in his build).
3. **VRR over FRL:** check follow mode at 4K120 (Lawson's result) once 2 works.
4. **ALLM and FRL recovery:** his `hdmi.allm`, `hdmi.frl_recovery`, off by default.
Each step a 1.7.x test build, with his README's test order (defaults → FRL → 4:2:0 → ALLM → recovery).

## Workspace
`research/port-slip/` (outside the repo): base/ours/his `hdmi.c`, the merge with conflict markers, his new files, and
his `amdgpu_dm` changes as a diff of upstream's patch.
