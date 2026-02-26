---
topic: llm
section: "Agents"
tag: Agents
title: "AI Agents Learnings"
---

*Notes from two videos on building AI agents practically, without the hype.*

**Sources:** [Part 1 — How to Build Effective AI Agents (without the hype)](https://www.youtube.com/watch?v=tx5OapbK-8A) · [Part 2 — Building AI Agents in Pure Python](https://www.youtube.com/watch?v=bZzyPscbtI8)

---

## What Are AI Agents?

The popular definition: a **pipeline of automation that at some point calls an LLM API**. But not all AI systems are AI agents. Anthropic draws a clearer distinction between **workflows** (predefined control flow) and **agents** (LLM-driven dynamic decisions).

The [Anthropic blog post on building effective agents](https://www.anthropic.com/engineering/building-effective-agents) is the key reference here.

### Patterns

| Category | Pattern |
|---|---|
| Building Block | Augmented LLMs — retrieval, tools, memory |
| Workflow | Prompt Chaining |
| Workflow | Routing |
| Workflow | Parallelization |
| Workflow | Orchestrator-Workers |
| Workflow | Evaluator-Optimizer |

---

## Tips for Building Agents

- **Be careful with agent frameworks.** They get you running fast, but you won't understand what's happening underneath. Learn the primitives first — it makes you a better engineer.
- **Prioritize deterministic workflows over complex agent patterns.** Start simple. Understand the problem, look at all available data, categorize it, and solve it in a way that works 100% of the time before reaching for agents.
- **Don't jump from prototype to production.** Classic path to hallucination chaos. Scale carefully.
- **Build testing and evaluation systems from the beginning** — not as an afterthought.
- **Put guardrails on outputs.** Before sending a response back to the user, have a second LLM check whether the answer is actually appropriate to send.

---

## Building Blocks in Code

*From [Building AI Agents in Pure Python](https://www.youtube.com/watch?v=bZzyPscbtI8)*

You don't need any fancy frameworks to build AI agents — the LLM provider APIs are enough. The first ~23 minutes of that video cover practical code for the four core building blocks:

- **Memory** — persisting conversation context
- **Structured output** — constraining model responses to a schema
- **Retrieval** — fetching external knowledge at inference time
- **Tools** — letting the model call functions

### Workflow Patterns in Practice

Break down the problem the way a human would think about and approach it. A few notes:

- **Parallelization** is especially well-suited for guardrail checks — run safety evaluation in parallel with the main response rather than sequentially.

---

## References

- [How to Build Effective AI Agents (without the hype) — Part 1](https://www.youtube.com/watch?v=tx5OapbK-8A)
- [Building AI Agents in Pure Python — Part 2](https://www.youtube.com/watch?v=bZzyPscbtI8)
- [Anthropic: Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents)
- [OpenAI API Reference](https://platform.openai.com/docs/api-reference/introduction)
