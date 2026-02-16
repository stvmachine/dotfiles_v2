---
name: figma
description: Fetch designs from Figma, generate React/React Native code, and sync design tokens. Use when the user shares a Figma URL, asks to implement a design, or wants to extract design tokens.
argument-hint: [figma-url]
allowed-tools: mcp__figma__*,mcp__figma-desktop__*, Read, Grep, Glob, Write, Edit
---

## Figma MCP Rules

- IMPORTANT: If the Figma MCP server returns a localhost source for an image or an SVG, use that image or SVG source directly
- IMPORTANT: DO NOT import/add new icon packages, all the assets should be in the Figma payload
- IMPORTANT: do NOT use or create placeholders if a localhost source is provided
- 
# Figma Design Integration

Fetch designs from Figma, generate code, and sync design tokens using the Figma MCP server.

## Getting Started

Parse the Figma URL from: `$ARGUMENTS`

A Figma URL typically looks like:

- `https://www.figma.com/file/{file_key}/{file_name}?node-id={node_id}`
- `https://www.figma.com/design/{file_key}/{file_name}?node-id={node_id}`

Extract the `file_key` and `node_id` from the URL.

## Fetching Design Data

Use the Figma MCP tools to fetch design data:

- `mcp__figma__get_file` - Get full file data
- `mcp__figma__get_file_nodes` - Get specific nodes from a file
- `mcp__figma__get_images` - Export images/SVGs from nodes
- `mcp__figma__get_styles` - Get styles from a file
- `mcp__figma__get_components` - Get components from a file

## Analysis Steps

1. **Identify the component type** - Button, card, form, layout, etc.
2. **Extract visual properties**:
   - Colors (fill, stroke, text)
   - Typography (font family, size, weight, line height)
   - Spacing (padding, margin, gaps)
   - Border radius
   - Shadows/effects
3. **Identify variants** - States like hover, active, disabled
4. **Check for existing components** - Look in `packages/ui/src` for similar components

## Code Generation Guidelines

When generating React/React Native code:

1. **Use existing design tokens** from the project:
   - Check `packages/ui/src` for theme/token files
   - Use NativeWind/Tailwind classes where applicable

2. **Follow project conventions**:
   - Use TypeScript
   - Use functional components with hooks
   - Export types for props
   - Follow existing component structure in `packages/ui/src`

3. **Component structure**:

```tsx
import { View, Text, Pressable } from 'react-native';

interface ComponentNameProps {
  // Props based on Figma variants
}

export function ComponentName({ ...props }: ComponentNameProps) {
  return (
    // Implementation
  );
}
```

## Design Token Sync

When syncing design tokens:

1. **Extract tokens from Figma**:
   - Colors (primitives and semantic)
   - Typography scales
   - Spacing scales
   - Border radius values
   - Shadow definitions

2. **Update token files** in the project:
   - Look for existing token files in `packages/ui/src`
   - Match the existing format and structure
   - Add new tokens without breaking existing ones

## Workflow

1. Use Figma MCP tools to fetch the design data
2. Analyze the design and extract specifications
3. Ask the user what they want to do:
   - **View specs**: Display the extracted design specifications
   - **Generate component**: Create React/React Native code
   - **Sync tokens**: Update design tokens in the codebase
4. Execute the chosen action
5. If generating code, suggest where to place the new component

## Error Handling

- If no Figma URL is provided, ask the user to provide one
- If the MCP tool fails, verify the Figma server is connected and authenticated
- If the node doesn't exist, suggest checking the Figma URL
