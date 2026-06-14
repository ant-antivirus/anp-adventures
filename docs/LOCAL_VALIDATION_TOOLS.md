# Local Validation Tools

Current required validation for the EP1 internal RC is:

- Rojo sourcemap validation for `default.project.json`.
- Rojo sourcemap validation for `ANPAdventures.project.json`.
- Luau parse validation when the local Luau tools are available.
- Studio smoke tests.
- Forbidden-system scan.
- `git diff --check`.

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
