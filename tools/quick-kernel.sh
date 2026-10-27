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
# the initrd: the original is kept once (off the small boot partition). amdgpu is replaced INSIDE
# the initrd (unpack, swap the module, repack with the same compression), because appending an
# overlay doesn't fit on small boot partitions.
BASE=/var/lib/ps5-quick-kernel/initrd.img.base
sudo mkdir -p /var/lib/ps5-quick-kernel
if sudo test -f "$EFI/initrd.img.base"; then sudo mv "$EFI/initrd.img.base" "$BASE"; fi   # older installs kept it on the boot partition
sudo test -f "$BASE" || sudo cp "$EFI/initrd.img" "$BASE"
IP=$(sudo lsinitrd "$BASE" 2>/dev/null | grep -o '[^ ]*amdgpu/amdgpu\.ko[a-z.]*' | head -1 | sed 's#^\./##')
IP=${IP:-usr/lib/modules/$K/kernel/drivers/gpu/drm/amd/amdgpu/amdgpu.ko.zst}
W=$(mktemp -d /var/tmp/quick-initrd.XXXXXX); sudo chmod 700 "$W"
# an early (uncompressed) cpio for microcode may come first: split it off
if [ -x /usr/lib/dracut/skipcpio ] && sudo /usr/lib/dracut/skipcpio "$BASE" > "$W/main.img" 2>/dev/null && [ -s "$W/main.img" ]; then
  E=$(( $(sudo stat -c%s "$BASE") - $(stat -c%s "$W/main.img") )); sudo head -c "$E" "$BASE" > "$W/early.cpio"
else sudo cp "$BASE" "$W/main.img"; : > "$W/early.cpio"; fi
MAGIC=$(head -c4 "$W/main.img" | od -An -tx1 | tr -d ' ')
case "$MAGIC" in 28b52ffd) DEC="zstd -dc"; ENC="zstd -19 -T0 -q";; 1f8b*) DEC="gzip -dc"; ENC="gzip -9";; fd377a58) DEC="xz -dc"; ENC="xz --check=crc32 -9";; *) DEC="cat"; ENC="cat";; esac
mkdir "$W/root" && (cd "$W/root" && $DEC ../main.img | sudo cpio -idm --quiet 2>/dev/null)
[ -e "$W/root/$IP" ] || echo "note: $IP wasn't in the initrd; adding it"
sudo mkdir -p "$W/root/$(dirname "$IP")" && sudo cp amdgpu.ko.zst "$W/root/$IP"
(cd "$W/root" && sudo find . -print0 | sudo cpio --null -o -H newc --quiet | $ENC > "$W/main.new")
cat "$W/early.cpio" "$W/main.new" > "$W/initrd.img"
sudo rm -f "$EFI/initrd.img"   # make room first: the boot partition can be small
if ! sudo cp "$W/initrd.img" "$EFI/initrd.img"; then echo "STOP: no room on the boot partition; restoring"; sudo cp "$BASE" "$EFI/initrd.img"; sudo cp "$BK/bzImage" "$EFI/"; sudo rm -rf "$W"; exit 1; fi
sudo rm -rf "$W"
echo "initrd: amdgpu replaced inside ($IP), $(sudo du -h "$EFI/initrd.img" | cut -f1), boot partition free: $(df -h "$EFI" | awk 'NR==2{print $4}')"
echo "$(cat LABEL) (quick kernel)" | sudo tee /etc/ps5-bazzite-deck-version >/dev/null
sync
echo "DONE: $(cat LABEL) installed. Power off and start with the loader (no warm reboot)."
echo "undo: sudo cp $BK/bzImage $EFI/ && sudo cp $BASE $EFI/initrd.img && sudo cp $BK/$(basename "$M") $MD/ && sudo depmod $K && sudo cp $BK/ps5-bazzite-deck-version /etc/ && sync"
EOI
chmod +x "$O/install.sh"
tar -C "$B/output" -czf "$O.tar.gz" "$(basename "$O")"
echo "==> $O.tar.gz ($(du -h "$O.tar.gz" | cut -f1))"
if [ "${NO_INSTALL:-0}" != 1 ]; then
  echo "==> install on $PS5"
  scp "$O.tar.gz" "$PS5:~" && ssh -t "$PS5" "rm -rf ps5-quick-$L && tar xzf ps5-quick-$L.tar.gz && bash ps5-quick-$L/install.sh"
fi
