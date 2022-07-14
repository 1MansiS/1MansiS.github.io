---
layout: post
title:  "Password Storage Using Java"
date:   2021-04-07T20:20:46.000Z
tags: java_crypto
---

Original post was published on Veracode blog [here](https://www.veracode.com/blog/research/password-storage-using-java)

This is the eighth entry in the blog series on using Java Cryptography securely. The first few entries talked about [architectural details](https://1mansis.github.io/2017/03/17/How_to_Get_Started_Using_Java_Cryptography_Securely.html), [Cryptographically Secure Random Number Generators](https://1mansis.github.io/2017/03/29/Cryptographically_Secure_Pseudo-Random_Number_Generator.html), [encryption/decryption](https://1mansis.github.io/2017/04/18/Encryption_and_Decryption_in_Java_Cryptography.html), and [message digests](https://1mansis.github.io/2017/06/13/Message_Digests_aka_Hashing_Functions.html). Later we looked at [What’s New](https://1mansis.github.io/2020/11/16/Java_Crypto_Catchup.html) in the latest Java version. All of this equipped us to talk in detail about some of the most common Cryptographic applications. We started by looking at the symmetric cryptography-based application with [Message Authentication Code](https://1mansis.github.io/2021/02/23/Message_Authentication_Code_(MAC)_Using_Java.html).

Password being such a central piece of any authentication-based system, every developer would be involved with it at some point in his or her career. These are usually stored in databases. Due to various vulnerabilities like SQL Injection, Remote Code Execution, etc., these databases could be compromised<sup>[16]</sup>. It becomes exceedingly important to make sure these stored passwords can’t be cracked offline easily.

Historical methods of storing passwords<sup>[15]</sup> have fallen short against growing computing powers, modern computer architectures, and enhanced attacks. Currently, the most secure way to store passwords is using **Password Based Encryption (PBE)**, which provides functions (called **Key Derivation Functions (KDFs)**) that will convert low entropy user passwords into random, unpredictable, and most importantly one-way, irreversible bytes of data. It should be these bytes of data which should be stored and never plain text passwords to safeguard against offline attacks. KDFs used to generate these random bytes of data are commonly called as password hashing algorithms. They can also be extended to store any kind of sensitive information such as PII (Personally Identifiable Information) which your business needs to protect against offline attacks.

Skip to the [TL; DR](#tldr)

In this post, we will be talking about various KDFs based password hashing algorithms to be used for any password storage requirements.

# Password-Based Key Derivation Functions

Construction of KDFs has evolved over time. There are two broad categories of password hashing algorithms that are widely implemented:

1. Adaptive Functions: Designed to iterate over inner crypto operations 1000s of times, to make password computations slower. Prominent functions are PBKDF2<sup>[3][4][9]</sup> which iterates over a HMAC function and bcrypt<sup>[10]</sup> which iterates over a blowfish based encryption scheme.

2. Memory Hard Functions: Memory hard functions are designed with significant internal memory, which effectively decimates traditional brute forcing techniques even with utilizing modern computer architectures. Prominent functions in this category are Argon2<sup>[7]<sup> and scrypt<sup>[8]</sup>.

Each of these algorithms has some set of parameters that needs to be configured judiciously. Before getting into a full-fledged conversation about various algorithms, let’s talk about some of the commonalities:

1. Salt Generation: When designing salting features of your application, make sure:
- Unique salt is generated for each password.
- To store salt and corresponding hashed password far from each other; like different data stores.
- Salt is generated using a cryptographically strong random number generator discussed in the [CSPRNG post](https://1mansis.github.io/2017/03/29/Cryptographically_Secure_Pseudo-Random_Number_Generator.html) and in the [Catchup post’s DRBG section](https://1mansis.github.io/2020/11/16/Java_Crypto_Catchup.html).

Summarizing,

---
Salts: Should be CSPRNG, unique per password and stored separately from password hashes.
---

2. Work Factor: Work Factors are parameters used for each password hash computation with the sole purpose of making hash calculations slower, thus more computationally expensive, which in turn makes offline password cracking slower. For adaptive functions, the only work factor involved is the number of crypto iterations per calculation. With memory hard functions, we additionally have a few more parameters such as memory and CPU threads which adds more complexity to hashing, making it that much harder for offline cracking. Things to consider while thinking about Work Factors:

- Work factor parameters should be individually tuned for each authentication server application. General guidance would be any interactive application should take at least 1 sec throughput and for non-interactive 5 secs are acceptable values.
- Work Factors should be re-evaluated from time to time (ideally yearly), to keep up with hardware advances.
- They are typically stored in password hash outputs making it a good idea to configure different iterations for each password.

Summarizing,

---
Work Factors: Should be a fine balance between security and performance, configured unique to server, different per user, and re-tuned periodically
---

Let's start discussing the algorithms to be considered in detail followed by some of the runner-ups: 

# Argon2

A memory-hard function, winner of [Password Hashing Competition](https://en.wikipedia.org/wiki/Password_Hashing_Competition) making it the only function designed specifically for password hashing. Argon2 provides maximum mitigation against dedicated modern GPUs and parallelized brute forcing techniques, making it the best choice for any modern-day password storage scheme.

Being the newest addition in the password hashing algorithms arsenal, library implementations were sparse a few years ago, but most mainstream providers have caught up. Unfortunately, not JDK.

## HowTo: How Does Argon2 Work?

This elegant algorithm is based on Blake2-like hashing and a configurable amount of memory table (m) to be re-filled multiple times(t) using some degree of parallelism(p).

## HowTo: Diagrammatic Representation of Argon2

![Argon2]({{ BASE_PATH }}/assets/images/Argon2.jpeg)

**Note:** Values in green are conservative secure configurations. Values in grape color are tuned parameter values on a t2.medium EC2 instance with 2 CPUs and 4GB RAM.

## HowTo: Design Input Parameters Securely?

- **Salt**: In addition to commonalities discussed above, choose salt size >= 64 bits (16 bytes)
- **Mode of Operation(m)**: Few different modes available, choose Argon2id to resist few different categories of attacks<sup>[11]</sup>. If Argon2id mode is not available choose Argon2i.
- Work Factors:
	- **Memory Size(m):** >>1MB
	- **Parallelism(p):** Choose a value based on twice the no of cores in your CPU.
	- **No of Iteration(t):** t no of times, memory array of size m will be re-filled, using p no of threads.

## HowTo: Implement

- JDK doesn’t support this implementation yet, we would need to depend on bouncycastle’s low level API (non-provider supplied) and place [bouncycastle’s jar file](https://www.bouncycastle.org/latest_releases.html) on class path.
- [Argon2Parameters](https://javadoc.io/static/org.bouncycastle/bcprov-jdk15on/1.68/org/bouncycastle/crypto/params/Argon2Parameters.html) is used to configure various input parameters and [Argon2BytesGenerator](https://javadoc.io/static/org.bouncycastle/bcprov-jdk15on/1.68/org/bouncycastle/crypto/generators/Argon2BytesGenerator.html) is used to actually generate the hashes.

```
// Build Argon2 Parameters
 Argon2Parameters.Builder argon2Parameters = (new Argon2Parameters.Builder())
     .withVersion(Argon2Parameters.ARGON2_id) // For password storage recommended mode of operation to protect against both side-channel and timing attacks.
     .withIterations(10) // No of times memory array will be filled
     .withMemoryAsKB(16777) // 16MB of memory assigned
     .withParallelism(4) // # of Parallel processing units
     .withSecret(plainTextPasswd.getBytes()) //password
     .withSalt(salt.getBytes()); // 32 bytes (256 bits) of CSPRNG unique salt
 
Argon2BytesGenerator argon2passwordGenerator = new Argon2BytesGenerator();
argon2passwordGenerator.init(argon2Parameters.build()); // Initializing Argon2 algorithm with configured parameters
 
// Array to store computed hash
byte[] passwdHash = new byte[32];
 
argon2passwordGenerator.generateBytes(plainTextPasswd.getBytes(), passwdHash); 
```

For a complete code example refer to [Argon2idPasswdStorage.java](https://github.com/1MansiS/JavaCrypto/blob/main/JavaCryptoModule/SecureJavaCrypto/src/main/java/com/secure/crypto/password_storage/Argon2idPasswdStorage.java).

## HowTo: Decide If This Is The Right Choice For Me?

- If you are not compelled into using a government-approved password hashing algorithm, spend some time parameter tuning, and use Argon2.
- Parameter tuning needs to be played with and prototyped<sup>[17]</sup>. Values used in the code are considered to be safe for typical modern application, while future-proofing us for foreseeable future.  


