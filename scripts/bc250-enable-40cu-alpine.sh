#!/bin/sh
# bc250-enable-40cu-alpine.sh — Build and install patched amdgpu for 40 CU on Alpine Linux
#
# Usage:
#   doas ./bc250-enable-40cu-alpine.sh build   # patch + compile + install
#   doas ./bc250-enable-40cu-alpine.sh enable  # set 40 CU mode and reboot
#   doas ./bc250-enable-40cu-alpine.sh disable # return to stock 24 CU and reboot
#   doas ./bc250-enable-40cu-alpine.sh status  # show current CU state
#   doas ./bc250-enable-40cu-alpine.sh restore # restore original amdgpu module

set -euo pipefail

KVER="$(uname -r)"
CLEAN_KVER="${KVER%%-*}"
MODDIR="/lib/modules/${KVER}"
MODPATH="${MODDIR}/kernel/drivers/gpu/drm/amd/amdgpu/amdgpu.ko"
BUILDDIR="/tmp/bc250-40cu-build"
CONF40="/etc/modprobe.d/bc250-40cu.conf"
BACKUP_SUFFIX=".bc250-backup-$(date +%Y%m%d)"
BC250_PCI_ID="13fe"

info()  { printf '\033[0;32m[+]\033[0m %s\n' "$*" >&2; }
warn()  { printf '\033[0;33m[!]\033[0m %s\n' "$*" >&2; }
err()   { printf '\033[0;31m[E]\033[0m %s\n' "$*" >&2; }
die()   { err "$@"; exit 1; }

check_bc250() {
    local detected=0
    if vulkaninfo --summary 2>/dev/null | grep -qi "${BC250_PCI_ID}"; then
        detected=1
    elif grep -qr "0x${BC250_PCI_ID}" /sys/class/drm/card*/device/device 2>/dev/null; then
        detected=1
    fi

    if [ "$detected" -eq 0 ]; then
        warn "No BC-250 (PCI ID ${BC250_PCI_ID}) detected."
        printf "Continue anyway? [y/N] " >&2
        read -r ans
        case "$ans" in y|Y) ;; *) exit 1 ;; esac
    else
        info "BC-250 (PCI ID ${BC250_PCI_ID}) successfully verified."
    fi
}

check_deps() {
    local pkgs_to_install=""
    command -v gcc >/dev/null 2>&1 || pkgs_to_install="${pkgs_to_install} gcc"
    command -v make >/dev/null 2>&1 || pkgs_to_install="${pkgs_to_install} make"
    command -v python3 >/dev/null 2>&1 || pkgs_to_install="${pkgs_to_install} python3"
    command -v vulkaninfo >/dev/null 2>&1 || pkgs_to_install="${pkgs_to_install} vulkan-tools"
    command -v curl >/dev/null 2>&1 || pkgs_to_install="${pkgs_to_install} curl"
    
    if ! diff --version 2>/dev/null | grep -q GNU; then
        pkgs_to_install="${pkgs_to_install} diffutils"
    fi
    if ! awk --version 2>/dev/null | grep -q GNU; then
        pkgs_to_install="${pkgs_to_install} gawk"
    fi
    
    if [ ! -d "${MODDIR}/build" ]; then
        local flavor="lts"
        case "${KVER}" in
            *-virt*) flavor="virt" ;;
            *-hardened*) flavor="hardened" ;;
            *-zen*) flavor="zen" ;;
            *) flavor="lts" ;;
        esac
        pkgs_to_install="${pkgs_to_install} linux-${flavor}-dev linux-headers build-base pahole elfutils-dev openssl-dev flex bison bc perl zstd-dev syslinux"
    fi

    if [ -n "$pkgs_to_install" ]; then
        info "Missing dependencies detected. Installing via apk:${pkgs_to_install}..."
        apk update
        # shellcheck disable=SC2086
        apk add --no-cache ${pkgs_to_install}
    fi
}

find_source() {
    local src_tar="/tmp/linux-${CLEAN_KVER}.tar.xz"
    if [ ! -d "${BUILDDIR}/linux-${CLEAN_KVER}" ]; then
        info "Downloading vanilla kernel source for ${CLEAN_KVER}..."
        mkdir -p "$BUILDDIR"
        curl -L "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${CLEAN_KVER}.tar.xz" -o "$src_tar"
        tar -xf "$src_tar" -C "$BUILDDIR"
    fi
    MODSRC="${BUILDDIR}/linux-${CLEAN_KVER}"
    [ -f "${MODSRC}/drivers/gpu/drm/amd/amdgpu/gfx_v10_0.c" ] || die "Kernel source tree invalid."
}

