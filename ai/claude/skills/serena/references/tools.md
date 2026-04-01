# Serena Tool Reference

## Table of Contents
- [Project Lifecycle](#project-lifecycle)
- [Symbol Operations](#symbol-operations)
- [Search & Navigation](#search--navigation)
- [Memory Management](#memory-management)
- [Reflection Tools](#reflection-tools)

---

## Project Lifecycle

### activate_project
Activate a project before any other operations.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| project | string | ✅ | Project name or path |

### get_current_config
Print current configuration including active/available projects, tools, contexts, modes.

*No parameters*

### check_onboarding_performed
Check if project onboarding was performed. Call after activating project.

*No parameters*

### onboarding
Run if onboarding not yet performed. Returns instructions for creating onboarding info.

*No parameters*

---

## Symbol Operations

### find_symbol
Find symbols by name path pattern.

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| name_path_pattern | string | ✅ | - | Pattern: `name`, `Class/method`, `/absolute/path` |
| relative_path | string | ❌ | "" | Restrict to file/directory |
| depth | int | ❌ | 0 | Retrieve descendants (1 = immediate children) |
| include_body | bool | ❌ | false | Include source code |
| substring_matching | bool | ❌ | false | Match partial names |
| include_kinds | int[] | ❌ | [] | LSP symbol kinds to include |
| exclude_kinds | int[] | ❌ | [] | LSP symbol kinds to exclude |
| max_answer_chars | int | ❌ | -1 | Max output chars (-1 = config default) |

**LSP Symbol Kinds**: 5=class, 6=method, 7=property, 8=field, 9=constructor, 12=function, 13=variable, 14=constant

### find_referencing_symbols
Find all references to a symbol.

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| name_path | string | ✅ | - | Symbol to find references for |
| relative_path | string | ✅ | - | File containing the symbol |
| include_kinds | int[] | ❌ | [] | Filter referencing symbol kinds |
| exclude_kinds | int[] | ❌ | [] | Exclude referencing symbol kinds |
| max_answer_chars | int | ❌ | -1 | Max output chars |

### get_symbols_overview
Get high-level view of symbols in a file. Use first when exploring new files.

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| relative_path | string | ✅ | - | File to analyze |
| depth | int | ❌ | 0 | Descendant depth (1 = methods of classes) |
| max_answer_chars | int | ❌ | -1 | Max output chars |

### rename_symbol
Rename symbol across entire codebase.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| name_path | string | ✅ | Symbol to rename |
| relative_path | string | ✅ | File containing symbol |
| new_name | string | ✅ | New name |

### replace_symbol_body
Replace entire symbol definition.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| name_path | string | ✅ | Symbol to replace |
| relative_path | string | ✅ | File containing symbol |
| body | string | ✅ | New body (includes signature, NOT docstrings/imports) |

### insert_before_symbol / insert_after_symbol
Insert code before/after a symbol.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| name_path | string | ✅ | Reference symbol |
| relative_path | string | ✅ | File containing symbol |
| body | string | ✅ | Content to insert |

---

## Search & Navigation

### search_for_pattern
Regex search across codebase. Prefer `find_symbol` for known symbols.

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| substring_pattern | string | ✅ | - | Regex pattern (DOTALL enabled) |
| relative_path | string | ❌ | "" | Restrict to path |
| restrict_search_to_code_files | bool | ❌ | false | Only search code files |
| paths_include_glob | string | ❌ | "" | Include glob (e.g., `*.py`) |
| paths_exclude_glob | string | ❌ | "" | Exclude glob (e.g., `*test*`) |
| context_lines_before | int | ❌ | 0 | Lines before match |
| context_lines_after | int | ❌ | 0 | Lines after match |
| max_answer_chars | int | ❌ | -1 | Max output chars |

### list_dir
List directory contents.

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| relative_path | string | ✅ | - | Directory to list ("." for root) |
| recursive | bool | ✅ | - | Scan subdirectories |
| skip_ignored_files | bool | ❌ | false | Skip gitignored files |
| max_answer_chars | int | ❌ | -1 | Max output chars |

### find_file
Find files by name/mask.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| file_mask | string | ✅ | Filename or mask (`*.py`, `config*`) |
| relative_path | string | ✅ | Directory to search ("." for root) |

---

## Memory Management

### write_memory
Persist information for future sessions.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| memory_file_name | string | ✅ | Memory identifier |
| content | string | ✅ | Content to store (markdown) |
| max_answer_chars | int | ❌ | Max output chars |

### read_memory
Retrieve stored memory. Don't read same memory twice in conversation.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| memory_file_name | string | ✅ | Memory to read |
| max_answer_chars | int | ❌ | Max output chars |

### list_memories
Show available memories.

*No parameters*

### edit_memory
Modify existing memory.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| memory_file_name | string | ✅ | Memory to edit |
| needle | string | ✅ | String/regex to find |
| repl | string | ✅ | Replacement string |
| mode | string | ✅ | "literal" or "regex" |

### delete_memory
Remove a memory. Only when user explicitly requests.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| memory_file_name | string | ✅ | Memory to delete |

---

## Reflection Tools

These tools help maintain quality. **Use them!**

### think_about_collected_information
Call after completing search operations (find_symbol, search_for_pattern, etc.)

*No parameters*

### think_about_task_adherence
Call before inserting, replacing, or deleting code.

*No parameters*

### think_about_whether_you_are_done
Call when you believe task is complete.

*No parameters*
