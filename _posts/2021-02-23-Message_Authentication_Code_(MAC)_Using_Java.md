---
layout: post
title:  "Message Authentication Code (MAC) Using Java"
date:   2021-02-23T20:20:46.000Z
tags: java_crypto
---

This is the seventh entry in this blog series on using Java Cryptography securely. Starting from the [basics](https://1mansis.github.io/2017/03/17/How_to_Get_Started_Using_Java_Cryptography_Securely.html) we began diving deeper into various basic cryptographic primitives such as [Cryptographically Secure Random Number Generator](https://1mansis.github.io/2017/03/29/Cryptographically_Secure_Pseudo-Random_Number_Generator.html), [symmetric & asymmetric encryption/decryption](https://1mansis.github.io/2017/04/18/Encryption_and_Decryption_in_Java_Cryptography.html) & [hashes](https://1mansis.github.io/2017/06/13/Message_Digests_aka_Hashing_Functions.html). After taking a brief interval, we caught-up with cryptographic updates in the latest Java version.

Skip to the [TL; DR](#tldr)

At this point, we are well equipped to discuss some of the most commonly encountered cryptographic schemes. Let’s start by looking at applications designed around symmetric cryptography, starting with **Message Authentication Code** in this post. Thankfully, Java provides us with rich, easy-to-use APIs for lot of these applications, relieving us to build up crypto systems from primitives.

# Overview: What is MAC?

Encryption provides us with the confidentiality service of cryptography. In a lot of applications (think of any kind of secure communication), receiving parties need to be assured of the origin of the message (authenticity) and make sure the message is received untampered (integrity).

[Hashing](https://1mansis.github.io/2017/06/13/Message_Digests_aka_Hashing_Functions.html) does provide us with integrity services but not authenticity. In order to get both, we would need a separate crypto-scheme that would compute authentication tags (a.k.a Message Authentication Codes or MACs). Message Authentication Code (MAC) crypto scheme, unlike hashing, involves a secret key to restrict integrity capabilities to only parties that have access to it, which is why it is also called keyed hashing or the more relevant term: cryptographic hash/checksum.

MAC can be constructed using ciphers (such as CMAC & GMAC) or hashes (HMAC). However, it is a bit tricky to get cipher-based MACs right. JDK doesn’t provide any cipher-based MAC constructions too. Rule of thumb: stay away from cipher-based MAC, even if encountered in some 3rd party providers. We already have a more trouble-free option with HMAC, so why risk it? Going ahead, we will just be focusing on HMACs.

# HowTo: How Does it Work?

This crypto scheme works around a central MAC algorithm, which takes 2 pieces of information; symmetric key (k) and plain text message to be authenticated (M) and computes Message Authentication Code. Thus, MAC = HMAC(K,M).

The MAC algorithm (HMAC) takes the message (M) of arbitrary length and generates fixed size authentication tags (or MACs).

## Message Authentication Steps:

1. A symmetric key(K) is established between sender and receiver, typically using a secure channel.
1. The sender computes MAC, using a secure HMAC algorithm on message M and symmetric key(K).
1. The message is appended with MAC and sent across to the receiver i.e., M || MAC is sent to the receiver.
1. Receiver pulls apart M and MAC and recomputes MAC from M using the same HMAC algorithm as sender and symmetric key(K).
1. If the receiver computed MAC == sender sent MAC, authenticity, and integrity of received M is verified. This implies messages have reached received untampered from the stated sender.

# HowTo: Construction of HMAC

# HowTo: Design

