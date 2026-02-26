---
topic: llm
section: "Agents"
tag: Agents
title: "Andrew Ng: The Rise of AI Agents and Agentic Reasoning"
---

*Notes from Andrew Ng's BUILD 2024 Keynote.*

**Source:** [Andrew Ng Explores The Rise Of AI Agents And Agentic Reasoning — BUILD 2024 Keynote](https://www.youtube.com/watch?v=KrRD7r7y7NY&t=18s)

---

## The AI Stack — Where Are the Biggest Opportunities?

Even though a lot of attention is on AI technology (foundation models), most of the opportunities will be in building AI applications.

![The AI Stack — layers from semiconductors to foundation models to applications](/assets/notes/andrew-ng-agents/andrew-ng-img-1.png)

- Generative AI is enabling fast ML product development
- **Agentic AI workflows is the most important AI technology to pay attention to right now**

---

## Agentic vs Non-Agentic Workflows

![Non-agentic (zero-shot) vs Agentic workflow comparison](/assets/notes/andrew-ng-agents/andrew-ng-img-2.png)

| | Non-Agentic (Zero-Shot) | Agentic |
|---|---|---|
| How it works | Single prompt, start to finish in one go | Iterative — outline → draft → research → revise |
| Analogy | Writing an essay without backspacing | Writing the way a human actually would |

The iterative loop (plan → act → reflect → revise) is what makes agentic workflows substantially more capable than single-shot prompting.

---

## 4 Agentic Reasoning Design Patterns

![Agentic Reasoning Design Patterns with key papers](/assets/notes/andrew-ng-agents/andrew-ng-img-3.png)

1. **Reflection** — Model reviews and critiques its own output, then improves it
   - *Self-Refine*, *Reflexion*, *CRITIC*

2. **Tool Use** — Model makes API calls (web search, code execution, external data)
   - *Gorilla*, *MM-REACT*, *Efficient Tool Use with Chain-of-Abstraction*

3. **Planning** — Model decides on steps before acting; chain-of-thought drives task decomposition
   - *Chain-of-Thought Prompting Elicits Reasoning*, *HuggingGPT*, *Talking to Tasks*

4. **Multi-Agent Collaboration** — Multiple specialized agents communicate and divide work
   - *Communicative Agents for Software Development*, *AutoGen*, *MetaGPT*

---

## LMM — Large Multi-Model Workflows

The AI Stack is gaining a new layer: an **orchestration layer** that coordinates across models, tools, and agents.

![The AI Stack with the new orchestration layer highlighted](/assets/notes/andrew-ng-agents/andrew-ng-img-4.png)

---

## Four AI Trends to Watch

![Four AI Trends](/assets/notes/andrew-ng-agents/andrew-ng-img-5.png)

1. **Agentic workflows are token-hungry** — will benefit from faster, cheaper token generation (SambaNova, Cerebras, Groq)
2. **Today's agents = retrofitted LLMs** — models trained to answer questions, then adapted into iterative workflows; future models will be fine-tuned natively for agentic use (tool use, planning, computer use)
3. **Data engineering is rising in importance** — particularly unstructured data management (text, images)
4. **The text processing revolution is here; image processing is next** — will unlock new visual AI applications in entertainment, manufacturing, self-driving, and security
