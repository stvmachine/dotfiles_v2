---
name: commit
description: Commit Skill with conventional commits and gitmoji support
allowed-tools: Bash(git *), Bash(curl *)
---

# Commit Skill

Create git commits following Conventional Commits specification with gitmoji.

## Format

```
<gitmoji> <type>(<scope>): <subject>

[optional body]

[optional footer(s)]
```

## Gitmoji Reference

| Emoji | Code | Type | Description |
|-------|------|------|-------------|
| ✨ | `:sparkles:` | feat | New feature |
| 🐛 | `:bug:` | fix | Bug fix |
| 📝 | `:memo:` | docs | Documentation |
| 💄 | `:lipstick:` | style | UI/style changes |
| ♻️ | `:recycle:` | refactor | Code refactoring |
| ⚡️ | `:zap:` | perf | Performance improvement |
| ✅ | `:white_check_mark:` | test | Tests |
| 🔧 | `:wrench:` | chore | Configuration/tooling |
| 🏗️ | `:building_construction:` | build | Build system changes |
| 👷 | `:construction_worker:` | ci | CI configuration |
| 🔥 | `:fire:` | remove | Remove code/files |
| 🚀 | `:rocket:` | deploy | Deployment |
| 🔒 | `:lock:` | security | Security fix |
| ⬆️ | `:arrow_up:` | deps | Upgrade dependencies |
| ⬇️ | `:arrow_down:` | deps | Downgrade dependencies |
| 🎨 | `:art:` | style | Improve structure/format |
| 💚 | `:green_heart:` | ci | Fix CI build |
| 📦 | `:package:` | build | Update compiled files |
| 🚧 | `:construction:` | wip | Work in progress |
| 🔀 | `:twisted_rightwards_arrows:` | merge | Merge branches |
| ⏪ | `:rewind:` | revert | Revert changes |
| 🏷️ | `:label:` | types | Types (TypeScript) |
| 🩹 | `:adhesive_bandage:` | fix | Simple fix for non-critical issue |
| 🧪 | `:test_tube:` | test | Add failing test |
| 💡 | `:bulb:` | docs | Add comments in code |
| 🍱 | `:bento:` | assets | Add/update assets |
| ♿️ | `:wheelchair:` | a11y | Accessibility |
| 📱 | `:iphone:` | responsive | Responsive design |
| 🗃️ | `:card_file_box:` | db | Database changes |
| 🔊 | `:loud_sound:` | logs | Add logs |
| 🔇 | `:mute:` | logs | Remove logs |

## Examples

```bash
# New feature
✨ feat(auth): add login with Google OAuth

# Bug fix with scope
🐛 fix(api): resolve null pointer in user service

# Test updates
✅ test: update TaskCardBody gap assertion and colors snapshot

# Documentation
📝 docs(readme): add installation instructions

# Refactoring
♻️ refactor(utils): simplify date formatting logic

# Performance
⚡️ perf(queries): optimize database queries with indexing

# Dependencies
⬆️ deps: upgrade react-native to 0.73

# Breaking change (add ! after type)
✨ feat(api)!: change authentication flow

BREAKING CHANGE: API now requires Bearer token
```

## Workflow

1. Stage changes with `git add`
2. Use `git status` and `git diff` to generate the commit message description:
   ```bash
   STATUS=$(git status --short)
   DIFF=$(git diff --cached)
   curl -s http://localhost:11434/api/chat -d "{
     \"model\": \"$(curl -s http://localhost:11434/api/tags | jq -r '.models[0].name')\",
     \"messages\": [{\"role\": \"user\", \"content\": \"You are a commit message writer. Given this git status and diff, write a conventional commit message following this format:\\n\\n<gitmoji> <type>(<scope>): <subject>\\n\\n<body>\\n\\nUse gitmoji, keep the subject under 72 chars, imperative mood. Body should be 2-4 concise bullet points. Types: feat, fix, refactor, style, docs, test, chore, perf. Only output the commit message, nothing else.\\n\\nGit status:\\n$STATUS\\n\\nGit diff:\\n$DIFF\"}],
     \"stream\": false
   }" | jq -r '.message.content'
   ```
3. Review output, adjust if needed, and commit.
