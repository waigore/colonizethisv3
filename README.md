# colonizethisv3
Colonization game developed using AI

## Running tools

CLI tools under `tool/` are run from the **project root** via Melos. One-time setup: install Melos (`dart pub global activate melos`) and bootstrap the workspace (`dart run melos bootstrap` or `melos bootstrap`). Then run any tool with:

```bash
melos run <tool_name> -- [args]
```

File paths in args are relative to the repo root. List available tools with `melos run` (no arguments). See **[Project tools](docs/project-tools.md)** for the list of available tools and how to invoke each.
