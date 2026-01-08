# Scripts

This folder contains various scripts and utilities for development and system management.

## Docker Tools

### `docker/` - Docker utilities and functions

- `install.fish` - Installs Docker completion and sets up abbreviations (`d` for docker, `dc` for docker-compose)
- `functions/docker.fish` - Enhanced docker function that auto-starts Docker if needed
- `functions/docker-cp.fish` - Utility to pull, retag, and push Docker images

### Docker Function Usage

```fish
# Enhanced docker command (auto-starts Docker if needed)
docker run hello-world
docker prune  # Prune with auto-start

# Docker copy utility
docker-cp source-image:tag destination-image:tag
```

## Token Generator

### `token-generator.fish` - Generate various types of tokens and keys

A utility script for generating different types of tokens, keys, and secrets.

### Usage

```fish
# Generate a UUID
token-generator uuid

# Generate an API key (default 32 chars)
token-generator api-key
token-generator api-key 64  # Custom length

# Generate a JWT secret
token-generator jwt-secret

# Generate a password (default 16 chars)
token-generator password
token-generator password 20  # Custom length

# Show help
token-generator help
```

### Examples

```fish
$ token-generator uuid
f47ac10b-58cc-4372-a567-0e02b2c3d479

$ token-generator api-key
a1b2c3d4e5f678901234567890123456789012345678901234567890

$ token-generator jwt-secret
YWJjZGVmZ2hpams=

$ token-generator password
MySecureP@ssw0rd123
```
