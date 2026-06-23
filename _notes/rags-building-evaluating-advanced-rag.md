---
topic: rag
section: "Advanced RAG Techniques"
tag: "Course Notes"
title: "Building and Evaluating Advanced RAG"
source: "https://www.deeplearning.ai/courses/building-evaluating-advanced-rag"
speaker: "Jerry Liu, Anupam Datta"
---

*Notes from the [Building and Evaluating Advanced RAG](https://www.deeplearning.ai/courses/building-evaluating-advanced-rag) course on DeepLearning.AI — Jerry Liu (LlamaIndex) & Anupam Datta (TruEra).*

---

## Table of Contents
1. [Advanced RAG Pipeline Overview](#advanced-rag-pipeline-overview)
2. [RAG Triad of Metrics](#rag-triad-of-metrics)
3. [Sentence-Window Retrieval](#sentence-window-retrieval)
4. [Auto-Merging Retrieval](#auto-merging-retrieval)
5. [Evaluation with TruLens](#evaluation-with-trulens)
6. [Summary & Choosing the Right Technique](#summary--choosing-the-right-technique)

---

## Advanced RAG Pipeline Overview

### Why Naive RAG Falls Short

A **naive RAG** pipeline — embed documents in fixed-size chunks, retrieve top-k, stuff into prompt — works for simple cases but breaks down on:

| Problem | Symptom |
|---------|---------|
| **Chunks too small** | Retrieved chunk lacks enough context; LLM gives incomplete answers |
| **Chunks too large** | Noisy retrieval; relevant detail diluted by surrounding text |
| **Embedding granularity mismatch** | You retrieve at chunk level but need surrounding paragraphs |
| **No evaluation** | No way to know if retrieval or generation is failing |

### Advanced RAG Landscape

```
Query
  │
  ▼
[Pre-Retrieval] — query rewriting, HyDE, query expansion
  │
  ▼
[Retrieval] — sentence-window, auto-merging, hybrid search
  │
  ▼
[Post-Retrieval] — re-ranking, context compression
  │
  ▼
[Generation] — LLM with retrieved context
  │
  ▼
[Evaluation] — RAG triad (TruLens / RAGAS)
```

### LlamaIndex Building Blocks

| Component | Role |
|-----------|------|
| `SimpleDirectoryReader` | Load documents from disk |
| `SentenceSplitter` | Chunk documents with overlap |
| `VectorStoreIndex` | Build vector index over chunks |
| `RetrieverQueryEngine` | Orchestrate retrieval + generation |
| `NodePostprocessor` | Post-process retrieved nodes (rerank, filter) |

---

## RAG Triad of Metrics

The **RAG Triad** (from TruEra) defines three independent axes of quality — all three must be high for a trustworthy RAG system.

```
          Answer Relevance
               ↑
               │
  Context  ────┼──── Groundedness
  Relevance    │
               │
         (query, context, response)
```

### 1. Context Relevance

> **"Is the retrieved context actually relevant to the query?"**

- Measures whether the retriever is surfacing useful chunks
- Failure mode: retriever returns plausible-sounding but off-topic chunks
- Score: fraction of retrieved context sentences relevant to the query

### 2. Groundedness

> **"Is the LLM's answer supported by the retrieved context?"**

- Also called **faithfulness** — measures hallucination
- Failure mode: LLM generates confident statements not found in context
- Score: fraction of claims in the response that can be traced back to context

### 3. Answer Relevance

> **"Does the answer actually address what the user asked?"**

- Measures end-to-end response quality relative to the original query
- Failure mode: technically grounded response that doesn't answer the question
- Score: semantic similarity between response and query intent

### Why All Three Together?

| Scenario | Context Rel. | Groundedness | Answer Rel. | Problem |
|----------|-------------|-------------|------------|---------|
| Hallucination | ✅ High | ❌ Low | ❌ Low | LLM ignores context |
| Wrong retrieval | ❌ Low | ✅ High | ❌ Low | Faithful to wrong docs |
| Off-topic answer | ✅ High | ✅ High | ❌ Low | Doesn't answer the question |
| Good RAG | ✅ High | ✅ High | ✅ High | — |

---

## Sentence-Window Retrieval

### The Problem

Small chunks embed well (each chunk is semantically coherent), but retrieved chunks often lack enough surrounding context for the LLM to synthesize a good answer.

### The Technique

**Embed small, retrieve big.**

1. Split documents into **small sentences** (1–3 sentences each)
2. Each sentence node stores a pointer to its **surrounding window** (e.g., ±2 sentences on each side)
3. At query time: embed the small sentence for **accurate retrieval**
4. When sending to the LLM: **replace the sentence with its full window**

```
Document: ... [S1] [S2] [S3] [S4] [S5] [S6] [S7] ...
                          ↑
                    Retrieved (S4)

Window sent to LLM: [S2] [S3] [S4] [S5] [S6]
                    (window_size=2 on each side)
```

### LlamaIndex Implementation

```python
from llama_index.core.node_parser import SentenceWindowNodeParser
from llama_index.core.postprocessor import MetadataReplacementPostProcessor

# Build nodes with sentence windows
node_parser = SentenceWindowNodeParser.from_defaults(
    window_size=3,
    window_metadata_key="window",
    original_text_metadata_key="original_text",
)

# At query time: replace the matched sentence with its window
postproc = MetadataReplacementPostProcessor(
    target_metadata_key="window"
)

query_engine = index.as_query_engine(
    similarity_top_k=6,
    node_postprocessors=[postproc],
)
```

### When to Use

- Documents with dense, information-rich prose
- When individual sentences are semantically meaningful on their own
- When you want tight retrieval precision but broader LLM context

---

## Auto-Merging Retrieval

### The Problem

Chunking is arbitrary — a topic may span multiple adjacent chunks. If multiple chunks from the same parent section are retrieved, it's better to send the full parent than redundant fragments.

### The Technique

**Build a hierarchy; merge up when children dominate.**

1. Parse documents into a **hierarchical tree** — large parent chunks containing smaller leaf chunks
2. Index and embed only the **leaf nodes** (small chunks → precise retrieval)
3. At query time: if enough leaf children of a parent are retrieved, **merge them into the parent node**

```
Document
  └── Chapter (parent, ~512 tokens)
        ├── Paragraph 1 (leaf, ~128 tokens)  ← retrieved
        ├── Paragraph 2 (leaf, ~128 tokens)  ← retrieved
        ├── Paragraph 3 (leaf, ~128 tokens)  ← retrieved
        └── Paragraph 4 (leaf, ~128 tokens)

If 3/4 leaves retrieved → merge into Chapter node
```

### LlamaIndex Implementation

```python
from llama_index.core.node_parser import HierarchicalNodeParser
from llama_index.core.retrievers import AutoMergingRetriever
from llama_index.core.storage.docstore import SimpleDocumentStore

# Build hierarchy: 2048 → 512 → 128 tokens
node_parser = HierarchicalNodeParser.from_defaults(
    chunk_sizes=[2048, 512, 128]
)

nodes = node_parser.get_nodes_from_documents(documents)

# Store all nodes (parents + leaves)
docstore = SimpleDocumentStore()
docstore.add_documents(nodes)

# Retrieve leaves, auto-merge to parents
base_retriever = index.as_retriever(similarity_top_k=12)
retriever = AutoMergingRetriever(
    base_retriever,
    storage_context,
    verbose=True,
    simple_ratio_thresh=0.4,  # merge if 40%+ of children retrieved
)
```

### When to Use

- Long documents with nested structure (chapters, sections, paragraphs)
- When queries often span a sub-topic that exists within one section
- To reduce redundancy when multiple overlapping chunks get retrieved

---

## Evaluation with TruLens

### Why Automated Evaluation Matters

Manual evaluation doesn't scale. TruLens provides **automatic, LLM-assisted evaluation** using the RAG Triad — letting you compare pipeline configurations systematically.

### Setup

```python
from trulens_eval import Tru, TruLlama
from trulens_eval.feedback import Groundedness
from trulens_eval.feedback.provider.openai import OpenAI as fOpenAI

tru = Tru()
provider = fOpenAI()

# Define feedback functions
grounded = Groundedness(groundedness_provider=provider)
f_groundedness = Feedback(grounded.groundedness_measure_with_cot_reasons)
f_context_relevance = Feedback(provider.context_relevance_with_cot_reasons)
f_answer_relevance = Feedback(provider.relevance)

# Wrap your query engine
tru_recorder = TruLlama(
    query_engine,
    app_id="my-rag-v1",
    feedbacks=[f_groundedness, f_context_relevance, f_answer_relevance],
)
```

### Running Eval

```python
eval_questions = ["What is a vector database?", "How does HNSW work?"]

with tru_recorder as recording:
    for q in eval_questions:
        query_engine.query(q)

tru.get_leaderboard(app_ids=["my-rag-v1"])
```

### Reading the Leaderboard

| Pipeline | Context Rel. | Groundedness | Answer Rel. | Latency |
|----------|-------------|-------------|------------|---------|
| Naive RAG | 0.62 | 0.71 | 0.65 | 1.2s |
| Sentence Window | 0.79 | 0.83 | 0.80 | 1.5s |
| Auto-Merging | 0.81 | 0.88 | 0.82 | 1.8s |

> Compare configurations and iterate — TruLens shows *which* component is failing, not just overall quality.

### TruLens Dashboard

```bash
tru.run_dashboard()  # Opens at http://localhost:8501
```

Provides per-question drill-down: which context chunks were retrieved, which claims were grounded, where the pipeline failed.

---

## Summary & Choosing the Right Technique

### Comparison

| Technique | How It Works | Best For |
|-----------|-------------|---------|
| **Naive RAG** | Fixed chunks, embed, retrieve | Prototyping, simple corpora |
| **Sentence Window** | Embed sentences, retrieve windows | Dense prose; high retrieval precision |
| **Auto-Merging** | Hierarchical chunks; merge if dominant | Long structured docs; reducing redundancy |
| **Hybrid Search** | Dense + sparse retrieval | Mixed semantic + keyword queries |

### Iterative Improvement Loop

```
1. Define eval questions
2. Baseline: measure RAG Triad on naive pipeline
3. Identify bottleneck (context relevance? groundedness?)
4. Apply targeted technique
5. Re-evaluate; compare leaderboard
6. Repeat
```

### Key Design Decisions

| Decision | Naive Default | Advanced Options |
|----------|-------------|-----------------|
| Chunk size | Fixed (512 tokens) | Sentence-level, hierarchical |
| Retrieval | Dense kNN | Hybrid, sentence window, auto-merge |
| Post-processing | None | Reranking (CohereRerank, ColBERT) |
| Evaluation | Manual spot-check | TruLens / RAGAS automated triad |

---

## Key Takeaways

| Concept | Key Idea |
|---------|---------|
| **RAG Triad** | Context Relevance + Groundedness + Answer Relevance — all three must be high |
| **Sentence Window** | Embed small → precise match; retrieve window → richer LLM context |
| **Auto-Merging** | Embed leaves → fast retrieval; merge to parents → reduces fragmentation |
| **TruLens** | Automated LLM-based evaluation; per-component failure diagnosis |
| **Iterative Eval** | Measure → identify bottleneck → apply technique → re-measure |

---

*Course: [Building and Evaluating Advanced RAG](https://www.deeplearning.ai/courses/building-evaluating-advanced-rag) — DeepLearning.AI*
