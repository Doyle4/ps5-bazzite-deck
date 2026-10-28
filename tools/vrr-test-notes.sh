#!/bin/bash
# Release notes for a vrr-test quick-kernel release: the same install, test and report steps
# every time, plus what this test changes. Usage: tools/vrr-test-notes.sh <tag> "<what it changes>" [variant help] [base version]
TAG=$1; WHAT=$2; VARIANT=${3:-}; BASE=${4:-v1.5.1}
R=VivaLaVent/ps5-bazzite-deck
cat << NOTES
**VRR test for $BASE installs (FLAVA3 consoles). Not a release.** A quick kernel: no reflash, the installer keeps a backup and prints an undo line.

## What this test changes
$WHAT

## Install
\`\`\`
cd ~ && rm -rf ps5-quick-$TAG* && curl -LO https://github.com/$R/releases/download/$TAG/ps5-quick-$TAG.tar.gz && tar xzf ps5-quick-$TAG.tar.gz && bash ps5-quick-$TAG/install.sh
\`\`\`
Then add \` hdmi.vrr_test=1\` to the end of \`cmdline.txt\` (one line), **power off and start with the loader** (cold, not a restart).

## Test (same steps every time, so results compare)
1. **TV:** VRR on for that HDMI input (LG: "VRR & G-Sync" and "AMD FreeSync Premium"; Samsung: Game Mode + FreeSync; Sony: VRR in the input settings).
2. **Game Mode:** HDR off. Pick one mode and note it (4K60, 1440p120 or 1080p120).
3. Start a fullscreen game, limit it to **60 fps** (quick access menu → Performance), and switch **VRR on** (same menu or Settings → Display).
4. Watch for a minute: picture, black, no signal, flicker, rolling/drift? What does the TV show (VRR/FreeSync indicator, refresh rate)?
5. **The chip's own VRR mode** (the main test): \`echo 1 | sudo tee /sys/module/hdmi/parameters/vrr_chip\`, then VRR off and on again in the game, and watch again.
$( [ -n "$VARIANT" ] && echo "6. **Variant:** $VARIANT" )

## Report (right after each test, same boot)
\`\`\`
bash <(curl -fsSL https://raw.githubusercontent.com/$R/main/tools/vrr-report.sh)
\`\`\`
It asks four short questions (display, mode, what you saw, what the TV showed) and saves one file with the kernel's VRR log. **Post that file** in #bazzite-prereleases-experimental with the test name (e.g. "$TAG, vrr_chip=1"), **one post per variant**. A photo of the TV helps for flicker or rolling, but not instead of the file.

## Back to normal
Remove \` hdmi.vrr_test=1\` from \`cmdline.txt\` (the test code then stays off), or run the undo line the installer printed, then a cold start.
NOTES
