---
topic: llm
section: "Protocols"
tag: MCP
title: "Model Context Protocol (MCP)"
---

*Notes from the [Large Language Model (LLM) Talk](https://podcasts.apple.com/us/podcast/large-language-model-llm-talk/id1790576136?i=1000702820070) podcast — listened April 17, 2025.*

---

## The Problem

Powerful AI models exist, but connecting them to real-world data kept feeling like a brand-new integration project every single time. If you had **M** LLMs and **N** tools, you potentially needed **M × N** custom connectors — each built from scratch, every time.

---

## What Is MCP?

**Model Context Protocol** is an open protocol introduced by Anthropic in November 2024. It creates a standardized way for applications to give LLMs context — a universal adapter so you never have to reinvent the wheel when connecting a new tool.

A few analogies:
- **USB** — one port standard, endless device support
- **LSP** (Language Server Protocol) — one protocol, any editor + any language

---

## How It Works

At its core, MCP uses a **client-server architecture** with three key players:

| Player | What It Is |
|---|---|
| **MCP Host** | The AI app the user interacts with (e.g. Claude Desktop, a code editor plugin). Can connect to multiple MCP servers simultaneously. |
| **MCP Client** | Middleware that lives inside the Host. One client per server — keeps connections isolated so one failure doesn't cascade. |
| **MCP Server** | A lightweight program outside the Host that exposes specific services, data, or tools via the MCP protocol. Can reach local files or remote APIs. |

---

## Primitives — The Building Blocks

### Client-Side Primitives

**Roots**
- Sets boundaries: which parts of the host system can the server access?
- The host tells the server: *"You can only look in here"* — prevents servers from wandering.

**Sampling**
- Reverses the usual client/server dynamic: the *server* can ask the *client* to generate text.
- Useful because servers typically don't have direct LLM access — but clients do.
- The client stays in full control: it picks the model, can rate-limit, or reject suspicious requests.

---

### Server-Side Primitives

| Primitive | Controlled By | Purpose |
|---|---|---|
| **Tools** | Model | Executable functions the LLM can call — *giving the model hands*. Real-time data, DB writes, triggering processes. |
| **Resources** | Application (Host) | Information for the LLM to work with — documents, tables, structured data. |
| **Prompts** | User | Pre-built templates for common tasks. User selects when to apply them. |

> **Tools are for taking actions. Resources are for providing information.**

---

## Under the Hood

MCP uses **JSON-RPC 2.0** for all client-server communication — a lightweight, well-understood RPC format.

---

## Why It Matters

- **Ecosystem** — a growing library of ready-made MCP servers means your AI tools can do more without writing custom glue code for every tool.
- **Portability** — switch LLMs without rewriting your tools.
- **Agent-ready** — MCP gives agents a consistent way to discover and use tools, enabling more sophisticated multi-step reasoning across systems.
- **Scalability** — build AI systems that are more powerful, secure, and robust by composing MCP servers rather than hardcoding integrations.

---

## Summary

> *"MCP is like a universal adapter for AI. It uses a client-server architecture with hosts, clients, and servers all working together seamlessly. It defines primitives like tools for action, resources for information, and prompts for structured interactions. On the client side, roots enforce security and sampling gives precise control over LLM text generation. All of this is designed to solve the dreaded M×N integration problem and create a more flexible, secure, and powerful AI ecosystem."*
