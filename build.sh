#!/bin/sh
set -e
set -o pipefail

version="${1:-21.3-Omega}"

source_img_name="CoreELEC-Amlogic-ng.arm-${version}-Generic"
source_img_file="${source_img_name}.img.gz"
source_img_url="https://github.com/CoreELEC/CoreELEC/releases/download/${version}/${source_img_file}"

target_img_prefix="CoreELEC-Amlogic-ng.arm-${version}"
build_date="$(date +%Y.%m.%d)"
target_img_name="${target_img_prefix}-E900V22C-${build_date}"

mount_point="target"
common_files="common-files"
system_root="SYSTEM-root"

modules_load_path="${system_root}/usr/lib/modules-load.d"
systemd_path="${system_root}/usr/lib/systemd/system"
libreelec_path="${system_root}/usr/lib/libreelec"
config_path="${system_root}/usr/config"
kodi_userdata="${mount_point}/.kodi/userdata"

echo "=================================================="
echo " CoreELEC ${version} build for Skyworth E900V22C"
echo "=================================================="

echo "[1/10] Downloading CoreELEC generic image"
wget "${source_img_url}" -O "${source_img_file}" || exit 1

echo "[2/10] Decompressing image"
gzip -d "${source_img_file}" || exit 1

echo "[3/10] Preparing mount point"
mkdir -p "${mount_point}"

echo "[4/10] Mounting BOOT partition"
sudo mount -o loop,offset=4194304 "${source_img_name}.img" "${mount_point}"

echo "[5/10] Applying device-specific files"

# DTB
sudo cp "${common_files}/e900v22c.dtb" "${mount_point}/dtb.img"

echo "  - Extracting SYSTEM squashfs"
sudo unsquashfs -d "${system_root}" "${mount_point}/SYSTEM"

# WiFi modules-load
sudo cp "${common_files}/wifi_dummy.conf" "${modules_load_path}/wifi_dummy.conf"
sudo chmod 0664 "${modules_load_path}/wifi_dummy.conf"

# systemd service
sudo cp "${common_files}/sprd_sdio-firmware-aml.service" \
        "${systemd_path}/sprd_sdio-firmware-aml.service"
sudo chmod 0664 "${systemd_path}/sprd_sdio-firmware-aml.service"
sudo ln -sf ../sprd_sdio-firmware-aml.service \
        "${systemd_path}/multi-user.target.wants/sprd_sdio-firmware-aml.service"

# fs-resize
sudo cp "${common_files}/fs-resize" "${libreelec_path}/fs-resize"
sudo chmod 0775 "${libreelec_path}/fs-resize"

# remote keymap
sudo cp "${common_files}/rc_maps.cfg" "${config_path}/rc_maps.cfg"
sudo chmod 0664 "${config_path}/rc_maps.cfg"

sudo cp "${common_files}/e900v22c.rc_keymap" \
        "${config_path}/rc_keymaps/e900v22c"
sudo chmod 0664 "${config_path}/rc_keymaps/e900v22c"

echo "[6/10] Rebuilding SYSTEM squashfs"
sudo mksquashfs "${system_root}" SYSTEM \
  -comp lzo \
  -Xalgorithm lzo1x_999 \
  -Xcompression-level 9 \
  -b 524288 \
  -no-xattrs

echo "[7/10] Replacing SYSTEM (safe mode, no dd)"
sudo rm -f "${mount_point}/SYSTEM"
sudo mv SYSTEM "${mount_point}/SYSTEM"
sudo md5sum "${mount_point}/SYSTEM" > "${mount_point}/SYSTEM.md5"

sudo rm -rf "${system_root}"

echo "[8/10] Unmounting BOOT partition"
sudo umount "${mount_point}"

echo "[9/10] Mounting DATA partition"
sudo mount -o loop,offset=541065216 "${source_img_name}.img" "${mount_point}"

sudo mkdir -p -m 0755 "${kodi_userdata}/keymaps"

sudo cp "${common_files}/advancedsettings.xml" \
        "${kodi_userdata}/advancedsettings.xml"
sudo chmod 0644 "${kodi_userdata}/advancedsettings.xml"

sudo cp "${common_files}/backspace.xml" \
        "${kodi_userdata}/keymaps/backspace.xml"
sudo chmod 0644 "${kodi_userdata}/keymaps/backspace.xml"

echo "[10/10] Finalizing image"
sudo umount "${mount_point}"
rm -rf "${mount_point}"

mv "${source_img_name}.img" "${target_img_name}.img"
gzip "${target_img_name}.img"
sha256sum "${target_img_name}.img.gz" > "${target_img_name}.img.gz.sha256"

echo "=================================================="
echo " Build completed successfully:"
echo "  ${target_img_name}.img.gz"
echo "=================================================="
