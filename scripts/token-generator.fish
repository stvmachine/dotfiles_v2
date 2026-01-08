#!/usr/bin/env fish
# Token Generator Script
# Generates various types of tokens and keys

function generate-uuid
    echo "Generating UUID..."
    if command -q uuidgen
        uuidgen | tr '[:upper:]' '[:lower:]'
    else
        # Fallback using openssl if uuidgen not available
        openssl rand -hex 16 | sed 's/\(........\)\(....\)\(....\)\(....\)\(............\)/\1-\2-\3-\4-\5/'
    end
end

function generate-api-key -a length
    set -l len $length
    if test -z "$len"
        set len 32
    end
    echo "Generating API key (length: $len)..."
    openssl rand -hex $len
end

function generate-jwt-secret
    echo "Generating JWT secret..."
    openssl rand -base64 32
end

function generate-password -a length
    set -l len $length
    if test -z "$len"
        set len 16
    end
    echo "Generating password (length: $len)..."
    openssl rand -base64 $len | tr -d "=+/" | cut -c1-$len
end

function show-help
    echo "Token Generator Script"
    echo ""
    echo "Usage: token-generator [command] [options]"
    echo ""
    echo "Commands:"
    echo "  uuid              Generate a UUID"
    echo "  api-key [length]  Generate an API key (default length: 32)"
    echo "  jwt-secret        Generate a JWT secret"
    echo "  password [length] Generate a password (default length: 16)"
    echo "  help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  token-generator uuid"
    echo "  token-generator api-key 64"
    echo "  token-generator jwt-secret"
    echo "  token-generator password 20"
end

# Main script logic
switch $argv[1]
    case uuid
        generate-uuid
    case api-key
        generate-api-key $argv[2]
    case jwt-secret
        generate-jwt-secret
    case password
        generate-password $argv[2]
    case help -h --help ""
        show-help
    case "*"
        echo "Unknown command: $argv[1]"
        echo ""
        show-help
        exit 1
end
