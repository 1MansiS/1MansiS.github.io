---
layout: post
title:  "Java Crypto Catchup"
date:   2020-11-16T20:20:46.000Z
tags: java_crypto
---

Original post was publish on Veracode blog [here](https://www.veracode.com/blog/research/java-crypto-catchup)

In 2017, we started a blog series talking about how to securely implement a crypto-system in java. [How to Get Started Using Java Cryptography Securely](https://1mansis.github.io/2017/03/17/How_to_Get_Started_Using_Java_Cryptography_Securely.html) touches upon the basics of Java crypto, followed by posts around various crypto primitives [Cryptographically Secure Pseudo-Random Number Generator (CSPRNG)](https://1mansis.github.io/2017/03/29/Cryptographically_Secure_Pseudo-Random_Number_Generator.html), [Encryption/Decryption](https://1mansis.github.io/2017/04/18/Encryption_and_Decryption_in_Java_Cryptography.html), and [Message Digests](https://1mansis.github.io/2017/06/13/Message_Digests_aka_Hashing_Functions.html). We also released a [Java Crypto Module](https://1mansis.github.io/2017/06/13/Java_Crypto_Libraries_Go_Modular.html) for easier dockerization of injectable modules exposing Crypto services via an API.

The last time we spoke about this, we were in Java 8 world. In just 3.5 years we have 7 new Java versions released! Let's revive this series by first catching up on the latest and greatest happenings in the wider cryptographic community and how that maps to newer Java versions in this post. In the following posts, we will be talking about how to securely write some of the more commonly used cryptographic schemes.

Special thanks to my awesome coworkers Jess Garrett and Andrew Shelton for contributing important sections in this post.


[TL;DR](#tldr)

## Generic to entire Java Cryptography Architecture (JCA)



Looking at what we discussed in [How to Get Started Using Java Cryptography Securely](https://1mansis.github.io/2017/03/17/How_to_Get_Started_Using_Java_Cryptography_Securely.html) post, the central theme of Java Cryptography Architecture (JCA)<sup>[11]</sup> defining abstract engine classes for different cryptographic services and having independent implementations thru different providers hasn't changed.

Highlighting the most notable changes in JCA:

1. Probably the best enhancement for lazy people like me would be that we no longer need to include the Unlimited strength jurisdiction file. Unlimited strength in algorithms (for example using 256 key sizes for symmetric algorithms) comes out of the box. It is enabled by default in the **java.security** file, with property **crypto.policy=unlimited**.
2. The security configuration file (java.security) will now be found under the `$JAVA_HOME/Contents/Home/conf/security/` folder.
3. Third party provider jar files are now treated as libraries rather than extensions. Thus, like any other library jar files, provider jar files will be placed on $CLASSPATH, and not as extensions under `$JAVA_HOME/Contents/Home/jre/lib/ext` folder.

## Secure Random

As we discussed in the [CSPRNG](https://1mansis.github.io/2017/03/29/Cryptographically_Secure_Pseudo-Random_Number_Generator.html) post, Java already provides algorithms (*PRNG) to safely generate a CSPRNG. To add support for the NIST specified<sup>[13]</sup> algorithms, Java provides a new algorithm named DRBG.

### Why Should You Use DRBG?

The primary reason to use DRBG is that it is government standardized. Also, the DRBG algorithm specification provides more granular configurations of how the underlying algorithm should work. It still sources entropy from the underlying operating system, in case you were wondering.

### HowTo: Design and Code It

Some of the extra algorithm-specific configurations and our recommendations are:

- DRBG mechanism: Underlying mechanism being used should be either Hash or HMAC. Defaults to Hash_SHA256, which is perfectly safe.
- Security Strength: Default is 128 bits, can be increased.
- Prediction Resistance: In an event, if the internal state of CSPRNG is compromised, future DRBG outputs won't be impacted. Enable this.
- Reseeding: This will periodically reseed to avoid too many outputs from a single seed. Enable this.
- Personalization String: This is a recommended but not required hardcoded string, which plays a role while seeding but not while adding entropy.

All this can be configured using [DrbgParameter](https://docs.oracle.com/en/java/javase/15/docs/api/java.base/java/security/DrbgParameters.html).

The most secure way to configure a SecureRandom object using DRBG the algorithm would be:


```
SecureRandom drbgSecureRandom = SecureRandom.getInstance("DRBG" , 
       DrbgParameters.instantiation(256,  // Required security strength
            PR_AND_RESEED,  // configure algorithm to provide prediction resistance and reseeding facilities
            "any_hardcoded_string".getBytes() // personalization string, used to derive seed not involved in providing entropy.
        )
);
```

**Refer:** Complete code example of [Secure Random using DRBG](https://github.com/1MansiS/JavaCrypto/blob/d544d71376b440e0e7d59ebd1b518b8b17cf9e68/JavaCryptoModule/SecureJavaCrypto/src/main/java/com/secure/crypto/secure_random/SecureRandomAPI.java)

## Encryption/Decryption

There are some exciting advances in Java Cryptography since version 8, and also in the cryptographic community at large since we last spoke about this in [Encryption/Decryption](https://1mansis.github.io/2017/04/18/Encryption_and_Decryption_in_Java_Cryptography.html). With Java it is usually about adding support for newer and shinier algorithms (ChaCha20, Elliptic Curves) which is great, but rarely about deprecating insecure (DES, RC2, etc.) algorithms.

### Symmetric Encryption

It's 2020 and most of our data is going to be online. To safeguard ourselves against any chosen cipher text attacks, we should only be focused on using Authenticated Encryption schemes. Java offers two authenticated encryption schemes: AES-GCM and ChaCha20-Poly1305. Let's see what's going on with each of these:

#### AES-GCM Cipher Scheme

We spoke in length about this in our [encryption/decryption](https://1mansis.github.io/2017/04/18/Encryption_and_Decryption_in_Java_Cryptography.html) post. The only thing that changed since then is how we specify the padding scheme.

Internally, GCM mode is basically a stream cipher where padding is not relevant. Transformation string definition is made consistent with throwing an exception for any other padding except NoPadding[3]. Thus,

```
// This is the only transformation string that would work.
// AES/GCM/PKCS5Padding will throw an exception.
Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
```

**Refer:** Complete working example of [AES-GCM](https://github.com/1MansiS/JavaCrypto/blob/main/JavaCryptoModule/SecureJavaCrypto/src/main/java/com/secure/crypto/cipher/symmetric/AESCipherAPI.java)

#### ChaCha20-Poly1305 Cipher Scheme

##### Why another Authenticated Encryption Cipher Scheme?

While AES-GCM is the gold standard in authenticated symmetric encryption, imagine a world where, due to advances in cryptoanalysis, AES is broken. This would mean the internet and several other protocols (Bluetooth, Wi-Fi, etc.) would be broken and the worst world won't even have a fully vetted backup plan. Luckily, the wider industry is preparing for such a standby cipher by adopting ChaCha20 stream cipher<sup>[14]</sup>.

One other reason for ChaCha20-Poly1305 adoption would be its speed. To run faster AES needs dedicated hardware, which is not always possible in smaller, lower-cost hardware devices such as IoT or smartphones.

Google, Cloudflare, and major browsers such as Chrome and Firefox are already using this in their TLS protocols<sup>[17,18]</sup>.

##### HowTo: Design and Code It?

It is nice to see Java providing Authenticated Encryption cipher construction out of the box in terms of the ChaCha20-Poly1305 algorithm. With this scheme, we can encrypt data of up to 256 GB. This is sufficient enough for any online communication needs but may not work for file/disk encryptions.

##### HowTo: Choose the Right Algorithm and Authenticator?

AES is a block cipher, where the mode of operation and padding parameters are relevant. ChaCha20 is a stream symmetric cipher, where these parameters are not relevant. In AES, using GCM mode provides authentication. In ChaCha20 ciphers, Poly1305 provides authenticator services. Accordingly, the transformation string to be used is as under:

```
Cipher cipher = Cipher.getInstance("ChaCha20-Poly1305");
```

##### HowTo: Generate Keys?

Symmetric Keys are still generated with the [KeyGenerator](https://docs.oracle.com/en/java/javase/15/docs/api/java.base/javax/crypto/KeyGenerator.html) class using the ChaCha20 algorithm. Keys should be 256 bits long. Thus,

```
KeyGenerator keyGenerator = KeyGenerator.getInstance("ChaCha20") ; // Key generator initialized to generate a Symmetric key for use with ChaCha20 algorithm
keyGenerator.init(256 , new SecureRandom()); // Generate a 256 bit key
SecretKey chachaKey = keyGenerator.generateKey(); // Generate and store it in SecretKey
```

##### HowTo: Configure the Initialization Vector

Just like AES-GCM mode, we would need to get into transparent specifications using [IvParameterSpec](https://docs.oracle.com/en/java/javase/15/docs/api/java.base/javax/crypto/spec/IvParameterSpec.html) to configure the initialization vector. Chacha20 ciphers need an initialization vector of size 96 bits (12 bytes).

```
byte iv[] = new byte[12]; // 96 bits IV for ChaCha20, byte array needs size in terms of bytes.
SecureRandom secRandom = SecureRandom.getInstance("DRBG" , 
                    DrbgParameters.instantiation(256, PR_AND_RESEED, "any_hardcoded_string".getBytes()));
secRandom.nextBytes(iv); // DRBG SecureRandom initialized using self-seeding
IvParameterSpec chachaSpec = new IvParameterSpec(iv);
```
**Refer:** Complete working example of [ChaCha20-Poly1305](https://github.com/1MansiS/JavaCrypto/blob/main/JavaCryptoModule/SecureJavaCrypto/src/main/java/com/secure/crypto/cipher/symmetric/ChaChaCipherAPI.java)

### Asymmetric Encryption

A big leap here is support for elliptic curve cryptography (ECC) for various asymmetric encryption applications. This comes with out-of-the-box, clean, and simplified API support served on a silver platter.

#### Why Is the Industry Even Moving Towards Embracing Elliptic Curves?

Well, RSA has for decades been the defacto algorithm used in asymmetric cryptographic applications, such as key agreement protocols and digital signing. However, despite its popularity, RSA is a bit fragile which makes its usage more nuanced than it might initially appear. Subtle complexities in generating prime numbers make it difficult to use RSA library implementations securely. Additionally, it has been subject to numerous well-documented padding oracle attacks over the years, many of which continue to impact modern systems<sup>[19]</sup>.

ECC has been around the block for the past 25 years, providing promising cryptoanalysis and future-proofing our applications. Over the years, many curves have been proposed and implemented. Not all are secure. We will discuss which are secured and should be used and which to avoid.

If you are using RSA don't lose sleep over it, but perhaps validate your code against [Encryption/Decryption](https://1mansis.github.io/2017/04/18/Encryption_and_Decryption_in_Java_Cryptography.html) post. For any new applications, we would strongly encourage using ECC-based APIs.

Let's briefly look at some of the most commonly used public key applications whose APIs are enhanced by later JDK versions:

##### Digital Signature

In addition to the already matured support for NIST approved elliptic curves, I am most excited about Edward curves support in Java 15 for [Digital Signatures](https://docs.oracle.com/en/java/javase/15/docs/api/java.base/java/security/Signature.html) as well as [Key Agreement](https://docs.oracle.com/en/java/javase/15/docs/api/java.base/javax/crypto/KeyAgreement.html) engine classes. We will talk in detail about secure ways of using Digital Signatures in a dedicated upcoming post.

If you are too eager, you can refer to complete working examples of using Digital Signatures using [Edward curves](https://github.com/1MansiS/JavaCrypto/blob/main/JavaCryptoModule/SecureJavaCrypto/src/main/java/com/secure/crypto/digital_signature/EdDigitalSignatureAPI.java) and [NIST curves](https://github.com/1MansiS/JavaCrypto/blob/main/JavaCryptoModule/SecureJavaCrypto/src/main/java/com/secure/crypto/digital_signature/ECDigitalSignatureAPI.java).

##### Key Agreement

Key Agreement engine class is equipped with ECC implementations of its classic counterparts protocols of Diffie Hellman and MQV. It comes with support for NIST curves in ECDH and ECMQV algorithms and Edward Curves in XDH, X25519, & X448 algorithms.

##### Encryption/Decryption

JDK does provide support for encrypting using elliptic curves thru support for ECIES (Integrated Encryption Scheme). This is sort of a hybrid algorithm between symmetric-asymmetric mechanisms. Elliptic Curves for encryption/decryption is rarely used due to its limitation around the amount of data it can safely handle at a time.

### Hashing

In addition to what we discussed in our [Message Digests, aka Hashing Functions](https://1mansis.github.io/2017/06/13/Message_Digests_aka_Hashing_Functions.html) post, the SHA3 Family of algorithms are now government approved hashing algorithms. These are not to be viewed as a replacement of SHA2 family algorithms despite the naming. There is nothing insecure about the SHA2 family.

Support for SHA3 algorithms is provided by [MessageDigest](https://docs.oracle.com/en/java/javase/15/docs/api/java.base/java/security/MessageDigest.html) engine class. You can refer to the complete code of using [SHA3 algorithms for computing Message Digests](https://github.com/1MansiS/JavaCrypto/blob/main/JavaCryptoModule/SecureJavaCrypto/src/main/java/com/secure/crypto/message_digest/MessageDigestAPI.java).

At this point, we cobbled together notable enhancements in the last 3.5 years of Java releases. You can experiment with various [secure Java Cryptography Libraries](https://www.veracode.com/blog/secure-development/java-crypto-libraries-go-modular) being discussed in this series. Going forward, we will just be focusing on the latest version. Next, we will start discussing different cryptographic applications using these building blocks. Keep watching this space!

## TL;DR

- No extra configurations or setup is required for using Unlimited Strength cryptographic algorithms.
- Security Configuration file (java.security) would be located under the `$JAVA_HOME/Contents/Home/conf/security/` folder.
- Third party provider jar files should be placed on $CLASSPATH.
- Support for ChaCha20-Poly1305, promising backup plan for AES-GCM Authenticated Encryption.
- Embrace Elliptic curves usage in public key cryptography applications. Support available across all application APIs.
- Support for SHA3 Family of algorithms thru [MessageDigest](https://docs.oracle.com/en/java/javase/15/docs/api/java.base/java/security/MessageDigest.html) engine class.

## References

### Oracle/Java Documentation:

1. [JEP 273](https://openjdk.java.net/jeps/273): DRBG-Based SecureRandom Implementations
2. [JEP-329](https://bugs.java.com/bugdatabase/view_bug.do?bug_id=JDK-8153028): ChaCha20 and Poly1305 Cryptographic Algorithms
3. [JDK-8180392](https://bugs.java.com/bugdatabase/view_bug.do?bug_id=JDK-8180392): GCM mode supports only NoPadding
4. [Java 15 Release Notes](https://cr.openjdk.java.net/~iris/se/15/spec/fr/java-se-15-fr-spec/)
5. [Java 14 Release Notes](https://www.oracle.com/technetwork/java/javase/14-relnote-issues-5809570.html)
6. [Java 13 Release Notes](https://www.oracle.com/technetwork/java/13-relnote-issues-5460548.html)
7. [Java 12 Release Notes](https://www.oracle.com/technetwork/java/javase/12-relnote-issues-5211422.html)
8. [Java 11 Release Notes](https://www.oracle.com/technetwork/java/javase/11-relnote-issues-5012449.html)
9. [Java 10 Release Notes](https://www.oracle.com/technetwork/java/javase/10-relnote-issues-4108729.html)
10. [Java 9 Release Notes](https://docs.oracle.com/javase/9/whatsnew/toc.htm#JSNEW-GUID-71A09701-7412-4499-A88D-53FA8BFBD3D0)

### Java Architectural Documentations:

11. [Java Cryptographic Architecture](https://docs.oracle.com/en/java/javase/15/security/java-cryptography-architecture-jca-reference-guide.html#GUID-2BCFDD85-D533-4E6C-8CE9-29990DEB0190)
12. [Java Security Standard Algorithm Names](https://docs.oracle.com/en/java/javase/15/docs/specs/security/standard-names.html)

### Standards:

13. [SP 800-90A DRBG Recommendations](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-90Ar1.pdf)
14. [ChaCha20-Poly1305 standard](https://tools.ietf.org/html/rfc8439)
15. [Digital Signature Standard NIST 186-4](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.186-4.pdf)
16. [SP 800-57 Recommendation for Key Management](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-57pt1r4.pdf)

### Blogs:

17. [AES Is Great...But We Need A Fall-back: Meet ChaCha and Poly1305](https://medium.com/asecuritysite-when-bob-met-alice/aes-is-great-but-we-need-a-fall-back-meet-chacha-and-poly1305-76ee0ee61895) - Prof Bill Buchanan
18. [It takes two to ChaCha (Poly)](https://blog.cloudflare.com/it-takes-two-to-chacha-poly/) - CloudFlare Blog Post.
19. [Seriously Stop Using RSA](https://blog.trailofbits.com/2019/07/08/fuck-rsa/)
