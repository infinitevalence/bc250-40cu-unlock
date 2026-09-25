# AGENTS.md — Operating procedures for coding agents

## Project Overview

**BC-250 40 CU Unlock** — Re-enable all 40 Compute Units on the AMD BC-250 APU (gfx1013 / Cyan Skillfish / salvaged PS5 APU).

The BC-250 ships with 24 of 40 RDNA2 CUs active. This project patches the `amdgpu` kernel driver to unlock all 40 CUs by writing two hardware registers during driver init. No firmware modifications required.

### Key Facts

- **Target hardware**: AMD BC-250 APU (PCI ID `0x13fe`, gfx1013, RDNA2)
- **Stock**: 24 CUs active (WGP 0–2), 16 CUs fused/harvested (WGP 3–4)
- **Unlocked**: 40 CUs active — 1.61× compute throughput at sweet-spot 1500 MHz
- **Mechanism**: Dual-register write via kernel module parameter `bc250_cc_write_mode`
  - `CC_GC_SHADER_ARRAY_CONFIG` (enumeration mask): `0xfff80000` → `0xffe00000`
  - `SPI_PG_ENABLE_STATIC_WGP_MASK` (dispatch gate): `0x7` → `0x1f`
- **Both registers required** — CC alone changes driver reports but SPI still dispatches to 24; SPI alone enables hardware but driver only generates work for 24
- **Harvesting pattern**: Contiguous on tested boards — SE0/SE1 SH0/SH1 each have identical contiguous harvesting (■■■■■■□□□□)
- **License**: GPL-2.0 (same as Linux kernel)

### How It Works

The patch modifies `gfx_v10_0_get_cu_info()` in `amdgpu` driver to write both registers during GPU init, guarded by:
- PCI device ID `0x13fe` (BC-250 only)
- Module parameter `bc250_cc_write_mode=3` (off by default, safe)

### Use Cases

- **AI / LLM inference**: pp512 benchmark shows 230 → 372 tok/s (1.61×) at 1500 MHz, 95W → 125W, 79C → 83C
- **Gaming**: glmark2 graphics sees +4.4% (9430 → 9844), fill-rate bound not CU-bound
- **Compute**: Full Vulkan/HSA compute access with all 40 CUs available

### Current Focus

Primary script: **`scripts/bc250-enable-40cu-alpine.sh`** — builds and installs a patched `amdgpu` kernel module specifically for **Alpine Linux**. Other distro variants exist (Arch, Fedora, generic).

## File Tree

