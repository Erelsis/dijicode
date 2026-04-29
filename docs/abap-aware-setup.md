## ABAP-Aware Dijicode Setup

This fork is ABAP-aware through a pinned extension pack defined in [product.json](/var/www/dijicode/product.json).
The local launch and maintenance scripts read that single source of truth and keep
this Dijicode build aligned with the expected ABAP extension versions.

### Pinned Extension Pack

The fork currently pins these Marketplace extensions:

- `larshp.vscode-abap@0.5.10`
- `hudakf.cds@0.7.2`
- `murbani.winregistry@0.0.1`
- `murbani.vscode-abap-remote-fs@2.4.3`

These match the runtime dependencies expected by ABAP FS while avoiding the cost
and maintenance burden of vendoring the entire upstream extension source tree into
`extensions/`.

### Manual Install And Repair

Run either:

```bash
bash ./scripts/install-abap-aware-extensions.sh
```

or the workspace task:

- `Install ABAP-Aware Extensions`

This installs the exact pinned versions, not simply the latest Marketplace versions.

### Manual Verification

Run either:

```bash
bash ./scripts/verify-abap-aware-extensions.sh
```

or the workspace task:

- `Verify ABAP-Aware Extensions`

This checks the currently installed extensions against the pinned versions in
[product.json](/var/www/dijicode/product.json) and exits non-zero if something is
missing or drifted.

### Automatic Bootstrap On Launch

When Dijicode is started via [scripts/code.sh](/var/www/dijicode/scripts/code.sh), the launch script now
runs the verifier in `--fix --quiet` mode before opening the window.

That gives you an automatic first-launch validation path for the fork:

1. Build or update Dijicode as usual.
2. Start it with `./scripts/code.sh` or the `Run Dev` task.
3. The launcher reconciles the ABAP pack to the pinned versions.
4. The window opens with the ABAP runtime prerequisites already in place.

If you need to skip this bootstrap temporarily, start with:

```bash
DIJICODE_SKIP_ABAP_AWARE_BOOTSTRAP=1 ./scripts/code.sh
```

### Fork Onboarding

After the extension pack is present:

1. Launch Dijicode with `./scripts/code.sh` or the `Run Dev` task.
2. Confirm the `ABAP FS` activity bar container appears.
3. Open the Command Palette and run `ABAP FS: Connection Manager`.
4. Add your SAP system details and save them to user or workspace settings.
5. Run `ABAP FS: Connect to an SAP system` and authenticate.
6. Verify core surfaces: Transports, Dumps, ATC Finds, Traces, and abapGit.
7. Open Copilot and, if needed, enable `abapfs.subagents.enabled` for ABAP-oriented agent flows.

### Scope And Limits

This implementation pins and bootstraps the ABAP extension set for the fork and
makes launch-time validation automatic.

It does not register ABAP FS under VS Code's built-in extension download pipeline
in `builtInExtensions`, because that path requires Marketplace or GitHub asset
checksums and metadata that are not currently available in this environment.