patch_source() {
    local gfx="${MODSRC}/drivers/gpu/drm/amd/amdgpu/gfx_v10_0.c"
    if grep -q 'bc250_cc_write_mode' "$gfx"; then
        info "Source already patched."
        return 0
    fi
    info "Applying 40-CU patch..."
    cd "$MODSRC"
    curl -sL https://raw.githubusercontent.com/duggasco/bc250-40cu-unlock/main/patch/bc250-40cu-amdgpu.patch | patch -p1
}

build_module() {
    local amdgpu_dir="${MODSRC}/drivers/gpu/drm/amd/amdgpu"
    info "Configuring kernel configuration..."
    cp /boot/config-"${KVER}" "${MODSRC}/.config"
    make -C "${MODSRC}" oldconfig >/dev/null 2>&1 || true
    
    info "Preparing kernel source tree (this may take a moment)..."
    make -C "${MODSRC}" prepare modules_prepare
    cp "${MODDIR}/build/Module.symvers" "${MODSRC}/"
    
    info "Compiling amdgpu module with $(nproc) jobs..."
    make -C "${MODSRC}" M="$amdgpu_dir" clean
    make -C "${MODSRC}" M="$amdgpu_dir" -j"$(nproc)" modules
    
    local ko_path="${amdgpu_dir}/amdgpu.ko"
    [ -f "$ko_path" ] || die "Compilation failed: amdgpu.ko not generated."
    
    # Strictly output ONLY the file path to stdout for command substitution
    printf '%s\n' "$ko_path"
}

install_module() {
    local built="$1"
    local target="${MODPATH}.gz"
    [ -f "${MODPATH}" ] && target="${MODPATH}"

    if [ ! -f "${target}${BACKUP_SUFFIX}" ]; then
        info "Backing up original module..."
        cp "$target" "${target}${BACKUP_SUFFIX}"
    fi

    info "Compressing and installing module..."
    cd "${MODSRC}/drivers/gpu/drm/amd/amdgpu"
    gzip -9 -c amdgpu.ko > "$target"
    depmod -a "${KVER}"
    mkinitfs -o /boot/initramfs-"${KVER}" "${KVER}"
}

do_build() {
    check_deps
    check_bc250
    find_source
    patch_source
    local built
    built="$(build_module)"
    install_module "$built"
    info "Build complete! Run: doas $0 enable"
}

do_enable() {
    printf 'options amdgpu bc250_cc_write_mode=3\n' > "$CONF40"
    mkinitfs -o /boot/initramfs-"${KVER}" "${KVER}"
    info "40 CU mode enabled. Rebooting..."
    sleep 2
    reboot
}

do_disable() {
    rm -f "$CONF40"
    mkinitfs -o /boot/initramfs-"${KVER}" "${KVER}"
    info "40 CU mode disabled. Rebooting..."
    sleep 2
    reboot
}

do_restore() {
    local target="${MODPATH}.gz"
    [ -f "${MODPATH}" ] && target="${MODPATH}"
    local backup
    backup="$(ls -1 "${target}".bc250-backup-* 2>/dev/null | head -1)"
    [ -n "$backup" ] || die "No backup found"
    cp "$backup" "$target"
    rm -f "$CONF40"
    depmod -a "${KVER}"
    mkinitfs -o /boot/initramfs-"${KVER}" "${KVER}"
    info "Original module restored. Rebooting..."
    sleep 2
    reboot
}

do_status() {
    printf '\033[1m=== BC-250 Alpine CU Status ===\033[0m\n\n'
    if vulkaninfo --summary 2>/dev/null | grep -qi "${BC250_PCI_ID}"; then
        printf '  Vulkan device:  \033[0;32mBC-250 (ID 13fe) detected\033[0m\n'
    else
        printf '  Vulkan device:  \033[0;33mNot responding via vulkaninfo (headless)\033[0m\n'
    fi
    printf '  active CUs:     %s\n' "$(dmesg | grep 'active_cu_number' | tail -1 | grep -o 'active_cu_number [0-9]*' | awk '{print $2}')"
    printf '  write_mode:     %s\n' "$(cat /sys/module/amdgpu/parameters/bc250_cc_write_mode 2>/dev/null || echo 'N/A')"
}

case "${1:-}" in
    build)   do_build ;;
    enable)  do_enable ;;
    disable) do_disable ;;
    restore) do_restore ;;
    status)  do_status ;;
    *)
        echo "Usage: doas $0 {build|enable|disable|restore|status}"
        ;;
esac
