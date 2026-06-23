---
topic: rag
section: "Vector Databases & Embeddings"
tag: "Course Notes"
title: "Vector Databases: from Embeddings to Applications"
source: "https://learn.deeplearning.ai/courses/vector-databases-embeddings-applications"
speaker: "Sebastian Witalec"
---

*Notes from the [Vector Databases: from Embeddings to Applications](https://learn.deeplearning.ai/courses/vector-databases-embeddings-applications) course on DeepLearning.AI — Sebastian Witalec (Weaviate).*

---

## Table of Contents
1. [Introduction](#introduction)
2. [How to Obtain Vector Representations of Data](#how-to-obtain-vector-representations-of-data)
3. [Search for Similar Vectors](#search-for-similar-vectors)
4. [Approximate Nearest Neighbors](#approximate-nearest-neighbors)
5. [Vector Databases in LLM Applications](#vector-databases-in-llm-applications)
6. [Sparse vs Dense Vectors & Hybrid Search](#sparse-vs-dense-vectors--hybrid-search)
7. [Application: Multilingual Search](#application-multilingual-search)

---

## Introduction

**What is and why do we need RAGs?**

AI models aren't trained on recent or prioriterary data. To tackle this problem, you can use retrieval augmented generation or RAGs

**Why vector databases?**

Traditional databases store exact values and search with exact matches or range queries. AI applications need something different — the ability to search by *meaning*, not exact text.

A **vector database** stores data as high-dimensional numerical vectors (embeddings) and enables fast similarity search over those vectors. This is the foundation of semantic search, RAG pipelines, recommendation systems, and more.

---

## How to Obtain Vector Representations of Data

### What Is an Embedding?

An **embedding** is a fixed-length numerical vector that encodes the semantic meaning of a piece of data (text, image, audio, etc.). Semantically similar items end up close together in vector space. Vector embedding captures the underlying meaning of the data.

### Encoding-decoding architecture 

Its build on encoder-decoder architecture. For e.g. if an MNIST image contains 28 pixels in one dimension, its 28 * 28 = 784 dimensions. Encoder goes from 784 -> 256 -> 128 -> 2, and decoder goes from 2 -> 128 -> 256 -> 784, and tries to re-create the image. Image won't be perfect in first go, so this process repeats and adjustments are made to achieve perfect image which is called weights.

2 similar images or text will be closer:

```
"dog" → [0.12, -0.84, 0.23, ..., 0.55]  # 1536-dim vector
"puppy" → [0.13, -0.81, 0.25, ..., 0.52]  # close to "dog"
"car" → [-0.72, 0.44, -0.11, ..., 0.08]  # far from "dog"
```

### Embedding Models

| Model | Dimensions | Notes |
|-------|-----------|-------|
| `text-embedding-ada-002` (OpenAI) | 1536 | General purpose, widely used |
| `all-MiniLM-L6-v2` (Sentence Transformers) | 384 | Fast, open-source |
| `multi-qa-mpnet-base-dot-v1` | 768 | Optimized for QA retrieval |
| `CLIP` (OpenAI) | 512 | Multimodal — text + images |

### How to calculate disctance (similarity) between 2 embeddings:

4 most popular distance metrics thats used in context of vector databases:

- Euclidean Distance: The length of the shortest path between two points or vectors.
- Manhattan Distance: Distance between two points if one was constrained to move only along one axis at a time.
- Dot Product: Measures the magnitude of the projection of one vector onto the other.
- Cosine: Measure the difference in directionality between vectors. 

Dot Product and Cosine Distance are commonly used in the field of NLP, to evaluate how similar two sentence embeddings are


---

## Search for Similar Vectors

### Distance Metrics

The core of similarity search is a **distance function** between two vectors:

| Metric | Formula | Best For |
|--------|---------|---------|
| **Euclidean (L2)** | $\sqrt{\sum (a_i - b_i)^2}$ | When magnitude matters |
| **Cosine Similarity** | $\frac{a \cdot b}{\|a\| \|b\|}$ | Normalized text embeddings |
| **Dot Product** | $\sum a_i b_i$ | When vectors are pre-normalized |

> **Cosine similarity** is the most common choice for text embeddings — it measures the angle between vectors and ignores magnitude, so "dog" and "puppy" are close regardless of how many times they appear in training data.

### Brute-Force (Exact) Search

Also called **k-Nearest Neighbor (kNN)** — compare query vector against every stored vector and return the $k$ closest.

- **Accuracy:** 100% exact
- **Complexity:** $O(n \cdot d)$ per query — linear in dataset size $n$ and vector dimension $d$
- **Problem:** Infeasible for millions of vectors at low latency

---

## Approximate Nearest Neighbors

**ANN algorithms** trade a small accuracy loss for dramatic speed gains — instead of finding the *exact* nearest neighbors, they find *very close* neighbors in milliseconds.

### Key ANN Algorithms

| Algorithm | Approach | Notes |
|-----------|---------|-------|
| **HNSW** (Hierarchical Navigable Small World) | Graph-based | Best accuracy/speed tradeoff; default in most vector DBs |
| **IVF** (Inverted File Index) | Clustering | Quantizes space into Voronoi cells; scales well |
| **PQ** (Product Quantization) | Compression | Reduces memory by compressing vectors |
| **FAISS** | Meta's library combining the above | Open source, widely used |

### HNSW Intuition

HNSW builds a layered graph where higher layers have coarser connections and lower layers have fine-grained connections — like zooming in on a map. Search starts at the top (few nodes, big jumps) and drills down to find the actual nearest neighbors.

```
Layer 2 (sparse):  A ——— C ——— F
Layer 1:           A — B — C — D — E — F
Layer 0 (dense):   A-a-B-b-C-c-D-d-E-e-F-f
                           ↑ query lands here
```

### Recall vs. Speed Tradeoff

- **Recall@k** — fraction of true top-k neighbors returned by ANN vs. exact search
- Typical production target: **Recall > 0.95** while achieving < 10ms latency
- Tuning HNSW: `ef_construction` (build quality) and `ef` (search quality)

---

## Vector Databases in LLM Applications

### What Is a Vector Database?

A **vector database** is purpose-built for storing, indexing, and querying embeddings at scale. Beyond raw ANN, vector databases add:

- **CRUD operations** (add, update, delete objects with metadata)
- **Metadata filtering** (pre/post-filter by structured fields)
- **Multi-tenancy** and access control
- **Persistence** (unlike in-memory FAISS)
- **Horizontal scaling**

### Popular Vector Databases

| Database | Notes |
|----------|-------|
| **Weaviate** | Open source; schema-based; strong GraphQL API; built-in ML modules |
| **Pinecone** | Managed; simple API; popular for production |
| **Chroma** | Lightweight; great for local dev and notebooks |
| **Qdrant** | Open source; Rust-based; flexible filtering |
| **pgvector** | Postgres extension — adds vector search to existing Postgres |
| **Milvus** | Open source; designed for billion-scale datasets |

### RAG with a Vector Database

The retrieval step in a RAG pipeline:

```
User Query
    │
    ▼
Embed query → query vector
    │
    ▼
Vector DB similarity search → top-k relevant chunks
    │
    ▼
Inject chunks into LLM prompt as context
    │
    ▼
LLM generates grounded answer
```

### Weaviate Quickstart (Python)

```python
import weaviate

client = weaviate.Client("http://localhost:8080")

# Define schema
class_obj = {
    "class": "Article",
    "vectorizer": "text2vec-openai",
    "properties": [{"name": "content", "dataType": ["text"]}]
}
client.schema.create_class(class_obj)

# Add data
client.data_object.create({"content": "Vector databases enable semantic search."}, "Article")

# Semantic search
result = (
    client.query
    .get("Article", ["content"])
    .with_near_text({"concepts": ["similarity search"]})
    .with_limit(3)
    .do()
)
```

---

## Sparse vs Dense Vectors & Hybrid Search

### Dense vs Sparse Embeddings

| | **Dense** | **Sparse** |
|--|-----------|-----------|
| Representation | All dimensions have values (e.g., 768 floats) | Most dimensions are 0 (e.g., BM25 term weights) |
| Captures | Semantic meaning | Exact keyword matches |
| Model type | Neural (sentence transformers) | TF-IDF, BM25 |
| Strength | Handles synonyms, paraphrases | High precision for exact terms |
| Weakness | May miss rare keywords | Misses semantic meaning |

### Hybrid Search

Combine dense + sparse retrieval to get the best of both worlds:

```
Dense score (semantic) + α × Sparse score (keyword) → final ranking
```

**Reciprocal Rank Fusion (RRF)** is a common fusion method — ranks results from both systems and merges them without needing to tune a weight $\alpha$.

> **When to use hybrid:** When queries may contain specific product names, codes, or jargon that dense-only search would miss, but you still want semantic generalization.

---

## Application: Multilingual Search

Neural embedding models like `paraphrase-multilingual-MiniLM-L12-v2` embed text from **50+ languages into the same vector space** — enabling cross-lingual search:

- Query in English → retrieve French, Spanish, German documents
- No translation step needed
- Works because the model is trained on parallel multilingual corpora

```python
from sentence_transformers import SentenceTransformer

model = SentenceTransformer('paraphrase-multilingual-MiniLM-L12-v2')

en_query = model.encode("What is a vector database?")
es_doc = model.encode("Una base de datos vectorial almacena embeddings.")

# These will be semantically close despite different languages
```

---

## Key Takeaways

| Concept | Key Idea |
|---------|---------|
| **Embedding** | Fixed-length vector encoding semantic meaning; similar items are nearby in vector space |
| **Cosine Similarity** | Most common metric for text; measures angle, not magnitude |
| **Exact kNN** | 100% accurate but $O(n)$ — impractical at scale |
| **ANN (HNSW)** | Near-exact results in milliseconds; tunable recall/speed tradeoff |
| **Vector Database** | Manages embeddings at scale: indexing, CRUD, filtering, persistence |
| **Hybrid Search** | Dense + sparse retrieval; handles semantic meaning AND exact keywords |
| **Multilingual** | Single multilingual model enables cross-language search without translation |

---

*Course: [Vector Databases: from Embeddings to Applications](https://learn.deeplearning.ai/courses/vector-databases-embeddings-applications) — DeepLearning.AI*
