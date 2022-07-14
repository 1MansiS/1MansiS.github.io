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

# PBKDF2

One of the most widely adopted government standardized password hashing algorithm is PBKDF2. PBKDF2 was designed for generating keying material for symmetric encryption. Due to its inherent configurable property to make it run slower, treating keying material derived out of this algorithm as password hashes, turned out to be a far secure choice than storing salted hashed password. It was more a knee-jerk reaction to pick something from the available crypto tools at the time, to protect against the ever-increasing offline cracking incidences.

PBKDF2 is the only password hashing algorithm available right out of JDK.

## HowTo: How Does PBKDF2 Work?

Password hashes are computed by applying HMAC algorithm to password and salt, repeatedly for iteration number of counts(c). This iteration count is responsible for slowing down the password generation, providing mitigation against brute forcing attacks.

## HowTo: Diagrammatic Representation of PBKDF2

![PBKDF2]({{ BASE_PATH }}/assets/images/pbkdf2.jpeg)

**Note:** Values in green are conservative secure configurations. Values in grape color are tuned parameter values on a t2.medium EC2 instance with 2 CPUs and 4GB RAM.

## HowTo: Design Input Parameters Securely?

- **Salt**: In addition to commonalities discussed above, choose salt size >= 64 bites (8bytes)
- **HMAC Algorithm**: Choose from any SHA2 or SHA3 family as underlying hashing algorithm.
- **Length of output password**: Output password size should be no more than the native hash’s output size.
- **Work Factor** - Iteration Count(c): Government suggested value is >= 10,000 which is very conservative. You should be picking at least a 6 figure value.

## HowTo: Implement

