---
topic: foundations
section: "Machine Learning"
tag: "Course Notes"
title: "Machine Learning — Foundations"
source: "https://www.coursera.org/learn/machine-learning"
speaker: "Andrew Ng"
---

# Machine Learning — Foundations
**Course:** Stanford / Coursera — Andrew Ng
**Week:** 1–2 | **Started:** July 1, 2019

---

## Table of Contents
1. [What is Machine Learning?](#what-is-machine-learning)
2. [Types of Learning](#types-of-learning)
   - [Supervised Learning](#supervised-learning)
   - [Unsupervised Learning](#unsupervised-learning)
3. [Model Representation](#model-representation)
4. [Cost Function](#cost-function)
5. [Gradient Descent](#gradient-descent)
6. [Multivariate Linear Regression](#multivariate-linear-regression)

---

## What is Machine Learning?

> *"Machine learning is a science of getting computers to learn without being explicitly programmed."*
> — Arthur Samuel (popularized by Andrew Ng)

**Formal definition (Tom Mitchell):**
A computer program is said to **learn from experience E** with respect to some **task T** and some **performance measure P**, if its performance on T, as measured by P, **improves with experience E**.

### Example — Playing Checkers

| Symbol | Definition |
|--------|-----------|
| **E** | Experience of playing many games of checkers |
| **T** | The task of playing checkers |
| **P** | Probability that the program wins the next game |

---

## Types of Learning

### Supervised Learning

The algorithm is given a **labeled dataset** — every training example has a known "right answer." The goal is to learn a mapping from inputs to outputs.

**Key characteristics:**
- Labeled training data with direct feedback
- Goal: predict output for unseen inputs

**Two main problem types:**

| Type | Output | Example |
|------|--------|---------|
| **Regression** | Continuous value | Predicting house prices |
| **Classification** | Discrete category | Tumor: benign (0) or malignant (1) |

> **Note:** Classification can have more than 2 categories — e.g., 0 = benign, 1 = malignant type A, 2 = malignant type B.

---

### Unsupervised Learning

The algorithm is given data **with no labels**. It must find hidden structure on its own — we don't tell it what the "right answer" looks like.

**Key characteristics:**
- No labeled examples, no feedback
- Approach problems with little or no idea what results should look like

**Two main techniques:**

| Technique | Description | Example |
|-----------|-------------|---------|
| **Clustering** | Automatically groups data into bands of similar or related items | Group users by lifespan, roles, location |
| **Non-clustering** | Find structure in a chaotic environment | Cocktail party problem — separating voices from mixed audio |

> **Reinforcement Learning** (mentioned briefly): the algorithm learns by interacting with an environment and receiving rewards or penalties — covered separately.

---

## Model Representation

**Linear regression** draws the best-fit straight line through data in a scatter plot. This line is called the **regression line** and is useful for making predictions.

### Training Set — Housing Prices Example

| Size in ft² (x) | Price in $1000s (y) |
|:-:|:-:|
| 2104 | 460 |
| 1416 | 232 |
| 1534 | 315 |
| 852  | 178 |
| …   | …   |

### Notation

| Symbol | Meaning |
|--------|---------|
| **m** | Number of training examples |
| **x** | Input variable / feature |
| **y** | Output variable / target variable |
| **(x, y)** | Single training example |
| **(x⁽ⁱ⁾, y⁽ⁱ⁾)** | The i-th training example (i-th row in the table) |

### How the Supervised Learning Pipeline Works

```
Training Set
     │
     ▼
Learning Algorithm
     │
     ▼
  h (hypothesis)
     │
  x ──► h(x) ──► ŷ (predicted output)
```

The hypothesis **h** maps input **x** to a predicted output **ŷ**.

### Hypothesis Function — Univariate Linear Regression

For a single input feature, the hypothesis is:

$$h_\theta(x) = \theta_0 + \theta_1 x$$

- **θ₀** — the y-intercept (bias term)
- **θ₁** — the slope (weight for feature x)

This is called **univariate linear regression** — one variable, one feature.

---

## Cost Function

The cost function measures **how wrong** the hypothesis is across all training examples. We want to choose θ₀ and θ₁ to minimize it.

**Goal:** Choose θ₀, θ₁ so that h(x) is as close to y as possible for all training examples (x, y).

### Mean Squared Error (MSE) Cost Function

$$J(\theta_0, \theta_1) = \frac{1}{2m} \sum_{i=1}^{m} \left( h_\theta(x^{(i)}) - y^{(i)} \right)^2$$

- The ½ is a convenience factor that cancels when taking the derivative
- This is also called the **squared error loss function**

**Optimization objective:**

$$\min_{\theta_0,\, \theta_1} \; J(\theta_0, \theta_1)$$

### Intuition — Simplified Example (θ₀ = 0)

Set θ₀ = 0 to simplify: **h(x) = θ₁x** (line through the origin).
Now J is purely a function of θ₁ — a parabola.

**Worked example with 3 training points: (1,1), (2,2), (3,3)**

| θ₁ | h(x) | J(θ₁) |
|----|------|--------|
| 0  | 0    | ~1.67  |
| 0.5 | 0.5x | ~0.58 |
| 1  | x    | **0** ← optimal |

At θ₁ = 0.5:

$$J(0.5) = \frac{1}{2 \times 3}\left[(0.5-1)^2 + (1-2)^2 + (1.5-3)^2\right] = \frac{1}{6}[0.25 + 1 + 2.25] \approx 0.58$$

> When we plot J(θ₁) vs θ₁, we get a **convex parabola** with a single global minimum — this is the ideal landscape for optimization.

### Visualizing with Both Parameters

When θ₀ ≠ 0, plotting J(θ₀, θ₁) gives a **3D bowl-shaped surface** (convex). We can also view it as **2D contour plots** — the center of the smallest contour ellipse is the minimum.

---

## Gradient Descent

Gradient descent is the algorithm used to **find the values of θ₀ and θ₁ that minimize J**.

**Intuition:** Imagine standing on a hilly landscape and taking small steps downhill in the direction of steepest descent — eventually reaching the valley (minimum).

### Algorithm

Start with some initial θ₀, θ₁ (often both = 0), then **repeat until convergence**:

$$\theta_j := \theta_j - \alpha \frac{\partial}{\partial \theta_j} J(\theta_0, \theta_1) \quad \text{for } j = 0, 1$$

> **Critical:** Update θ₀ and θ₁ **simultaneously** using temp variables, not sequentially.

```
temp0 := θ₀ − α · ∂J/∂θ₀
temp1 := θ₁ − α · ∂J/∂θ₁
θ₀ := temp0
θ₁ := temp1
```

**α (alpha)** is the **learning rate** — controls the step size:
- Too small → very slow convergence
- Too large → may overshoot, fail to converge, or diverge

### Gradient Descent for Linear Regression

After computing the partial derivatives of the MSE cost function:

**Repeat until convergence:**

$$\theta_0 := \theta_0 - \alpha \cdot \frac{1}{m} \sum_{i=1}^{m} \left(h_\theta(x^{(i)}) - y^{(i)}\right)$$

$$\theta_1 := \theta_1 - \alpha \cdot \frac{1}{m} \sum_{i=1}^{m} \left(h_\theta(x^{(i)}) - y^{(i)}\right) \cdot x^{(i)}$$

*(Update both simultaneously)*

### Key Properties

- **"Batch" Gradient Descent** — each update uses the **entire** training set (all m examples)
- The cost function J of linear regression is always **convex** (bowl-shaped) → only one global minimum, no local minima
- Starting from any initial guess and repeatedly applying these updates will make the hypothesis more and more accurate

---

## Multivariate Linear Regression

**Week 2** — extends linear regression to **multiple input features** (variables) to better predict the output.

### Training Set — Extended Housing Example

| Size (ft²) | # Bedrooms | # Floors | Age (yrs) | Price ($1000s) |
|:-----------:|:---------:|:--------:|:---------:|:--------------:|
| 2104 | 5 | 1 | 45 | 460 |
| 1416 | 3 | 2 | 40 | 232 |
| 1534 | 3 | 2 | 30 | 315 |
| 852  | 2 | 1 | 36 | 178 |

### Notation

| Symbol | Meaning |
|--------|---------|
| **n** | Number of features |
| **x⁽ⁱ⁾** | Input features of the i-th training example (a vector) |
| **xⱼ⁽ⁱ⁾** | Value of feature j in the i-th training example |
| **x₁, x₂, x₃, x₄** | Size, # bedrooms, # floors, age |

### Hypothesis Function — Multivariate

$$h_\theta(x) = \theta_0 + \theta_1 x_1 + \theta_2 x_2 + \cdots + \theta_n x_n$$

**Vectorized form** (using the convention x₀ = 1):

$$\mathbf{x} = \begin{bmatrix} x_0 \\ x_1 \\ \vdots \\ x_n \end{bmatrix} \in \mathbb{R}^{n+1}, \quad \boldsymbol{\theta} = \begin{bmatrix} \theta_0 \\ \theta_1 \\ \vdots \\ \theta_n \end{bmatrix} \in \mathbb{R}^{n+1}$$

$$h_\theta(x) = \boldsymbol{\theta}^T \mathbf{x} = \theta_0 x_0 + \theta_1 x_1 + \cdots + \theta_n x_n$$

> Setting x₀ = 1 (a "dummy" feature) allows the entire hypothesis to be written as a clean dot product **θᵀx**.

### Gradient Descent for Multiple Variables

**Repeat until convergence** (update all θⱼ simultaneously for j = 0, 1, …, n):

$$\theta_j := \theta_j - \alpha \cdot \frac{1}{m} \sum_{i=1}^{m} \left(h_\theta(x^{(i)}) - y^{(i)}\right) \cdot x_j^{(i)}$$

Note that for j = 0, since x₀⁽ⁱ⁾ = 1, this reduces to the familiar θ₀ update.

---

## Summary

| Concept | Key Idea |
|---------|----------|
| **Supervised Learning** | Learn from labeled data; predict continuous (regression) or discrete (classification) output |
| **Unsupervised Learning** | Find hidden structure in unlabeled data (clustering, dimensionality reduction) |
| **Hypothesis h(x)** | The model's prediction function — a line (or hyperplane) for linear regression |
| **Cost Function J** | Measures prediction error; MSE is standard for regression |
| **Gradient Descent** | Iterative optimization algorithm that minimizes J by following the gradient downhill |
| **Batch GD** | Uses all m training examples per parameter update |
| **Multivariate LR** | Extends to n features using vectorized notation: h(x) = θᵀx |

---

*Notes from Andrew Ng's Machine Learning course (Stanford/Coursera) — Pages 1–5*
*Next: Feature Scaling, Normal Equation, Logistic Regression*
