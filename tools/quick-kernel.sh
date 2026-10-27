#!/bin/bash
# Quick kernel test without an image build (minutes instead of an hour), for kernel-only
# changes such as the VRR tests: builds bzImage (the HDMI driver is built in) and amdgpu.ko
# in the kernel builder container, packs them with an installer, and installs them on the PS5.
#   bash tools/quick-kernel.sh <label> [ps5-host]        e.g.  bash tools/quick-kernel.sh vrr-test11
# Output: ~/ps5-build-7.3/output/ps5-quick-<label>.tar.gz. The PS5 must run the same kernel
# version (7.3.0) the tree builds; the installer keeps a backup and prints the undo command.
set -euo pipefail
L=${1:?usage: quick-kernel.sh <label> [ps5-host]}; PS5=${2:-ps5@192.168.66.55}
B=~/ps5-build-7.3; K=$B/work/linux73; O=$B/output/ps5-quick-$L; mkdir -p "$O"; rm -rf "$O"/*
cd "$B"
echo "==> kernel build (bzImage + modules, incremental)"
docker run --rm -v "$K":/src -v "$B/work/ps5-linux-patches":/ps5-linux-patches:ro -v "$B/cache/ccache":/ccache \
  ps5-kernel-builder bash -c 'export CCACHE_DIR=/ccache; make -s LOCALVERSION= -j$(nproc) bzImage modules && make -s LOCALVERSION= kernelrelease > /src/.quick-release'
R=$(cat "$K/.quick-release"); rm -f "$K/.quick-release"
echo "    kernel release: $R"
cp "$K/arch/x86/boot/bzImage" "$O/bzImage"
zstd -q -f -o "$O/amdgpu.ko.zst" "$K/drivers/gpu/drm/amd/amdgpu/amdgpu.ko"
echo "$R" > "$O/KERNEL"; echo "$L" > "$O/LABEL"
cat > "$O/install.sh" << 'EOI'
#!/bin/bash
# Installs a quick test kernel (bzImage + amdgpu module) with a backup. Undo command at the end.
# amdgpu usually sits in the initrd too: instead of rebuilding the initrd, a small cpio archive
# with the new module is appended to the untouched original (the kernel reads concatenated
# archives, later files replace earlier ones). The original is kept as initrd.img.base.
set -euo pipefail
cd "$(dirname "$0")"
K=$(uname -r); [ "$K" = "$(cat KERNEL)" ] || { echo "STOP: running kernel $K, this build is $(cat KERNEL)"; exit 1; }
EFI=$(for d in /efi /boot/efi; do sudo test -f $d/bzImage && echo $d && break; done)
[ -n "$EFI" ] || { sudo mkdir -p /boot/efi; mountpoint -q /boot/efi || sudo mount LABEL=boot /boot/efi; EFI=/boot/efi; }
sudo test -f "$EFI/bzImage" || { echo "STOP: no bzImage on the boot partition"; exit 1; }
MD=/usr/lib/modules/$K/kernel/drivers/gpu/drm/amd/amdgpu; M=$(ls $MD/amdgpu.ko* | head -1)
BK=/var/lib/ps5-quick-kernel/$(date +%Y%m%d-%H%M%S); sudo mkdir -p "$BK"
sudo cp "$EFI/bzImage" "$EFI/initrd.img" "$M" /etc/ps5-bazzite-deck-version "$BK/" 2>/dev/null || true
sudo install -m644 bzImage "$EFI/bzImage"
sudo install -m644 amdgpu.ko.zst "$MD/amdgpu.ko.zst"; [ "$M" = "$MD/amdgpu.ko.zst" ] || sudo rm -f "$M"
sudo depmod "$K"
# the initrd: original kept once as initrd.img.base, new initrd = base + overlay with the module
sudo test -f "$EFI/initrd.img.base" || sudo cp "$EFI/initrd.img" "$EFI/initrd.img.base"
IP=$(sudo lsinitrd "$EFI/initrd.img.base" 2>/dev/null | grep -o '[^ ]*amdgpu/amdgpu\.ko[a-z.]*' | head -1 | sed 's#^\./##')
IP=${IP:-usr/lib/modules/$K/kernel/drivers/gpu/drm/amd/amdgpu/amdgpu.ko.zst}
T=$(mktemp -d); mkdir -p "$T/$(dirname "$IP")"; cp amdgpu.ko.zst "$T/$IP"
(cd "$T" && find . -print0 | cpio --null -o -H newc --owner=0:0 --quiet) > /tmp/amdgpu-overlay.cpio
sudo sh -c "cat '$EFI/initrd.img.base' /tmp/amdgpu-overlay.cpio > '$EFI/initrd.img'"
rm -rf "$T" /tmp/amdgpu-overlay.cpio
echo "initrd: original + overlay with $IP ($(sudo du -h "$EFI/initrd.img" | cut -f1))"
echo "$(cat LABEL) (quick kernel)" | sudo tee /etc/ps5-bazzite-deck-version >/dev/null
sync
echo "DONE: $(cat LABEL) installed. Power off and start with the loader (no warm reboot)."
echo "undo: sudo cp $BK/bzImage $EFI/ && sudo cp $EFI/initrd.img.base $EFI/initrd.img && sudo cp $BK/$(basename "$M") $MD/ && sudo depmod $K && sudo cp $BK/ps5-bazzite-deck-version /etc/ && sync"
EOI
chmod +x "$O/install.sh"
tar -C "$B/output" -czf "$O.tar.gz" "$(basename "$O")"
echo "==> $O.tar.gz ($(du -h "$O.tar.gz" | cut -f1))"
if [ "${NO_INSTALL:-0}" != 1 ]; then
  echo "==> install on $PS5"
  scp "$O.tar.gz" "$PS5:~" && ssh -t "$PS5" "rm -rf ps5-quick-$L && tar xzf ps5-quick-$L.tar.gz && bash ps5-quick-$L/install.sh"
fi