- Use [SecretKeyFactory](https://docs.oracle.com/en/java/javase/16/docs/api/java.base/javax/crypto/SecretKeyFactory.html) to specify which digest to use with HMAC algorithm.
- [PBEKeySpec](https://docs.oracle.com/en/java/javase/16/docs/api/java.base/javax/crypto/spec/PBEKeySpec.html) is used to configure different input parameters.

```
// Using SHA-512 algorithm with HMAC, to increase the memory requirement to its maximum, making it most secure pbkdf2 option.
SecretKeyFactory pbkdf2KeyFactory = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA512") ;
 
PBEKeySpec keySpec = new PBEKeySpec(charEnteredPassword, // Input character array of password
                                  salt, // CSPRNG, unique
                                  150000, // Iteration count (c)
                           32) ; // 256 bits output hashed password
 
// Computes hashed password using PBKDF2HMACSHA512 algorithm and provided PBE specs.
byte[] pbkdfHashedArray = pbkdf2KeyFactory.generateSecret(keySpec).getEncoded() ; 
```

Complete code can be referenced at [PBKDF2PasswdStorage.java](https://github.com/1MansiS/JavaCrypto/blob/main/JavaCryptoModule/SecureJavaCrypto/src/main/java/com/secure/crypto/password_storage/PBKDF2PasswdStorage.java).

## HowTo: Decide If This Is The Right Choice For Me?

- PBKDF2 is a very basic CPU intensive algorithm, which can no longer put a tough fight against modern GPUs with multiple cores and easily configurable parallel processing.
- If you don’t have to adhere to government standards, and can use a 3rd party implementation, choose a memory hard function such as Argon2.


# bcrypt

Bcrypt is slightly better than pbkdf2, which provides some memory intensive work in addition to CPU intensive operations. It is based on blowfish symmetric cipher. Like PBKDF2, this algorithm is also roughly two decades old.

## HowTo: How Does bcrypt Work?

It relies on an expensive key setup phase running blowfish based encryption scheme applied a number of iterations times. Briefly, just as pbkdf2, cost factor defines how slow the password computation would be and should be configured accordingly.

## HowTo: Diagrammatic Representation of bcrypt

![BCrypt]({{ BASE_PATH }}/assets/images/bcrypt.jpeg)

**Note:** Values in green are conservative secure configurations. Values in grape color are tuned parameter values on a t2.medium EC2 instance with 2 CPUs and 4GB RAM.

## HowTo: Design Input Parameters Securely?

- **Salt**: Has to be exact 128 bits in size.
- **Work Factor** - cost(c): Cost is configured logarithmically. Thus, 12 ==> 212 iterations.

## HowTo: Implement

Bcrypt is not yet supported by JDK. To use it, we would need to rely on bouncycastle’s low level API (i.e., not thru JCA’s provider pattern). For this, we would need to make sure, [bouncycastle’s jar file](https://www.bouncycastle.org/latest_releases.html) is on class path.

[Bcrypt](http://javadox.com/org.bouncycastle/bcprov-jdk15on/1.53/org/bouncycastle/crypto/generators/BCrypt.html) class provides implementation for this algorithm.

```
BCrypt.generate(
            plainTextPasswd.getBytes(), // byte array of user supplied, low entropy password

salt.getBytes(), // 128 bit(= 16 bytes), CSPRNG generated salt
            14 // cost factor, performs 2^14 iterations.
            );
```

Complete code can be referenced at [BcryptPasswordStorage.java](https://github.com/1MansiS/JavaCrypto/blob/main/JavaCryptoModule/SecureJavaCrypto/src/main/java/com/secure/crypto/password_storage/BCryptPasswdStorage.java).

## HowTo: Decide If This Is The Right Choice For Me?

- Contemporary computer architectures do come with inbuilt RAM modules, making brute force attacks still very viable and providing little memory intensive advantages for using bcrypt over pbkdf2.
- Unless you are restricted by available implementations, use one of the memory hard functions.

# scrypt

Scrypt is one of the earlier generation memory hard functions. It is a solid choice compared to adaptive functions discussed above, giving a lot of parameter tuning options. Its need for lot more resources for its computations effectively diffuses most of the large-scale parallel attacks. Like all the above functions, scrypt is also designed with a focus on deriving key materials, rather than passwords. It’s getting increasing adoption in crypto-currencies like Litecoins, YACoin, etc.

## HowTo: How Does Scrypt Work?

Its memory hard function is based on a combination of Salsa20 steam cipher and xor, keying material pre/post-processed thru HMAC and pbkdf2 algorithms. It has various parameters (cpu/memory processing times)<sup>[12]</sup> to increase computing time, making brute forcing attacks impractical.

## HowTo: Diagrammatic Representation of Scrypt

![SCrypt]({{ BASE_PATH }}/assets/images/scrypt.jpeg)

**Note:** Values in green are conservative secure configurations. Values in purple are tuned parameter values on a t2.medium EC2 instance with 2 CPUs and 4GB RAM.

## HowTo: Design Input Parameters Securely?

- **Salt**: In addition to commonalities discussed above, choose salt size >= 128 bits (16 bytes)
- **Output Length of derived password**: Typically set to 256 bits.
- **Work Factor**:
    - **CPU/Memory Cost(N)/Work Factor/Iteration Count**: Values are configured in power of 2 (i.e., 2N).
    - **Block size(r)**: In the future, if memory becomes cheaper, increase this value.
    - **Parallelization Factor(p)**: In the future, if the processing power of CPU increases, upgrade this value.

## HowTo: Implement

We would need to depend on bouncycastle’s low-level API (non-provider supplied) and place [bouncycastle's jar file](https://www.bouncycastle.org/latest_releases.html) on class path. [Scrypt](https://javadoc.io/static/org.bouncycastle/bcprov-jdk15on/1.68/org/bouncycastle/crypto/generators/SCrypt.html) supplies implementation to generate keys using this class.

```
SCrypt.generate(
            plainTextPasswd.getBytes(), // user supplied password, converted into byte array
            salt.getBytes(), // salt of size 32 bytes
            65536, // CPU/Memory cost
            16, // block size
            1, // Parallelization parameter:
            32 // (256 bits) Length of output key size
            );
```

For a complete working example, refer to [ScryptPasswordStorage.java](https://github.com/1MansiS/JavaCrypto/blob/main/JavaCryptoModule/SecureJavaCrypto/src/main/java/com/secure/crypto/password_storage/ScryptPasswdStorage.java).

## HowTo: Decide If This Is The Right Choice For Me?

- Unlike Argon2, Scrypt can’t be made to compute slower without the huge overhead of bigger memory, i.e., CPU cost and memory cost can’t be separated. This is because its CPU/Memory cost parameter (N), can’t be tuned separately.
- A lot more crypto schemes are involved in the internal workings of the algorithm, increasing complexity in terms of implementations, cryptanalysis etc.

This post should equip you to choose the right algorithm to store sensitive information, how to meticulously tune each required input parameter and how to code it all up in Java. 

Designing password hashing mechanisms is one piece of a much-complicated puzzle, where coding tools can help. It is equally important to choose passwords wisely. A lot of experimental results are available which emphasize the criticality of choosing longer, higher entropy passwords<sup>[13]</sup> which will significantly increase the work involved in cracking them offline.

I will encourage you to experiment with various password storage algorithms, by invoking corresponding endpoints discussed in [Java Crypto MicroService](https://github.com/1MansiS/JavaCrypto).

TL; DR

- Historical methods of storing passwords such as computing its hash, using salts etc. easily crumbles to growing computing resources.
- Using one of the suitable key derivation functions (KDFs), derive a hash version of the plain text password and never persist its plain text version.
- Salt used in any KDF should be CSPRNG, unique per password and stored far away from password hashes.
- Work Factors should be a fine balance between security and performance, configured unique to server, different per user and re-tuned periodically.
- If adhering to some government standard is not a requirement use Argon2 memory hard KDF for storing passwords.

# References:

## Oracle/Java Documentation:

1. [Java Cryptographic Architecture](https://docs.oracle.com/en/java/javase/16/security/java-cryptography-architecture-jca-reference-guide.html#GUID-2BCFDD85-D533-4E6C-8CE9-29990DEB0190)

2. [Java Security Standard Algorithm Names](https://docs.oracle.com/en/java/javase/16/docs/specs/security/standard-names.html)

## Standards:

3. [NIST SP 800-132](https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-132.pdf): Password Based Key

4. [NIST SP 800-135](https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-135r1.pdf): Recommendation for existing application specific KDFs

5. [NIST SP-800-108](https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-108.pdf): Recommendation for KDF using pseudo-random

6. [RFC 8018](https://tools.ietf.org/html/rfc8018) - Password-Based Cryptography Specification

7. [Argon2 Specification](https://password-hashing.net/argon2-specs.pdf)

8. [scrypt specification](https://www.tarsnap.com/scrypt/scrypt.pdf)

9. [RFC 8018](https://tools.ietf.org/html/rfc8018): PBKDF2 Specification

10. [bcrypt algorithm](https://www.usenix.org/legacy/events/usenix99/provos/provos_html/node5.html)

## Blogs:

11. [Password Hashing: Scrypt, Bcrypt and ARGON2](https://medium.com/analytics-vidhya/password-hashing-pbkdf2-scrypt-bcrypt-and-argon2-e25aaf41598e) - Michele Preziuso

12. [scrypt parameters](https://stackoverflow.com/questions/11126315/what-are-optimal-scrypt-work-factors)

13. [NIST Password guidance simplified](https://securityboulevard.com/2019/03/nist-800-63-password-guidelines/)

## Misc:

14. [Password Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html)

15. [Salted Password Hashing - Doing it Right](https://crackstation.net/hashing-security.htm)

16. [List of Data Breaches](https://en.wikipedia.org/wiki/List_of_data_breaches)

17. [Parameter Tuning Guidance - Argon2](https://www.twelve21.io/how-to-choose-the-right-parameters-for-argon2/)

18. [Parameter choice for PBKDF2](https://cryptosense.com/blog/parameter-choice-for-pbkdf2/)

19. [How To Store Sensitive Information In 2020](https://sector.ca/sessions/how-to-store-sensitive-information-in-2020/)


