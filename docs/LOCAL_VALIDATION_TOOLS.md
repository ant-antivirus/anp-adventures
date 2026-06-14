# Local Validation Tools

Current required validation for the EP1 internal RC is:

- Rojo sourcemap validation for `default.project.json`.
- Rojo sourcemap validation for `ANPAdventures.project.json`.
- Luau parse validation when the local Luau tools are available.
- Studio smoke tests.
- Forbidden-system scan.
- `git diff --check`.

Normal Mock-mode Studio runs should show:

```text
[ANP StartupHealth] SmokeTests: true
[ANP StartupHealth] SmokeTestGate: Enabled
```

During a temporary Studio DataStore pilot, `SmokeTestConfig` skips normal smoke tests
when real DataStore is enabled:

```text
[ANP StartupHealth] SmokeTests: false
[ANP StartupHealth] SmokeTestGate: RealDataStoreEnabled
[ANP SmokeTests] Skipped reason=RealDataStoreEnabled
```

Revert `PersistenceConfig` to Mock mode before committing so smoke tests run again.

This workspace has Luau tools at:

```text
D:\ATOM\Luau\
```

Use:

```text
D:\ATOM\Luau\luau-compile.exe --only-parse <file>
```

Optional future local tooling:

- `luau`
- `selene`
- `stylua`
- `lune`

These optional tools are useful, but they are not required to mark the current EP1 RC if Rojo validation and Studio smoke tests pass.
