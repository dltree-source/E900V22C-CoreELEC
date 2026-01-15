#!/bin/sh
set -e

# ===== Version handling =====
version="${1:-21.3-Omega}"

source_img_name="CoreELEC-Amlogic-ng.arm-${version}-Generic"
source_img_file="${source_img_name}.img.gz"
source_img_url="https://github.com/CoreELEC/CoreELEC/releases/download/${version}/${source_img_name}.img.gz"

build_date="$(date +%Y.%m.%d)"
target_img_prefix="CoreELEC-Amlogic-ng.arm-${version}"
target_img_name="${target_img_prefix}-E900V22C-${build_date}"

mount_point="target"
common_files="common-files"
system_root="SYSTEM-root"

modules_load_path="${system_root}/usr/lib/modules-load.d"
systemd_path="${system_root}/usr/lib/systemd/system"
libreelec_path="${system_root}/usr/lib/libreelec"
config_path="${system_root}/usr/config"
kodi_userdata="${mount_point}/.kodi/userdata"

echo "================================================="
echo " CoreELEC E900V22C Builder"
echo " Version : ${version}"
echo " Date    : ${build_date}"
echo "================================================="

echo "Downloading CoreELEC generic image"
wget "${source_img_url}" -O "${source_img_file}" || exit 1

echo "Decompressing CoreELEC image"
gzip -d "${source_img_file}" || exit 1

echo "Creating mount point"
mkdir -p "${mount_point}"

echo "Mounting CoreELEC boot partition"
sudo mount -o loop,offset=4194304 "${source_img_name}.img" "${mount_point}"

echo "Copying E900V22C DTB file"
sudo cp "${common_files}/e900v22c.dtb" "${mount_point}/dtb.img"

echo "Decompressing SYSTEM image"
sudo unsquashfs -d "${system_root}" "${mount_point}/SYSTEM"

echo "Copying modules-load config"
sudo cp "${common_files}/wifi_dummy.conf" "${modules_load_path}/"
sudo chmod 0664 "${modules_load_path}/wifi_dummy.conf"

echo "Copying systemd service"
sudo cp "${common_files}/sprd_sdio-firmware-aml.service" "${systemd_path}/"
sudo chmod 0664 "${systemd_path}/sprd_sdio-firmware-aml.service"
sudo ln -sf ../sprd_sdio-firmware-aml.service \
  "${systemd_path}/multi-user.target.wants/sprd_sdio-firmware-aml.service"

echo "Copying fs-resize script"
sudo cp "${common_files}/fs-resize" "${libreelec_path}/"
sudo chmod 0775 "${libreelec_path}/fs-resize"

echo "Copying remote keymap files"
sudo cp "${common_files}/rc_maps.cfg" "${config_path}/"
sudo cp "${common_files}/e900v22c.rc_keymap" "${config_path}/rc_keymaps/e900v22c"
sudo chmod 0664 "${config_path}/rc_maps.cfg"
sudo chmod 0664 "${config_path}/rc_keymaps/e900v22c"

echo "Rebuilding SYSTEM squashfs"
sudo mksquashfs "${system_root}" SYSTEM \
  -comp lzo -Xalgorithm lzo1x_999 -Xcompression-level 9 \
  -b 524288 -no-xattrs

sudo rm -f "${mount_point}/SYSTEM.md5"
sudo dd if=/dev/zero of="${mount_point}/SYSTEM"
sudo sync
sudo rm "${mount_point}/SYSTEM"
sudo mv SYSTEM "${mount_point}/SYSTEM"
sudo md5sum "${mount_point}/SYSTEM" > "${mount_point}/SYSTEM.md5"

sudo rm -rf "${system_root}"

echo "Unmounting boot partition"
sudo umount -d "${mount_point}"

echo "Mounting data partition"
sudo mount -o loop,offset=541065216 "${source_img_name}.img" "${mount_point}"

sudo mkdir -p -m 0755 "${kodi_userdata}/keymaps"
sudo cp "${common_files}/advancedsettings.xml" "${kodi_userdata}/"
sudo cp "${common_files}/backspace.xml" "${kodi_userdata}/keymaps/"
sudo chmod 0644 "${kodi_userdata}/advancedsettings.xml"
sudo chmod 0644 "${kodi_userdata}/keymaps/backspace.xml"

echo "Unmounting data partition"
sudo umount -d "${mount_point}"
rm -rf "${mount_point}"

echo "Finalizing image"
mv "${source_img_name}.img" "${target_img_name}.img"
gzip "${target_img_name}.img"
sha256sum "${target_img_name}.img.gz" > "${target_img_name}.img.gz.sha256"

echo "Build complete:"
ls -lh "${target_img_name}.img.gz"*
