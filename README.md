# AI Dev Container Template

This development container is configured to work with local LLMs (Large Language Models) via LM Studio, supporting both **Claude Code** and **Open Code** AI assistants

## Overview

This template provides two ways to interact with your local LLM:

- **Claude Code**: Uses the Anthropic API-compatible endpoint from LM Studio
- **Open Code**: A VS Code extension that connects directly to LM Studio using its configuration

## Prerequisites

- **Docker Desktop** with Dev Containers support (Note: This template does not currently work with Podman due to a devcontainers images issue - see [devcontainers/images#1556](https://github.com/devcontainers/images/issues/1556))
- LM Studio installed on your host machine

## Getting Started with LM Studio

### 1. Download and Install LM Studio

1. Visit [https://lmstudio.ai](https://lmstudio.ai)
2. Download the latest version for your operating system
3. Install and launch LM Studio

### 2. Download a Model

1. Use the search bar in LM Studio to find a model (e.g., qwen3.5, Mistral, Phi)
2. Click the download button on a model you'd like to use
3. Wait for the download to complete

### 3. Start the Local Server

1. Go to the server icon (left sidebar)
2. Under "Load a model", select your downloaded model
3. Click "Start Server"
4. Note the server address (default: `http://localhost:1234`)

### 4. Configure the Dev Container

The dev container is pre-configured with the following environment variables:

- `ANTHROPIC_BASE_URL`: The LM Studio server URL
- `ANTHROPIC_AUTH_TOKEN`: Authentication token (default: `lmstudio`)
- `ANTHROPIC_MODEL`: Model identifier (default: `default_model`)

To update the IP address to match your LM Studio setup:

1. Open `.devcontainer/devcontainer.json`
2. Modify the `ANTHROPIC_BASE_URL` value:
   - For local network access (e.g., `YOUR_IP_ADDRESS:1234`)
   - For direct localhost with network sharing (using `--network=host`)

## Usage

Once the dev container is running, you can interact with your local LLM through the Anthropic API-compatible endpoint.

### Environment Variables

The container sets these environment variables automatically:

```
ANTHROPIC_BASE_URL=http://YOUR_IP_ADDRESS:1234
ANTHROPIC_AUTH_TOKEN=lmstudio
ANTHROPIC_MODEL=default_model
```

### Network Configuration

The container uses `--network=host` to allow access to LM Studio running on `localhost`. This works on Linux and allows the container to reach the local server.

## Using Open Code

Open Code is a VS Code extension that provides AI assistance directly in your editor. It reads its configuration from `opencode.json`.

### Configuration

The `opencode.json` file configures Open Code to connect to your LM Studio instance:

```json
{
  "provider": {
    "lmstudio": {
      "name": "LM Studio",
      "api": "openai",
      "options": {
        "baseURL": "http://YOUR_IP_ADDRESS:1234/v1"
      },
      "models": {
        "default_model": {
          "name": "LmStudio"
        }
      }
    }
  },
  "model": "default_model",
  "mcp": {
    "chrome-devtools": {
      "type": "local",
      "command": ["npx", "-y", "chrome-devtools-mcp@latest", "--headless", "--chromeArg", "--no-sandbox"]
    }
  }
}
```

### Updating Open Code Settings

To update the connection settings:

1. Open `opencode.json`
2. Modify the `baseURL` value to match your LM Studio server:
   - Replace `YOUR_IP_ADDRESS` with your machine's IP address
   - The port `1234` is the default for LM Studio
   - The `/v1` path is required for OpenAI-compatible API

### MCP Servers

Open Code supports Model Context Protocol (MCP) servers for extended functionality. This template includes:

- **Chrome DevTools MCP**: Provides tools for browser automation and inspection
  - Runs headless with `--no-sandbox` for containerized environments

## Using Claude Code

## Troubleshooting

### Connection Issues

- Ensure LM Studio server is running before starting the dev container
- Verify the IP address matches your machine on the network
- Check firewall settings allow connections on port 1234

### Model Loading Errors

- Ensure the model is fully downloaded in LM Studio
- Try reloading the model in LM Studio
- Check the LM Studio server logs for errors

## Setup Instructions

To use this template in your own project:

1. **Copy the following files/folders** to your project root:
   - `.devcontainer/` folder
   - `.mcp.json`
   - `opencode.json`
   - `forge.yaml`

2. **Choose a devContainer base image** from the official [devcontainers/images repository](https://github.com/devcontainers/images/tree/main/src) that fits your project needs.

3. **Add devcontainer features** as needed from the [devcontainers/features repository](https://github.com/devcontainers/features/tree/main/src).

4. **Update the IP address** in `.devcontainer/devcontainer.json` and `opencode.json` to match your machine's IP address (replace `YOUR_IP_ADDRESS` with your actual IP).

5. **Start the dev container** - you're ready to go!

## Extensions

The dev container includes these VS Code extensions:
- ESLint
- Prettier
- TypeScript Next
