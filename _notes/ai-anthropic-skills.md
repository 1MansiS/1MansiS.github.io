---
topic: llm
section: "Skills"
tag: Skills
title: "Agent Skills with Anthropic"
source: "https://learn.deeplearning.ai/courses/agent-skills-with-anthropic"
speaker: "Anthropic"
---

*Notes from the [Agent Skills with Anthropic](https://learn.deeplearning.ai/courses/agent-skills-with-anthropic) course on DeepLearning.AI.*

---

## What Is a Skill?

A **skill** is a folder of organized instructions that gives an agent a new, specialized capability — without hardcoding that behavior into the agent itself. Skills are an **open standard**, meaning any skills-compatible agent (not just Claude) can use them.

Think of a skill as a reusable playbook: you describe the workflow once, package it, and the agent knows how to run it whenever it's needed.

**A skill includes:**
- A `SKILL.md` file — the entry point with the skill's name, description, and main instructions
- Optional supporting files — scripts, additional markdown, templates, images, data — all referenced from `SKILL.md`

---

## Skill Anatomy

### Directory Structure

```
my-skill/
├── SKILL.md          ← required entry point
└── references/
    ├── instructions.md
    ├── analysis.py
    └── template.csv
```

### SKILL.md Format

The file opens with a YAML-like header that defines the skill's identity, followed by the full instructions:

```markdown
---
name: Weekly Marketing Analysis
description: Analyzes weekly campaign data and produces a performance summary report.
---

## Instructions

1. Load the provided CSV file from the user
2. Run `references/analysis.py` on the data
3. Fill in `references/template.csv` with results
4. Summarize key metrics and trends in a brief report
```

> Only the `name` and `description` are loaded at session start. The full instructions load only when the skill is triggered — this is **progressive disclosure**.

- Agent Skill specification: https://agentskills.io/specification
---

## Progressive Disclosure

Skills are designed to protect the **context window**.

```
Session start:
  Context window ← [skill name + description only]

User triggers skill:
  Context window ← [skill name + description + full SKILL.md instructions]

During execution (if needed):
  Context window ← [+ referenced files, loaded on demand]
  Scripts        ← executed outside the context window
```

**Why this matters:**

| Without Progressive Disclosure | With Progressive Disclosure |
|-------------------------------|----------------------------|
| All skill content loaded upfront | Only name/desc loaded at start |
| Context fills up fast | Context stays clean |
| More tokens → degraded responses | Instructions arrive exactly when needed |
| Scripts pollute context with output | Scripts run separately, results summarized |

---

## Creating a Skill

1. Create a folder — use lowercase with hyphens (e.g., `weekly-marketing-analysis`). No reserved keywords.
2. Add `SKILL.md` with a YAML header (`name`, `description`) followed by your instructions.
3. Add a `references/` subfolder for any supporting files the skill needs (scripts, templates, data).
4. Zip the folder.
5. In **Claude Desktop → Capabilities → Skills**, upload the zip and enable it.

Once enabled, prompting Claude to do something that matches the skill's description will automatically load and apply it.

---

## When to Use a Skill

> *If you find yourself having the same conversation across sessions — explaining the same workflow over and over — it's a strong candidate for a skill.*

| Signal | Example |
|--------|---------|
| Repeated workflow | "Every Monday, analyze the new marketing CSV and produce a summary" |
| Cross-session pattern | Asking the agent to follow the same code review checklist every PR |
| Specialized domain knowledge | Custom security audit steps for your codebase |
| Multi-step process | Data ingestion → transform → validate → report |

---

## Skills vs Tools vs MCP vs Subagents

These four building blocks are complementary, not competing:

| Mechanism | What It Is | Best For |
|-----------|-----------|---------|
| **Skills** | Packaged instructions + assets | Encoding *how* to do a repeated workflow |
| **Tools** | Functions the agent can call (bash, read, write, web) | Taking discrete actions in the environment |
| **MCP** | Protocol for connecting agents to external services | Integrating with APIs, databases, third-party systems |
| **Subagents** | Separate agent instances spun up to handle subtasks | Parallelism, isolation, or tasks needing a fresh context |

Skills work *with* the others — a skill can instruct the agent to use a specific MCP server, call a tool, or delegate to a subagent. This composition is where the real power comes from.

**Example workflow:**

```
User: "Run the weekly marketing report"
  │
  ▼
Skill loads → provides instructions
  │
  ├── Tool (Bash) → runs analysis.py
  ├── MCP (Google Drive) → uploads report
  └── Subagent → drafts the email summary
```

- MCP connects our agents or AI applications with external systems and data, anytime you need external context model doesn't know about MCP is very useful.
- MCP is bringing in all underlying tooling we need and the skill is a set of intructions to put those tools together to build particular workflows that are repeatable.
- Tools are a bit more lower level
- Tool defn always live in the context window, skills are progressively loaded when necessary
- We can think of a subagent, as an agent which can be spawn or created by a main agent, that can report back to main agent. 
- Subagents can have an isolated context, with fine grained permissions as well as executing tasks in parallel. They can have limited set of permissions as well as access to skills.
- When we think about context window we need to be intentional, we need to be mindful of how subagents can help us minimize what goes into the context window and how MCP loads the data necessary. Skills should be loaded progressively
- Subagents can persist across sessions, skills can persist across conversations 
- Use skills for procedural and predictable workflows, and subagents for full agentic logic for specialized tasks

---

## Exploring Pre-Built Skills

- Public Repo of Agent Skills: https://github.com/anthropics/skills
- skill-creator is a skill to help programmatically create a skill for you


## Key Takeaways

| Concept | Key Idea |
|---------|---------|
| **Skill** | Folder of instructions + assets; open standard; any compatible agent can use it |
| **SKILL.md** | Entry point with name/description header + full instructions body |
| **Progressive disclosure** | Name/desc always loaded; full instructions only on trigger; scripts run outside context |
| **When to skill-ify** | Repeated workflows or cross-session patterns you keep re-explaining |
| **Composition** | Skills + Tools + MCP + Subagents = powerful, modular agentic workflows |

---

Resources:
- https://claude.com/blog/skills-explained

*Course: [Agent Skills with Anthropic](https://learn.deeplearning.ai/courses/agent-skills-with-anthropic) — DeepLearning.AI*
