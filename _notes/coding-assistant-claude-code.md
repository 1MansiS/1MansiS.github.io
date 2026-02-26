---
topic: llm
section: "Agents"
tag: Coding Assistants
title: "What is a Coding Assistant — Anthropic Claude Code in Action"
---

*Notes from Anthropic's Claude Code in Action course.*

**Source:** [Claude Code in Action — Anthropic SkillJar](https://anthropic.skilljar.com/claude-code-in-action/303241)

---

## What is a Coding Assistant?

A coding assistant is a **tool** — it does whatever the model instructs it to do (e.g. read a file, run a command, edit code). The language model is the brain; the assistant is the hands.

![Coding assistant architecture — task goes in, language model + tools iterate through gather context → formulate a plan → take an action](/assets/notes/coding-assistant/coding-assistant-img-1.png)

The assistant loop:
1. **Gather context** — read files, search code, understand the codebase
2. **Formulate a plan** — decide what steps are needed
3. **Take an action** — execute via tools, observe the result, iterate

> Most coding assistants use remotely hosted language models. Claude Code uses the Claude series of models hosted at Anthropic, AWS, or Google Cloud (configurable).

---

## How Tools Work

Models are given plain text instructions describing what each tool does — e.g. `ReadFile: main.go`. The model then decides which tool to call and when. Claude's models are particularly good at understanding tool descriptions and using them to complete tasks. The tool set is extensible — new tools can be added as needed.

---

## Tools Available in Claude Code

![Tools with Claude Code — full table of built-in tools and their purposes](/assets/notes/coding-assistant/coding-assistant-img-3.png)

| Tool | Purpose |
|---|---|
| Agent | Launch a subagent to handle a task |
| Bash | Run a shell command |
| Edit | Edit a file |
| Glob | Find files based on a pattern |
| Grep | Search the contents of a file |
| LS | List files and directories |
| MultiEdit | Make several edits at the same time |
| NotebookEdit | Write to a cell in a Jupyter notebook |
| NotebookRead | Read a cell |
| Read | Read a file |
| TodoRead | Read one of the created to-dos |
| TodoWrite | Update the list of to-dos |
| WebFetch | Fetch from a URL |
| WebSearch | Search the web |
| Write | Write to a file |
