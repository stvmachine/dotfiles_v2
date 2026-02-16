---
name: storybook
description: Interact with the Storybook MCP server to discover components, get documentation, retrieve story URLs, and follow UI development conventions. Use when developing UI components, creating stories, verifying rendered output, or when the user asks about available components in the design system.
allowed-tools: WebFetch, Read, Grep, Glob, Write, Edit, Bash
---

# Storybook MCP Integration

This project has `@storybook/addon-mcp` installed, which runs an MCP server alongside the Storybook dev server.

## MCP Server

When Storybook is running, the MCP server is available at:

```
http://localhost:6006/mcp
```

Start Storybook from the repo root:

```bash
pnpm --filter @medtasker/storybook dev
```

## Available MCP Tools

The Storybook MCP server provides these tools:

1. **UI Development Instructions** — Get standardized instructions for creating/modifying components following project conventions and writing stories.

2. **Story URL Retrieval** — Get direct URLs to specific stories for visual verification in the browser.

3. **Component Documentation** — List all available UI components and retrieve detailed docs for specific components by ID. Prefer this over reading raw source files to reduce token usage.

## Workflow for UI Development

1. **Before creating a component**, use the MCP server to:
   - Get UI development instructions for the project
   - List existing components to check for reusable pieces
   - Get docs for similar components to follow patterns

2. **After creating a component and its stories**, use the MCP server to:
   - Retrieve the story URL for visual verification
   - Run the autonomous correction loop (interaction + accessibility tests)

3. **When fixing UI bugs**, use the MCP server to:
   - Get the story URL to see the current rendered state
   - Get component docs to understand the API

## Storybook Location

- Config: `apps/storybook/.storybook/main.ts`
- Stories: `apps/storybook/stories/`
- Package: `apps/storybook/package.json`

## Story Conventions

- Stories live in `apps/storybook/stories/` organized by domain (e.g. `ui/`, `navigation/`, `login/`)
- Import types from `@storybook/react-webpack5` (Storybook v9)
- Import test utilities from `storybook/test` (not `@storybook/test`)
- Components come from `@medtasker/ui/src`

## Requirements

- Node.js 24+ (see `.nvmrc`)
- Storybook 9.1.16+
