---
name: serena
description: Serena MCP usage guide for semantic code operations, symbol manipulation, project memory, and session persistence. Use when invoking any mcp__serena__* tools, performing symbol operations (rename, find references, extract), navigating large codebases, or managing project memory/sessions.
---

# Serena MCP Server

Semantic code understanding with project memory and session persistence.

## Required First Step

**ALWAYS activate project before any Serena operation:**

```
mcp__serena__activate_project(project: "<path_or_name>")
mcp__serena__check_onboarding_performed()
```

## When to Use Serena

| Use Case | Serena | Alternative |
|----------|--------|-------------|
| Symbol rename with references | ✅ | ❌ Morphllm |
| Find all references | ✅ | ❌ Grep |
| Semantic code navigation | ✅ | ❌ Native |
| Project memory/session | ✅ | ❌ None |
| Pattern-based bulk edits | ❌ | ✅ Morphllm |
| Simple text replacement | ❌ | ✅ Edit tool |

## Core Tools

### Project Lifecycle
- `activate_project` → **REQUIRED FIRST** - activate target project
- `get_current_config` → check active project and available tools
- `check_onboarding_performed` → verify project is ready
- `onboarding` → run if onboarding not yet performed

### Symbol Operations
- `find_symbol` → locate symbols by name path pattern
- `find_referencing_symbols` → find all references to a symbol
- `get_symbols_overview` → high-level view of file symbols
- `rename_symbol` → rename across entire codebase
- `replace_symbol_body` → replace symbol definition
- `insert_before_symbol` / `insert_after_symbol` → add code around symbols

### Search & Navigation
- `search_for_pattern` → regex search across codebase
- `list_dir` → list directory contents
- `find_file` → find files by mask

### Memory Management
- `write_memory` → persist information for future sessions
- `read_memory` → retrieve stored information
- `list_memories` → show available memories
- `edit_memory` / `delete_memory` → modify or remove memories

### Reflection (Call These!)
- `think_about_collected_information` → after search operations
- `think_about_task_adherence` → before code modifications
- `think_about_whether_you_are_done` → at task completion

## Tool Details

See [references/tools.md](references/tools.md) for detailed parameter documentation.

## Workflow Patterns

### Session Start
```
1. activate_project(project: "path/to/project")
2. check_onboarding_performed()
3. list_memories() → check existing context
4. read_memory("relevant_memory") → if applicable
```

### Symbol Investigation
```
1. get_symbols_overview(relative_path: "file.py", depth: 1)
2. find_symbol(name_path_pattern: "ClassName", include_body: false)
3. find_symbol(name_path_pattern: "ClassName/method", include_body: true)
4. think_about_collected_information()
```

### Symbol Modification
```
1. find_symbol(name_path_pattern: "target", include_body: true)
2. think_about_task_adherence()
3. replace_symbol_body(name_path: "target", relative_path: "file.py", body: "new code")
```

### Cross-Session Persistence
```
1. write_memory("task_context", "important findings...")
2. [end session]
3. [new session]
4. activate_project(...)
5. list_memories()
6. read_memory("task_context")
```

## Name Path Patterns

| Pattern | Matches |
|---------|---------|
| `method` | Any symbol named "method" |
| `Class/method` | method inside Class |
| `/Class/method` | Exact path from file root |
| `Foo/get` with `substring_matching: true` | `Foo/getValue`, `Foo/getData` |

## Best Practices

1. **Activate first** - Always `activate_project` before operations
2. **Read before edit** - Use `find_symbol` with `include_body: true` before modifications
3. **Use reflection tools** - Call `think_about_*` tools at appropriate points
4. **Prefer symbolic over text** - Use symbol tools over grep/edit when possible
5. **Persist important context** - Use memory for cross-session continuity
