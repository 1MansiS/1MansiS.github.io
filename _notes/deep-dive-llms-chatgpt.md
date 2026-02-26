---
topic: foundations
section: "Language Models"
tag: LLMs
title: "Deep Dive into LLMs like ChatGPT"
source: "https://www.youtube.com/watch?v=7xTGNNLPyMI"
speaker: "Andrej Karpathy"
---

*Notes from Andrej Karpathy's talk. Mental models for what ChatGPT is — what it's good at, not good at, and the sharp edges to be aware of.*

**Source:** [Deep Dive into LLMs like ChatGPT — Andrej Karpathy](https://www.youtube.com/watch?v=7xTGNNLPyMI)

---

## How to Build ChatGPT

Training happens in sequential stages.

### Stage 1: Pre-Training

**Step 1 — Download and process the internet**

Raw web data goes through a pipeline (e.g. [FineWeb](https://huggingface.co/spaces/HuggingFaceFW/blogpost-fineweb-v1)): URL filters (CommonCrawl) → text extraction → quality filters. This produces the pre-training dataset.

**Step 2 — Tokenization**

NNs expect a 1D sequence of symbols from a finite vocabulary. Raw text is compressed using the **byte pair encoding (BPE)** algorithm: repeatedly merge the most frequent adjacent symbol pair into a new token. The result is a vocabulary. Play with GPT-4 tokenization at [tiktokenizer.vercel.app](https://tiktokenizer.vercel.app/).

**Step 3 — Training the Neural Network**

The NN (a transformer) is a giant mathematical expression. Training adjusts its parameters so the probability of the next token matches the training distribution.

![NN Training — tokens in, probabilities out, correct answer guides weight update](/assets/notes/deep-dive-llms/llm-note-img-1.png)

Visualize internals at [bbycroft.net/llm](https://bbycroft.net/llm).

![NN internals — input tokens + billions of weights → giant math expression → 100,277 numbers](/assets/notes/deep-dive-llms/llm-note-img-2.png)

**Step 4 — Inference**

Generating new tokens from the trained model. ChatGPT only does the inference part (plus the assistant layer on top). Pre-training and tokenization happen once; inference runs on every query.

![Pretraining full overview — all four steps plus inference](/assets/notes/deep-dive-llms/llm-note-img-3.png)

---

### The Base Model

A base model is an **internet document simulator** — given prefix tokens, it predicts the next token based on everything it saw during training. It is stochastic by nature.

- Information seen more often in training → remembered more reliably
- **Regurgitation**: reciting training data verbatim (undesirable)
- **Hallucination**: best-guess token prediction when the model hasn't seen the answer

Base models are not assistants. They are glorified autocomplete. Few-shot prompting is a trick to coax assistant-like behavior from a base model.

Released base models need two things: the Python code (e.g. [openai/gpt-2](https://github.com/openai/gpt-2)) and the parameter weights (just numbers). Play with open base models at [app.hyperbolic.xyz](https://app.hyperbolic.xyz/models).

---

### Stage 2: Post-Training — Making an Assistant

All the heavy compute/data/cost is in pre-training. Post-training is relatively cheap and fast.

1. Humans write a dataset of **conversations** (question + ideal answer pairs)
2. Conversations are tokenized (similar protocol to pre-training)
3. Base model is fine-tuned on this data → **Supervised Fine-Tuning (SFT)**

This is called the [InstructGPT paper approach](https://arxiv.org/pdf/2203.02155). OpenAI didn't release the data; HuggingFace OpenAssistant is an OSS equivalent.

The model now has a "human labeler persona" — it answers questions in the style of the experts who wrote the training conversations. If the prompt matches the post-training distribution, the SFT model responds. Otherwise it falls back to pre-training knowledge (the whole internet).

Today, LLMs themselves are used to generate post-training data (e.g. [UltraChat](https://huggingface.co/datasets/stingning/ultrachat)), eliminating the need for humans.

---

## LLM Physiology

### Hallucinations

The model statistically emits tokens from its training distribution. For questions it doesn't know the answer to, it confidently guesses. Mitigations:

- **Teach uncertainty**: train the model on examples where the answer is "I don't know" so the relevant neurons activate on uncertainty ([ref](https://arxiv.org/pdf/2407.21783))

![Mitigation 1 — interrogate model to discover knowledge gaps, add refusal examples to training set](/assets/notes/deep-dive-llms/llm-note-img-4.png)

- **External tools**: model detects uncertainty, emits a special `<SEARCH_WEB>` token, fetches new data, adds it to the context window, then infers from the richer context. Knowledge in model parameters = vague recollection; knowledge in context window tokens = working memory.

![Vague recollection vs Working memory — params vs context window](/assets/notes/deep-dive-llms/llm-note-img-5.png)

### Knowledge of Self

Without intervention, a model asked "Who are you?" gives a statistically plausible answer (often "ChatGPT by OpenAI") because that text is prevalent in pre-training data — even if the model is something else entirely. Fix: hardcode a system prompt at conversation start, or fine-tune with identity-specific conversations.

### Models Need Time to Think

Each token spends a finite amount of compute in the NN. To solve hard problems:

- **Spread computation across tokens** — let the model "think out loud" before answering
- **Use a code interpreter** — models can't do mental arithmetic but can write and run Python
- Models are bad at spelling because they see **tokens** (chunks), not individual characters; the tokenizer isn't character-aware

---

## Summary: Three Stages

| Stage | What it does | Training data |
|---|---|---|
| Pre-training | Internet document simulator | The entire internet |
| Post-training (SFT) | Assistant with human persona | Human-written Q&A conversations |
| RLFT | Reasoning / "thinking" models | Verifiable Q&A + trial-and-error |

**RLFT (Reinforcement Learning on Fine-Tuned models)**: generate many candidate answers, pick the best, train on it, repeat. All major providers do this internally; **DeepSeek** was the first to open-source the approach and demonstrate its "reasoning" capability. Models learn to allocate more tokens to thinking — essentially chain-of-thought emerging from RL.

- `GPT-o*` series = thinking/reasoning models (RLFT)
- `GPT-4*` series = mostly SFT post-trained models
- For factual questions → SFT models. For math/logic → reasoning models.

**RLHF (Reinforcement Learning from Human Feedback)**: extends RL to unverifiable domains by training a "reward model" NN on human preferences, then using it as a simulator. Downside: the reward function can be gamed since it's a NN approximation, not real human feedback.

---

## Future Capabilities

- **Multimodal**: audio, video, images are just more tokens — same model handles all modalities
- **Agents**: models operating autonomously over longer horizons
- **Test-time training**: currently impossible to add knowledge after training except via the (finite) context window; multimodal use cases will push context windows larger

---

## How to Keep Up

- [lmarena.ai](https://lmarena.ai) — human-preference model rankings (somewhat gamed, but good first pass)
- [ainews newsletter](https://buttondown.com/ainews) — daily summaries

## How to Access Models

| Type | Where |
|---|---|
| Proprietary (GPT, Gemini) | chatgpt.com, gemini.google.com |
| Open-weight (DeepSeek, LLaMA) | [together.ai](https://together.ai) |
| Base models | [hyperbolic.xyz](https://app.hyperbolic.xyz/models) |
| Run locally | [LM Studio](https://lmstudio.ai) |
