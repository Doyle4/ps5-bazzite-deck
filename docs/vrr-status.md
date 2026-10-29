# VRR on the PS5 (FLAVA3)

**VRR works** from v1.7.0 on consoles with the FLAVA3 HDMI chip, switched with Steam's VRR setting. Confirmed at
4K60, 1080p120, 1440p60 and 1440p120 on an LG C4. Consoles with the VERDE chip don't have it yet.

## How it works
The PS5's GPU doesn't drive HDMI itself: it sends DisplayPort to an HDMI chip, which normally re-times everything
to a fixed refresh rate. For VRR the chip has a "follow" mode, and three things make it work:
1. **A timing packet from the GPU every frame** (a DP extension SDP, header `39 04`, carrying the source timing).
   Without it, follow mode gives a black picture. It's on the GPU side, which is why no capture of the messages to
   the chip could show it.
2. **DPCD 0x107's MSA-ignore bit stays clear:** the chip drops its input lock when it's set, but follows a
   variable frame length with valid timing information.
3. **Follow mode is switched on after the packet flows,** step by step, plus a FreeSync InfoFrame for the TV. The
   picture stays dark meanwhile (about 2 seconds).

## Credits
- **Lawson:** the fix. He found the missing piece on the GPU side (his PS5 VRR kernel, vrr13) and the chip's MSA
  quirk.
- Thanks also to **hsgodd** for his captures of the stock system, and to **Gilles** for testing (LG C4).

## History
The test builds v1.5.1–v1.6.3 carried the experiments; their patches are in `patches/parked/vrr-history`.
Ruled out along the way: GPU timing (the GPU's variable timing worked from the start), a hardware limit, the
FreeSync InfoFrame's content, a VTEM to the TV, `0x7077`, the CLKUPD latch, the DRM and SPD InfoFrames, and
replaying Sony's own chip messages.

## Debugging
`hdmi.icc_trace=1` logs every message to the chip, `hdmi.vrr_measure=1` the measured frame intervals while VRR is
on, `vrr-report` collects a test run. `hdmi.vrr=0` never offers VRR.
