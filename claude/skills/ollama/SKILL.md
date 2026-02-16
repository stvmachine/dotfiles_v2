---
name: ollama
description: Chat with local Ollama models. Use when the user wants to ask a question to a local LLM, run inference locally, or use /ollama.
allowed-tools: Bash(curl *)
---

# Ollama Skill

Communicate with a local Ollama instance running at `http://localhost:11434`.

## Usage

When invoked, send the user's prompt to Ollama using the chat API. If the user provides a specific model name, use that. Otherwise, list available models and pick the first one.

## Workflow

1. **Check available models** (if no model specified):
   ```bash
   curl -s http://localhost:11434/api/tags | jq -r '.models[].name'
   ```

2. **Send a chat completion request**:
   ```bash
   curl -s http://localhost:11434/api/chat -d '{
     "model": "<model_name>",
     "messages": [{"role": "user", "content": "<user_prompt>"}],
     "stream": false
   }'
   ```

3. **Extract and display the response** from the JSON output at `.message.content`.

4. If Ollama is not running, inform the user to start it with `ollama serve`.

## Streaming

For long responses, use streaming mode by omitting `"stream": false` and piping through `jq`:
```bash
curl -s http://localhost:11434/api/chat -d '{
  "model": "<model_name>",
  "messages": [{"role": "user", "content": "<user_prompt>"}],
  "stream": false
}' | jq -r '.message.content'
```

## Examples

- `/ollama What is the capital of France?` — Sends prompt to default model
- `/ollama model=codellama Explain this function` — Uses a specific model
- `/ollama list` — Lists available models