```
.
├── AGENTS.md
├── CONTEXT.md
├── ERROR.md
├── HANDOFF.md
├── README.md
├── bc250-alpine-6.18.53/
│  ├── 07-cac-weight-and-sendraw-debugfs.patch
│  └── 08-smu-cmn-send-raw-debugfs-definitions.patch
├── docs/
│  ├── technical-report.md
│  ├── whitepaper-cu-unlock.pdf
│  └── whitepaper-cu-unlock.tex
├── kernel-6.18.53-context/
│  ├── amdgpu_pm.h
│  ├── amdgpu_smu.h
│  ├── smu_cmn.c
│  ├── smu_cmn.h
│  └── smu_internal.h
├── patch/
│  ├── 01-declare-20-smu-message-enums.patch
│  ├── 02-map-23-pmfw-messages-raise-sclk-max.patch
│  ├── 03-gfx-clock-force-and-dpm-levels.patch
│  ├── 04-start-pmfw-telemetry-reporting.patch
│  ├── 05-raceless-direct-gfxclk-query.patch
│  ├── 06-read-cac-weight-baselines.patch
│  ├── 07-cac-weight-and-sendraw-debugfs.patch
│  ├── 08-smu-cmn-send-raw-debugfs-definitions.patch
│  ├── 09-cpu-cclk-soft-limits-debugfs.patch
│  ├── 10-print-full-32bit-cac-value.patch
│  ├── 11-full-telemetry-dump-debugfs.patch
│  ├── 12-unlock-all-40-compute-units.patch
│  ├── 13-gfxoff-disable-gfx1013.patch
│  ├── 14-gmc-kiq-bypass-dead-gpu.patch
│  ├── 15-amdgpu-gmc-kiq-bypass.patch
│  ├── 16-cu-unlock-cc-spi-safe-no-rlc.patch
│  ├── 17-bc250-gfx1013-fault-probe.patch
│  ├── 18-ttm-guard-null-pages-on-unpopulate.patch
│  ├── 19-bc250-kfd-skip-sdma0.patch
│  ├── 20-amdgpu-ttm-populate-null-guard.patch
│  ├── 21-amdgpu-gmc-flush-pasid-kiq.patch
│  ├── 22-amdgpu-ttm-fno-lto.patch
│  ├── 23-gb-addr-config-num-se.patch
│  ├── 24-gmc-v10-flush-all-vmids.patch
│  ├── 25-bc250-flush-tlb-by-runlist.patch
│  ├── 26-bc250-sdma-firmware-override.patch
│  ├── 27-bc250-early-sdma-trap.patch
│  ├── 28-bc250-8core-telemetry.patch
│  ├── 29-bc250-tmr-discovery-offset-fix.patch
│  ├── 30-cyan-skillfish2-hardcoded-fallback.patch
│  ├── ANALYSIS-gfx1013-compute-defect.md
│  ├── BC250-PRODUCTION-GUIDE.md
│  ├── NOTICE
│  └── SERIES.md
└── scripts/
  ├── bc250-40cu-benchmark.sh
  ├── bc250-compute-verify.sh
  ├── bc250-cu-health-test.sh
  ├── bc250-cu-mask.sh
  ├── bc250-enable-40cu-alpine.sh  ← primary focus
  ├── bc250-enable-40cu-arch.sh
  ├── bc250-enable-40cu-fedora.sh
  ├── bc250-enable-40cu.sh
  └── cu_map.sh
```

### Key Areas

| Area | Purpose |
|------|-----|
| **`patch/`** | 30 kernel patches for amdgpu driver + series descriptions |
| **`scripts/bc250-enable-40cu-alpine.sh`** | Main build/install script for Alpine Linux |
| **`scripts/bc250-cu-*`** | CU health testing, masking, verification scripts |
| **`docs/`** | Technical report, whitepaper PDF+LaTeX |
| **`bc250-alpine-6.18.53/`** | Patch set for Alpine Linux 6.18.53 kernel |
| **`kernel-6.18.53-context/`** | Kernel source context (amdgpu headers, smu_cmn) |
| **`scripts/bc250-enable-40cu-arch.sh`** | Arch Linux variant (PKGBUILD-based) |
| **`scripts/bc250-enable-40cu-fedora.sh`** | Fedora variant (DNF-based) |

## Git push to GitHub

### SSH (preferred)

```sh
# Use the system openssh agent socket, load the key, then push
SSH_AUTH_SOCK=/run/user/1000/openssh_agent ssh-add ~/.ssh/id_rsa

cd /home/infinitevalence/bc250-40cu-unlock
SSH_AUTH_SOCK=/run/user/1000/openssh_agent git push origin ALPINE
```

- **Branch:** `ALPINE`
- **Key:** `~/.ssh/id_rsa` (configured in `~/.ssh/config`)

> The passphrase is provided via SSH_ASKPASS when prompted. The system
> openssh-agent at `/run/user/1000/openssh_agent` must be used — a fresh
> `eval $(ssh-agent -s)` will create an orphaned agent whose socket the
> system won't resolve.
> 
> **Agent Execution Note:** For non-interactive agent runs where passphrase prompting blocks execution:
> 1. **Git Credential Store (Recommended):** Store PAT securely outside the repository:
>    ```sh
>    git config --global credential.helper store
>    echo "https://YOUR_PAT:x-oauth-basic@github.com" >> ~/.git-credentials
>    ```
>    Git authenticates automatically without exposing tokens in code or repo files.
> 2. **Dedicated Unencrypted Deploy Key:** Place a passphrase-free deploy key at `~/.ssh/id_ed25519_deploy` (outside repository tracking) and reference it in `~/.ssh/config`.
