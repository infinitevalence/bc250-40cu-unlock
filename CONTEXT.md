 Here's the diagnosis:

 Root cause #1 — pnum extraction is wrong:
 - basename "$patchfile" .patch on 12-unlock-all-40-compute-units.patch gives 12-unlock-all-40-compute-units, NOT 12
 - case "12-unlock-all-40-compute-units" in 12|19|21) → no match
 - Patch 12 IS being applied (user-only option), and patch 16's context conflicts with it

 Root cause #2 — Patch 16 context mismatch:
 - Patch 16 modifies gfx_v10_0.c around line 10117 with specific context lines
 - The remote Alpine kernel (6.18.49) likely has a different kernel source version than what the patches expect
 - Both patches 12 and 16 modify gfx_v10_0.c — if patch 12 applied first, patch 16's context lines won't match

 The fix: Extract just the leading numeric digits from filenames (e.g., 12 from 12-unlock-all-40-compute-units.patch) so the skip case works, and surface patch failure details.
