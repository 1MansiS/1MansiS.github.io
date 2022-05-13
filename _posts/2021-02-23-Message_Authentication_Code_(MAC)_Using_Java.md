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

![MAC Construction]({{ BASE_PATH }}/assets/images/GSD1.pheno.png)

# HowTo: Design

We would mainly need to make two secure decisions:

## HowTo: Which HMAC Algorithm to Use?

It should be clear, HMAC computing algorithm is central in this MAC construction. JCA does provide a few of the not-so-safe HMACs for backward compatibility. Stay away from those. The list of secure JCA provided HMAC algorithms are:

```
1.  HmacSHA224
2.  HmacSHA256
3.  HmacSHA384
4.  HmacSHA512
5.  HmacSHA512/224
6.  HmacSHA512/256
7.  HmacSHA3-224
8.  HmacSHA3-256
9.  HmacSHA3-384
10. HmacSHA3-512
```

**Note:** Collision resistance weakness of the underlying hash doesn’t impact the security strength of an HMAC scheme. Having said that MD5 is already out of the door[7] by most protocols and standards, but also SHA1 is severely discouraged due to its lower output size and various other reasons.

Summarizing,

---
Use only the SHA2 or SHA 3 family of underlying hash for your HMAC algorithm.
---

## HowTo: Securely Generate a Symmetric Key?

Your MAC scheme is as secure as your key. Make sure:

---
Key size of Symmetric Key(K) is >= 128 bits
---

and

---
A computed Symmetric key should be safeguarded as any other cryptographic keying material, i.e., it should be accessed only by involved parties.
---

## HowTo: Implement

Putting this all together, let's look at pseudo-code:

