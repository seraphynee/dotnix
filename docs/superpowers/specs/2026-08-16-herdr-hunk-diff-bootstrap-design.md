# Herdr Hunk Diff Bootstrap Design

## Goal

Install `jhochenbaum/herdr-hunk-diff` into Herdr's user-managed plugin
directory without building the plugin as a Nix package. Keep the desired plugin
revision reproducible and updateable through `flake.lock`.

## Chosen Approach

Keep `herdr-hunk-diff` as a non-flake input solely to pin its Git commit. Remove
the `buildNpmPackage` wrapper, generated npm lockfile patch, and package output.
Herdr remains responsible for cloning, building, registering, and storing the
plugin.

Extend the existing Herdr shell bootstrap to manage two plugin forms:

- Local plugin roots, which continue to use `herdr plugin link`.
- GitHub plugins, which use `herdr plugin install OWNER/REPO --ref REV --yes`.

The Home Manager module passes the locked revision from
`inputs.herdr-hunk-diff.rev` to the bootstrap. The revision is embedded into the
generated bootstrap application when the configuration is built.

## Bootstrap Behavior

The bootstrap runs only from a shell inside a Herdr session, as it does today.
It obtains the installed plugin registry once with
`herdr plugin list --json`.

For `jhochenbaum.hunkdiff`, it compares all of the following fields:

- Plugin ID: `jhochenbaum.hunkdiff`
- Source kind: `github`
- Source owner: `jhochenbaum`
- Source repository: `herdr-hunk-diff`
- Resolved commit: the revision pinned by the flake input

When all fields match, the bootstrap performs no installation or network
operation. When the plugin is absent or its resolved commit differs, the
bootstrap runs:

```sh
herdr plugin install jhochenbaum/herdr-hunk-diff \
  --ref LOCKED_REVISION \
  --yes
```

This lets Herdr replace an older managed checkout when the pin changes. Local
plugin linking remains unchanged.

## Update Workflow

Update the desired plugin revision with:

```sh
just up herdr-hunk-diff
just rb HOST
```

The direct equivalent of the first command is:

```sh
nix flake update herdr-hunk-diff
```

Updating `flake.lock` alone does not alter an already deployed bootstrap. The
configuration rebuild is required to embed the new revision. The next shell
opened inside Herdr detects the mismatch and asks Herdr to install that pinned
revision.

The pinned Herdr input must also provide Herdr 0.8.0 or newer because the plugin
declares that minimum version. The initial implementation will update the
`herdr` input before verifying installation.

## Failure Handling

Plugin inspection or installation failures must not prevent an interactive
shell from starting. The bootstrap prints a concise diagnostic and returns
success so a later Herdr shell can retry.

First-install concurrency must be serialized so multiple panes do not perform
the Git checkout and npm build simultaneously. A failed or interrupted attempt
must not permanently suppress later retries.

The bootstrap will not automatically configure the plugin's optional
keybindings. Herdr's main config is managed by Home Manager, so keybindings
belong in the repository if requested separately.

## Testing

Extend the existing bootstrap shell test with mocked Herdr responses covering:

- An absent GitHub plugin is installed with the locked revision and `--yes`.
- A matching installed revision is skipped.
- A mismatched installed revision is reinstalled.
- Local plugin roots retain their existing link and skip behavior.
- Registry inspection and remote installation failures remain non-fatal.
- Calls outside a Herdr session remain silent no-ops.
- Concurrent initialization does not launch duplicate remote installations.

Run the focused shell test, formatting checks, and relevant flake evaluation or
checks after implementation.

## Out of Scope

- Building or caching the plugin's npm dependencies with Nix.
- Managing plugin files directly in the Nix store.
- Automatically tracking an unpinned default branch.
- Automatically installing the plugin's optional keybindings.
