---
layout: post
title:  "Message Digests, aka Hashing Functions"
date:   2017-06-13
tags: java_crypto
---

This is the fourth entry in a blog series on using Java cryptography securely. The first entry provided an overview covering [architectural details, using stronger algorithms and debugging tips](https://1mansis.github.io/2017/03/17/How_to_Get_Started_Using_Java_Cryptography_Securely.html). The second one covered [Cryptographically Secure Pseudo-Random Number Generators](https://1mansis.github.io/2017/03/29/Cryptographically_Secure_Pseudo-Random_Number_Generator.html). The third entry taught you how to securely configure basic encryption/decryption primitives. This post will teach you about Message Digest and walk you through some common use cases and show you how to use them securely along with code examples. This blog series should serve as a one-stop resource for anyone who needs to implement a crypto-system in Java. My goal is for it to be a complimentary, security-focused addition to the [JCA Reference Guide](https://docs.oracle.com/javase/8/docs/technotes/guides/security/crypto/CryptoSpec.html).

Skip to the [tl;dr](#tldr)

A message digest algorithm or a hash function, is a procedure that maps input data of an arbitrary length to an output of fixed length. Output is often known as hash values, hash codes, hash sums, checksums, message digest, digital fingerprint or simply hashes. The length of output hashes is generally less than its corresponding input message length. Unlike other cryptographic algorithms, hash functions do not have keys.

Hash functions are an essential part of message authentication codes and digital signature schemes, which deserve special attention and will be covered in future posts. Hash functions are also used in varied cryptographic applications like integrity checks, password storage and key derivations, discussed in this post. They are also utilized in Secure Sockets Layer (SSL), Pretty Good Privacy (PGP), and various other cryptographic protocols. 

# What security properties should a good hash function exhibit?

* **Deterministic:** A given message should always produce the same digest. Otherwise, it's not useful for integrity checks.
* **One-way (pre-image resistance):** It should not be feasible to recover the original message given the digest. Otherwise the digest of a message would leak the message, making it difficult to control message confidentiality.
* **Weak collision resistant (second pre-image resistance):** It should not be feasible to generate an arbitrary message that produces a given digest. Otherwise, a malicious person could trick your integrity check into accepting the wrong message.
* **Strong collision resistant:** It should not be feasible that two reasonably similar messages will result in the same digest. If so, an attacker could simply swap signatures on different messages, for example.
* **Unpredictability:** Because otherwise, #3 and #4 are much easier to accomplish, and because changes in a digest could then leak information about the message.

# Which hashing algorithms to use and which should I stay away from?

[JDK 8's Security API](https://docs.oracle.com/javase/8/docs/technotes/guides/security/StandardNames.html#MessageDigest) offers seven algorithms to choose from, out of which only three are suitable for all applications. This means there is only a 42 percent chance of making the right choice

# Which algorithms should I use?

The SHA2 family of algorithms (SHA2-224, SHA2-256, SHA2-384 and SHA2-512) with security strength<sup>[5]</sup> above 128 bits are safe for all security applications. All SHA2 algorithms except SHA2-224 fall under this category. Security strength can be roughly defined as the number of repetitions required to find a collision (two messages with same hashes) by brute force. SHA2-224 algorithm's output is 224 bits, so it would need a maximum number of 2 224/2 repetitions to find a collision, which won’t provide us with desirable long-term security. Thus,  

<span style="background-color: #FFFF00">Use a hash algorithm providing at least 128 bits of security strength. These would be SHA2-256 and above.</span>

In Java 8, [`MessageDigest`](https://docs.oracle.com/javase/8/docs/api/java/security/MessageDigest.html) class provides hashing functionality. You need to add all the data you need to compute digest for with repeated use of [`update`](https://docs.oracle.com/javase/8/docs/api/java/security/MessageDigest.html#update-byte-) method. Once done, call [`digest`](https://docs.oracle.com/javase/8/docs/api/java/security/MessageDigest.html#digest--) method, which will generate the digest and reset it for next use.

Below would be the most secure way to use Message Digests:

```
/*
Most secure way to use Message Digest. Ideal for copy-pasting ;)
*/
String algorithm = "SHA-512" ; // Algorithm chosen for digesting
String data = args[0] ; // Any piece of data to be hashed, in this example used command line input
MessageDigest md = null ;
 
try {
    md = MessageDigest.getInstance(algorithm) ; // MessageDigest instance instantiated with SHA-512 algorithm implementation
} catch( NoSuchAlgorithmException nsae) {System.out.println("No Such Algorithm Exception");}
 
byte[] hash = null ;
 
md.update(data.getBytes()) ; // Repeatedly use update method, to add all inputs to be hashed.
 
hash = md.digest() ; // Perform actual hashing
 
System.out.println("Base64 hash is = " + Base64.getEncoder().encodeToString(hash)) ;
```

**Note:** Code examples/snippets referenced in JavaDocs of MessageDigest class and [Java Cryptography Architecture](https://docs.oracle.com/javase/8/docs/technotes/guides/security/crypto/CryptoSpec.html#Examples) use "SHA" or "SHA-1" algorithms, which are not secured for many applications, as will be discussed below. Just be wary of not accidentally using them.

# Which algorithms should I stay away from and why?

**MD* algorithms:** JDK provides support for MD2 and MD5 algorithms. These were developed in 1989 and 1991, respectively. Over the years, the security of these algorithms has been severely compromised, with attacks ranging from collision<sup>[7]</sup><sup>[8]</sup>, brute-forcing, etc. NIST no longer approves the use of these algorithms<sup>[6]</sup>.

**SHA-0 and SHA-1:** These algorithms have been compromised with collision resistance attacks<sup>[9]</sup>. Due to this, they should not be used for any applications that requires collision-resistance properties, such as password storage, generating digital signatures or time stamps.<sup>[2]</sup><sup>[6]</sup>SHA1 can be used for non-digital signature generation applications such as HMAC, Key Derivation, hashing passwords etc.

If you are using any of the above algorithms, please plan on upgrading soon.

# Note about the SHA-3 family of algorithms: 

SHA-3 algorithms are newer algorithms and not yet supported by any default providers in Java 8. Their support is first introduced only in [Java 9](https://docs.oracle.com/javase/9/security/oracleproviders.htm), by SUN provider. Supported algorithms are SHA3-224, SHA3-256, SHA3-384 and SHA3-512. As for SHA2 algorithms, all algorithms except SHA3-224 are safe for security usage. However, they're not yet commonly used/deployed. There have been discussions on the complicated specifications<sup>[10]</sup>, interpreted differently by implementers. Thus, if you need to use it, keep an eye on any future developments. These are introduced to be used in parallel to SHA2 rather than as a predecessor.

**How do you safely store user credentials?**

You surely have heard the advice to hash and salt your passwords before storing. This is good practice, but dated. You should also be "stretching" your passwords. There have been way too many password breaches in major companies<sup>[11]</sup> that have affected millions of users. This compelled me to talk a bit about how to store passwords to mitigate against offline attacks. You should use the PBKDF2 algorithm offered by [`SecretKeyFactory`](https://docs.oracle.com/javase/8/docs/api/javax/crypto/SecretKeyFactory.html) as discussed in my previous post on [encryption/decryption](https://1mansis.github.io/2017/04/18/Encryption_and_Decryption_in_Java_Cryptography.html). Under the hood all PBKDFs algorithms use hashing algorithms as pseudo-random generators, and run them tens of thousands of times over a user-supplied password (stretching) and apply a salt (cryptographically random nonce value used in hash calculation) to the output. You would be storing salt and output of PBKDF for user authentication. You can refer to a complete working example under [crypto_usecase/password_management](https://github.com/1MansiS/java_crypto/tree/master/crypto_usecases/password_management)

**File Integrity Checks**

Contrary to popular belief, file integrity checks need to use collision-resistance algorithms<sup>[14]</sup>.  [CalculateChecksum.java](https://github.com/1MansiS/java_crypto/blob/master/message_digest/CalculateChecksum.java) is a complete working example of how to compute the hash of a file.

**Note:** However compelling it may be, please don't truncate hash values. Hash output of minimum 256 bits should be used. Remember why we steered away from SHA2-224 hashes above?

At this point, we have spoken about three main cryptographic primitives, namely: RNG, encryption and Message Digests. These are usually fundamental building blocks of any cryptographic applications or protocols. Most cryptographic systems rarely use these three in isolation; it's usually a combination, which we will start talking about in our following posts. Stay tuned!

# tl;dr

* A hash function transforms arbitrary-length input data into fixed-length output hashes.
* Hashing functions should be deterministic, one-way, collision resistant, pseudo-random and unpredictable.
* The SHA2 family of hash functions, providing security strength above 128 bits, is safe for security use. These would be SHA2-256 and above.
* If you are using any MD* functions, SHA0 or SHA1, plan on upgrading sooner.
* File Integrity checks need to use a collision-resistance hash function.
* For password storage, always use PBKDF2 algorithms. 
* Never use truncated hash values. Always use hashes from secure hashing functions of length 256 and above.

# References

1. Secure Hash Algorithms: https://en.wikipedia.org/wiki/Secure_Hash_Algorithms
2. Recommendation for Transitioning the Use of Cryptographic Algorithms and Key Lengths: http://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-131Ar1.pdf
3. Practical Cryptography by Al-Sakib Khan Pathan, Saiful Azad.
4. Secure Hash Standard: Section 1: Table Secure Hash Function properties: http://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.180-4.pdf
5. Recommendation for Applications Using Approved Hash Algorithms: Security strength of Approved Hash Algorithms: Section 4.2: http://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-107r1.pdf
6. NIST Policy on Hash Functions: http://csrc.nist.gov/groups/ST/hash/policy.html
7. Den Boer & Bosselaers: Collisions for the compression function of MD5: https://www.esat.kuleuven.be/cosic/publications/article-143.pdf
8. Wag and Yu: How to bread MD5 and Other Hash Functions: http://merlot.usc.edu/csac-f06/papers/Wang05a.pdf
9. Wag, Yu and Yin: Efficient Collision Search Attacks on SHA-0: http://www.iacr.org/cryptodb/archive/2005/CRYPTO/1825/1825.pdf
10. http://www.cryptologie.net/article/386/sha-3-keccak-and-disturbing-implementation-stories/
11. List of Data Breaches: https://en.wikipedia.org/wiki/List_of_data_breaches
12. Digital Identity Guidelines: https://pages.nist.gov/800-63-3/sp800-63b.html
13. How to store user's password safely: https://nakedsecurity.sophos.com/2013/11/20/serious-security-how-to-store-your-users-passwords-safely/
14. Vulnerability of software integrity and code signing applications to chosen-prefix collisions for MD5: https://www.win.tue.nl/hashclash/SoftIntCodeSign/