* **Step 1: Computing a Symmetric Key (K),** for the required HMAC algorithm, use recommended key size. As discussed in the post on [encryption/decryption](https://1mansis.github.io/2017/04/18/Encryption_and_Decryption_in_Java_Cryptography.html) we would be using [KeyGenerator](https://docs.oracle.com/en/java/javase/15/docs/api/java.base/javax/crypto/KeyGenerator.html).

```
KeyGenerator keygen = KeyGenerator.getInstance("HmacSHA512"); // Use a secure underlying hash for HMAC algorithm.  
keygen.init(256); // Explicitly initializing keyGenerator. Specify key size, and trust the provider supplied randomness. 
SecretKey hmacKey = keygen.generateKey(); // SecretKey holds Symmetric Key(K)
```

* ** Compute MAC** using [Mac](https://docs.oracle.com/en/java/javase/15/docs/api/java.base/javax/crypto/Mac.html#init(java.security.Key)) class by providing computed symmetric key (K), and plain text message M to a secure HMAC algorithm.

```
Mac mac = Mac.getInstance("HmacSHA512"); // get access to Mac object which implements HmacSHA512 algorithm. 
mac.init(new SecretKeySpec(hmacKey.getEncoded(), "HmacSHA512")); // Initialize Mac object with symmetric key(K), same as with sender
mac.update(message.getBytes()); // add message data (M) to Mac object to compute Mac. 
String senderMac = mac.doFinal(); // Compute MAC
```

* **Step 3: Send MAC to receiver side** Message and computed MAC sent from sender to receiver.
* **Step 4:** On the receiver’s side, re-compute MAC by providing symmetric key (K), plain text message (M) to the same secure HMAC algorithm used on the sender side.

```
Mac mac = Mac.getInstance("HmacSHA512"); // get access to Mac object which implements same algorithm used on sender side 
mac.init(new SecretKeySpec(hmacKey.getEncoded(), "HmacSHA512")); // Initialize Mac object with symmetric key(K), same as with sender
mac.update(message.getBytes()); // add message data (M) to Mac object to compute Mac. 
String receivedMac = mac.doFinal(); // Compute MAC
```

* **Step 5: Verify received MAC and re-computed MAC**

If received MAC, and re-computed MAC are identical on the receiver side, M is received untampered from the expected sender (party with symmetric key(K)).

```
if (macComputationAPI.computeMac(hmacKey, data).equals(mac)){
    return "Authentication and Integrity checked cleared on Received message " + M;
} else {
    return "Message " + M + " received on receiver side is tampered with, or doesn't come from the expected sender";
}
```

**Note:** Peeping into the upcoming [Java 16 release notes](https://jdk.java.net/16/release-notes), there are no new additions apart from some backend sun provider support, which should not impact any of these discussions.

Refer to [MACComputationAPI](https://github.com/1MansiS/JavaCrypto/blob/main/JavaCryptoModule/SecureJavaCrypto/src/main/java/com/secure/crypto/mac/MACComputationAPI.java) for a complete code example.

# HowTo: Do's and Don'ts
Do’s:

* Use only secure underlying hashes as HMAC algorithm.
* The key size to be used should be >= 128 bits.
* Symmetric Key(K) used on sender and receiver sides, should be safeguarded as any secret key.

Don'ts:

* Don’t use underlying hash algorithms from the 90s such as HmacMD5 & HmacSHA1, even if JDK provides those.

# HowTo: Where is it Used (Applications)?

MACs are crucial in most secure communication protocols, such as tls, ssh, etc. Just focusing on modern applications, which most developers would encounter at some point, would be for authorization mechanisms. MACs are very commonly used for authorization purposes in terms of API Keys, JWT (Json Web Tokens)[3][4] & session IDs. Taking the example of JWT and seeing how it fits; Server signs a json payload with one of the signing algorithms, HMAC-SHA256 being one of them. This signature is attached to the encoded payload and passed to the client. The client in turn includes this exclusive payload (authenticity) and signature in each request thereafter talking to the server. The server verifies this signature to establish integrity.

You can experiment with sender and receiver endpoints of a MAC by invoking corresponding endpoints from [Java Crypto MicroService](https://github.com/1MansiS/JavaCrypto).

This concludes our relevant discussion on using Message Authentication Codes. We will continue talking about a few more cryptographic applications and constructions in future posts. Stay tuned!

TL; DR

* MAC provides authenticity and integrity security services.
* Stay away from cipher (CMAC) based MACs, use only Hash-based MACs.
* MACs are generated for a given message, using a symmetric key shared by both sending and receiving parties.
* Use only secure hashes from SHA2 and SHA3 families of hashing algorithms.
* Make sure Secret Key (K) is safeguarded and is of minimum 128 bits in length.
* Commonly used for authorization mechanisms in modern applications.

# References:

## Oracle/Java Documentation:
1. [Java Cryptographic Architecture](https://docs.oracle.com/en/java/javase/15/security/java-cryptography-architecture-jca-reference-guide.html#GUID-2BCFDD85-D533-4E6C-8CE9-29990DEB0190)
2. [Java Security Standard Algorithm Names](https://docs.oracle.com/en/java/javase/15/docs/specs/security/standard-names.html)

## Standards

3. [RFC 7519](https://tools.ietf.org/html/rfc7519) discusses JWT standard
4. [RFC 7518](https://tools.ietf.org/html/rfc7518#section-3.1) section 3.1 mentions list of signing algorithms.
5. [NIST FIPS 198-1](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.198-1.pdf) discusses keyed-HMAC.
6. [NIST SP 800-107](https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-107r1.pdf) Section 5.3, discusses security strength of HMAC scheme.
7. [RFC 6151:](https://tools.ietf.org/html/rfc6151) Security Considerations for the MD5 Message-Digest and the HMAC-MD5 Algorithms

## Blogs/Conferences/Books
8.  [JWT Introduction](https://jwt.io/introduction): Json Web Tokens
9.  Book Title - Serious Cryptography - Jean Philippe Aumasson
10. Book Title - Understanding Cryptography - Christof Paar & Jan Pelzl