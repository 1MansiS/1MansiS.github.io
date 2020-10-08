---
layout: post
title:  "Message Digests, aka Hashing Functions"
date:   2017-06-13
tags: java_crypto
---

This is the fourth entry in a blog series on using Java cryptography securely. The first entry provided an overview covering [architectural details, using stronger algorithms and debugging tips](https://1mansis.github.io/2017/03/17/How_to_Get_Started_Using_Java_Cryptography_Securely.html). The second one covered [Cryptographically Secure Pseudo-Random Number Generators](https://1mansis.github.io/2017/03/29/Cryptographically_Secure_Pseudo-Random_Number_Generator.html). The third entry taught you how to securely configure basic encryption/decryption primitives. This post will teach you about Message Digest and walk you through some common use cases and show you how to use them securely along with code examples. This blog series should serve as a one-stop resource for anyone who needs to implement a crypto-system in Java. My goal is for it to be a complimentary, security-focused addition to the JCA Reference Guide.

