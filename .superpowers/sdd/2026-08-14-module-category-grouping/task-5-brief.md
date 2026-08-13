### Task 5: Consolidate network service aspects

**Files:**

- Create: `modules/services/networking.nix`
- Retain unchanged: `modules/services/kanata.nix`
- Delete: `modules/services/cloudflare-warp.nix`
- Delete: `modules/services/tailscale.nix`

**Interfaces:**

- Consumes: independent Cloudflare WARP and Tailscale aspects.
- Produces: one network-service category file plus the unchanged Kanata file.

- [ ] **Step 1: Verify the service layout is initially red**

Run:

```bash
test -f modules/services/networking.nix \
  && test "$(find modules/services -maxdepth 1 -name '*.nix' | wc -l)" -eq 2
```

Expected: FAIL.

- [ ] **Step 2: Build service `networking.nix`**

Use `apply_patch` to create a static attrset containing the complete `den.aspects.services._."cloudflare-warp".nixos` assignment followed by the complete `den.aspects.services._.tailscale.nixos` assignment. Add `# Cloudflare WARP` and `# Tailscale` comments. Delete `cloudflare-warp.nix` and `tailscale.nix`.

- [ ] **Step 3: Format and verify service structure**

Run:

```bash
nix fmt
test "$(find modules/services -maxdepth 1 -name '*.nix' | wc -l)" -eq 2
test -f modules/services/networking.nix
test -f modules/services/kanata.nix
rg --no-filename -o 'den\.aspects\.[A-Za-z0-9_".-]+(\._\.[A-Za-z0-9_".-]+)*' modules -g '*.nix' | sort -u | sha256sum
```

Expected: two service files and declaration checksum `724b9ab5d5da0deed8616fa5ffc9b4690feac39957433cfe3e860ecc69bf900a`.

- [ ] **Step 4: Evaluate a host using both network services**

Run:

```bash
nix eval 'path:.#nixosConfigurations.acerus.config.system.build.toplevel.drvPath' --raw
```

Expected: PASS, or the same Nix-daemon access failure recorded in Task 1.

- [ ] **Step 5: Create the local service checkpoint**

Run:

```bash
jj diff --stat
jj commit -m "refactor(services): group network modules"
```

Expected: a local service-grouping commit, or the already-recorded read-only object-store limitation without a Git fallback.

---

