---
layout: post
title:  "Encryption and Decryption in Java Cryptography"
date:   2017-04-18
tags: java_crypto
---

This is the third entry in a blog series on using Java cryptography securely. The first entry provided an overview covering [architectural details, using stronger algorithms, and debugging tips](http://localhost:4000/2017/03/17/How_to_Get_Started_Using_Java_Cryptography_Securely.html). The second one covered [Cryptographically Secure Pseudo-Random Number Generators](https://www.veracode.com/node/24711). This entry will teach you how to securely configure basic encryption/decryption primitives. This blog series should serve as a one-stop resource for anyone who needs to implement a crypto-system in Java. My goal is for it to be a complimentary, security-focused addition to the [JCA Reference Guide](https://docs.oracle.com/javase/8/docs/technotes/guides/security/crypto/CryptoSpec.html). 

Skip to the [tl;dr](#tldr)

Encryption is the process of using mathematical algorithms to obscure the meaning of a piece of information so that only authorized parties can decipher it. It is used to protect our data (including texts, conversations ad voice), be it sitting on a computer or it being transmitted over the Internet. Encryption technologies are one of the essential elements of any secure computing environment.

The security of encryption lies in the ability of an algorithm to generate ciphertext (encrypted text) that is not easily reverted back to its original plaintext. The use of keys adds another level of security to methods of protecting our information. A key is a piece of information that allows only those that hold it to encode and decode a message.

There are two general categories of key based algorithms:

* **Symmetric encryption algorithms:** Symmetric algorithms use the same key for encryption and decryption. These algorithms, can either operate in block mode (which works on fixed-size blocks of data) or stream mode (which works on bits or bytes of data). They are commonly used for applications like data encryption, file encryption and encrypting transmitted data in communication networks (like TLS, emails, instant messages, etc.). 
* **Asymmetric (or public key) encryption algorithms:** Unlike symmetric algorithms, which use the same key for both encryption and decryption operations, asymmetric algorithms use two separate keys for these two operations. These algorithms are used for computing digital signatures and key establishment protocols. 

To configure any basic encryption scheme securely, it's very important that all of these parameters (at the minimum) are configured correctly:

* Choosing the correct algorithm
* Choosing the right mode of operation
* Choosing the right padding scheme
* Choosing the right keys and their sizes
* Correct IV initialization with [cryptographically secure CSPRNG](http://localhost:4000/2017/03/29/Cryptographically_Secure_Pseudo-Random_Number_Generator.html)

It's very important to be vigilant about configuring all of these parameters securely. Even a tiny misconfiguration will leave an entire crypto-system open to attacks.

**Note:** To keep this discussion simple, I will discuss only algorithm-independent initializations of a Cipher. Unless you know what you are doing, let provider defaults do their job of configuring more algorithm-dependent configurations, like p and q values of the RSA algorithm, etc.

Just configuring the basic cryptographic parameters above spans more than half a dozen classes, involving class hierarchies, plenty of overloaded constructors/methods and so on, adding many unnecessary complexities. I wish Java didn't complicate these basic configurations and would instead employ a more simplified architecture like that of Microsoft, where all these parameters are within the perimeter of a single class [SymmetricAlgorithm](https://msdn.microsoft.com/en-us/library/system.security.cryptography.symmetricalgorithm(v=vs.110).aspx) and [AsymmetricAlgorithm](https://msdn.microsoft.com/en-us/library/system.security.cryptography.asymmetricalgorithm(v=vs.110).aspx).

For the first 3 parameters to be specified (algorithm, mode of operation and padding scheme), a [`Cipher`](https://docs.oracle.com/javase/8/docs/api/javax/crypto/Cipher.html) object uses a transformation string. Let's dig deeper and see what is going on in each of these parameters.

# Choosing the correct algorithm:

A transformation string always includes the name of a cryptographic algorithm. Between symmetric and asymmetric encryption, there are 11 algorithms (not considering various `PBEWith<digest|prf>And<encryption>` combinations), which can be specified as per the [Standard Algorithm Name Documentation for Java 8](https://docs.oracle.com/javase/8/docs/technotes/guides/security/StandardNames.html#Cipher) . Out of these only two (one for each, symmetric and asymmetric encryptions) are actually completely secured. The rest of the algorithms, are either way too broken (DES, RC2, etc.) or cracks have started to surface (RC5), making it breakable with sufficient CPU power - it may already be broken by the time you read this. Even the most well-intentioned, security-minded developer might not be reading troves of NIST specifications, nor following the latest happenings and research in the cryptography community, and might pick up broken or risky algorithm, digest or pseudo-random generator. 

Always for:

**Symmetric Algorithm:** Use AES/AESWrap block cipher; and

**Asymmetric Algorithm:** Use RSA

To make matters worse, even the [JCA Reference Guide](https://docs.oracle.com/javase/8/docs/technotes/guides/security/crypto/CryptoSpec.html#CipherBased), uses insecure algorithm specifications in its examples, which are the first – and probably last – stop for copy-pasting code for many. If you follow the [JCA Reference Guide](https://docs.oracle.com/javase/8/docs/technotes/guides/security/crypto/CryptoSpec.html#CipherBased) section "Creating a Cipher Object", you will see examples using the DES algorithm. Going forward, we will limit our discussions to only secured algorithms. 

# Choosing the right mode of operation:

Mode of operation, as part of transformation, is only relevant to block ciphers. While using asymmetric ciphers, use ECB as the mode of operation, which essentially is a hack behind-the-scenes, meaning ignore this value.

If you aren't reading the [Java Cryptography Architecture (JCA) Reference Guide](https://docs.oracle.com/javase/8/docs/technotes/guides/security/crypto/CryptoSpec.html#Cipher) Cipher section carefully, you might just miss the point that Java providers (SunJCE, SunPKCS11) defaults to ECB mode for symmetric as well as asymmetric algorithms. This might be a good thing for asymmetric algorithms, but a terrible idea for block ciphers. Providers could have been instructed to make secure defaults based on the algorithm used. If using symmetric encryption, to save you from replay attacks or known plaintext attacks, please use a transformation, which fully specifies an algorithm (i.e. with its mode of operation and padding). Basically, never, ever do something like:

```
// ANTI-PATTERN
// This defaults to using ECB mode of operation, which should never be used for any cryptographic operations. Plaintext blocks generates
// identical cipher text blocks.
Cipher c = Cipher.getInstance("AES");
```

In the case above, the AES algorithm would be used with ECB mode of operation, making replay attacks very easy.

For any new development, or if there's the slightest chance of revamping old work, use **Authenticated Encryption with Associated Data (AEAD)** mode (For example **GCM** and **CCM**). Use an authentication tag with full 128 bits-length. If you have to use an unauthenticated mode, use CBC or CTR with a MAC to authenticate the ciphertext. We will talk more about MAC along with an example with CBC mode, in upcoming posts. 

# Choosing the right padding scheme:

**Symmetric Algorithms:**

Most block cipher modes require the length of plaintext to be a multiple of the block size of the underlying encryption algorithm, which is seldom the case. Thus, we require some padding.

Java provides 3 different schemes for just symmetric encryption, one being NoPadding (unacceptable) and another being ISO10126Padding (which has be withdrawn since 2007). So, the only viable option is using **PKCS5Padding**. I would like to warn, that a combination of some modes of operation (for example CBC mode) and PKCS5Padding padding scheme can lead to padding oracle attacks<sup>[5]</sup>. However, not specifying a padding scheme at all is more dangerous than providing a scheme which is susceptible only to certain types of attacks. It's best to use AEAD mode of operation to be sure that you're protected against these attacks.

**Asymmetric Algorithms:**

Here, we have the option of choosing from two padding schemes. Make sure to only use **OAEPWith<digest>And<mgf>Padding** schemes. For a digest, please use either **SHA1** or **SHA256/384/512**, unlike what the example in [Standard Names Document](https://docs.oracle.com/javase/8/docs/technotes/guides/security/StandardNames.html#Cipher) (Cipher Algorithm Padding section) specifies. For Mask Generation Function(MGF), use **MGF1** padding as specified. PKCS1Padding with RSA has been susceptible to Chosen Ciphertext attacks<sup>[6]</sup> since 1998.

At this point, we can talk about the correct way to use a transformation in a [`Cipher.getInstance`](https://docs.oracle.com/javase/8/docs/api/javax/crypto/Cipher.html#getInstance-java.lang.String) method. Luckily, so far we will be dealing only with a single class, which will chance quickly.

**Symmetric Encryption**

```
Cipher c = Cipher.getInstance("AES/CBC/PKCS5Padding") ;
  
                        OR
 
Cipher c = Cipher.getInstance("AES/CTR/PKCS5Padding") ;
  
                        OR
 
Cipher c = Cipher.getInstance("AES/GCM/PKCS5Padding") ;
  
                        OR
 
Cipher c = Cipher.getInstance("AES/CCM/PKCS5Padding") ;
```

**Asymmetric Encryption**

```
Cipher c = Cipher.getInstance("RSA/ECB/OAEPWithSHA-1AndMGF1Padding") ;
  
                        OR
  
Cipher c = Cipher.getInstance("RSA/ECB/OAEPWithSHA-1AndMGF1Padding") ;
  
                        OR
  
Cipher c = Cipher.getInstance("RSA/ECB/OAEPWithSHA-1AndMGF1Padding") ;
  
                        OR
  
Cipher c = Cipher.getInstance("RSA/ECB/OAEPWithSHA-1AndMGF1Padding") ;
```

# Keys:

The security level of an encryption scheme is directly proportional to the size of its key. Key sizes should be long enough that brute force attacks become unfeasible, but short enough to keep computational feasibility in mind. Also, we should try to consider choices could that could still withstand computational advances for the next 30 years. With that in mind: 

**Symmetric Algorithms**

Choose the key size for AES as 256 bits. This is done to future proof your applications. **Note:** You would still need [Java Cryptography Extension (JCE) Unlimited Strength](http://www.oracle.com/technetwork/java/javase/downloads/jce8-download-2133166.html) installed to use 256-bit keys. 

If you have to choose (or stay with) a 128-bit key size (due to hardware or software limitations), it should be fine from most known attacks, as long as the rest of all the parameters are carefully configured as discussed in this post.

To implement this, the [KeyGenerator](https://docs.oracle.com/javase/8/docs/api/javax/crypto/KeyGenerator.html) class is used:

```
KeyGenerator keygen = KeyGenerator.getInstance("AES") ; // key generator to be used with AES algorithm.
keygen.init(256) ; // Key size is specified here.
byte[] key = keygen.generateKey().getEncoded();
SecretKeySpec skeySpec = new SecretKeySpec(key, "AES");
```

**Asymmetric Algorithms**

For asymmetric encryption, choose a key size of at least 2048 bits. I would encourage this purely for future-proofing your applications. Obviously, if you can afford it (from a hardware and software perspective), use at least **4096** bits key size.

The [KeyPairGenerator](https://docs.oracle.com/javase/8/docs/api/java/security/KeyPairGenerator.html) class is used to generate the key pair to be used by asymmetric algorithms:

```
KeyPairGenerator keyGen = KeyPairGenerator.getInstance("RSA");
keyGen.initialize(4096); // key size specified here.
KeyPair pair = keyGen.generateKeyPair();
```

**PBKDF2 (Password Based Key Derivation Function) and PBEWith<digest|prf>And<encryption>:** 

PBKDF2 is typically used when only user supplied passwords are used to protect or allow access to secret information, derive cryptographic keying material from sources like a passphrase. PBKDFs are computed by applying multiple iterations to a user-supplied password using a pseudorandom function (prf) and an additional salt. Here, the developer is responsible for configuring prf, iteration count and salt value. Specifications around these standards were last written in 2000<sup>[3]</sup>, and computational powers have increased since. So, I would suggest, using **SHA2** family of hash functions, a salt value of at least **64** bits, and an iteration count of atleast **10,000**. While Java providing an API to support this is a good step, there is absolute lack of documentation around how and where to use this.

PBEWith*, really is the PBKDF2 + encryption scheme (CBC mode with PKCS5Padding). Make sure you use any of the AES cipher algorithms.

To implement PBKDF2 in java:

```
// Should be as long and as many special characters as possible
String user_entered_password = sys.args[0] ;
 
// salt value
byte[] salt = new byte[128] ; // Should be atleast 64 bits
SecureRandom secRandom = new SecureRandom() ;
secRandom.nextBytes(salt) ; // self-seeded randomizer for salt
 
// iteration count
int iterCount = 12288 ;
 
int derivedKeyLength = 256 ; // Should be atleast longer than 112 bits. Depends on Key size of algorithm.
 
KeySpec spec = new PBEKeySpec(password.toCharArray(), salt, iterCount, derivedKeyLength * 8);
SecretKeyFactory f = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256");
```

To implement PBEWith<digest|prf>And<encryption></encryption></digest|prf>

```
// Generate PBEKeySpec as above
String algo = "PBEWithHmacSHA512AndAES_128" ; // Using approved Hashing algorithm and recommended block cipher
 
SecretKeyFactory skf = SecretKeyFactory.getInstance(algo);
SecretKey key = skf.generateSecret(ks);
 
// Note: there is no typical transformation string. Algorithm, mode (CBC) and padding scheme (PKCS5Padding) is all taken care by 
// PBEWithHmacSHA512AndAES_128.
Cipher c = Cipher.getInstance(algo); 
c.init(Cipher.ENCRYPT_MODE, key);
```

# Initialization Vectors:

To add to the complexity of a cipher, Initialization Vectors are used. For CTR and CBC modes of operations, we need IVs to be unpredictable and random. 

We get access to configuring IVs, by getting into transparent specification (thru [AlgorithmParameterSpecs](https://docs.oracle.com/javase/8/docs/api/java/security/spec/AlgorithmParameterSpec.html)) and using the [IvParameterSpec](https://docs.oracle.com/javase/8/docs/api/javax/crypto/spec/IvParameterSpec.html) class. One of the most important thing to keep in mind while configuring IVs is its source of randomness. Logically, there seems to be two places, where this randomness can be configured; one inside IvParameterSpec and another thru the [init](https://docs.oracle.com/javase/8/docs/api/javax/crypto/Cipher.html#init-int-java.security.Key-java.security.spec.AlgorithmParameterSpec-java.security.SecureRandom-) method in the Cipher class. Javadocs, says any randomness needed by [Cipher](https://docs.oracle.com/javase/8/docs/api/javax/crypto/Cipher.html) comes from the SecureRandom configuration in init method. It might be true for other transparent (non-developer controlled) parameter, but it's not true for IV. IV gets its randomness from the way IvParameterSpec is configured.

This would be implemented as:

```
byte iv[] = new byte[16];
 
SecureRandom secRandom = new SecureRandom() ;
secRandom.nextBytes(iv); // self-seeded randomizer to generate IV
 
IvParameterSpec randomIvSpec = new IvParameterSpec(iv) ; // IvParameterSpec initialized using its own randomizer.
 
// randomIvSpec will influence randomness of IV and not "new SecureRandom()"
c.init(Cipher.ENCRYPT_MODE, skeySpec, randomIvSpec, new SecureRandom()) ;
```

Most modes of operations also need a nonce (of key and IV pair). So make sure, that not more than a few plaintexts are encrypted with same Key/IV pair.

Full working examples of encryption schemes using Java 8 are in the ["Java_Crypto"](https://github.com/1MansiS/java_crypto) repo on github. More specifically:

* [SecuredGCMUsage.java](https://github.com/1MansiS/java_crypto/blob/master/cipher/SecuredGCMUsage.java) for AES using GCM mode
* [SecurePBKDFUsage.java](https://github.com/1MansiS/java_crypto/blob/master/cipher/SecurePBKDFUsage.java) for PBKDF2 passwords
* [SecuredRSAUsage.java](https://github.com/1MansiS/java_crypto/blob/master/cipher/SecuredRSAUsage.java) for RSA with OAEPWith<digest>And<mgf>Padding

# Conclusion: 

With enough effort, any practical cryptographic system can be attacked successfully. The real question is how much work it takes to break a system. As seen in this post, there are many details to pay attention to, and all of the details must be done correctly while designing and implementing an encryption scheme. Hopefully, this should assure us of a reasonable security level to safe-guard our crypto-systems from currently known crypto attacks, and future-proofing it too.

# tldr

* There are 2 key based encryption algorithms: Symmetric and Asymmetric algorithms.
* There are various cryptographic parameters which need to be configured correctly for a crypto-system to be secured; these include key size, mode of operation, padding scheme, IV, etc.
* For symmetric encryption use the AES algorithm. For asymmetric encryption, use the RSA algorithm.
* Use a transformation that fully specifies the algorithm name, mode and padding. Most providers default to the highly insecure ECB mode of operation, if not specified.
* Always use an authenticated mode of operation, i.e. AEAD (for example GCM or CCM) for symmetric encryption. If you have to use an unauthenticated mode, use CBC or CTR along with MAC to authenticate the ciphertext, correct random IV and padding parameters.
* Use authentication tag with at least 128 bits length in AEAD modes.
* Make sure to use OAEPWith<digest>And<mgf>Padding for asymmetric encryption, where the digest is SHA1/SHA256/384/512. Use PKCS5Padding for symmetric encryption.
* If using PDKDF for key generation or Password Based Encryption (PBE), make sure to use SHA2 algorithms, a salt value of at least 64 bits and iteration count of 10,000. 
* Key sizes: use AES 256 if you can, else 128 is secure enough for time being. For RSA use at least 2048, consider 4096 or longer for future proofing.
* There is a limit on how much plaintext can be safely encrypted using a single (key/IV) pair in CBC and CTR modes. 
* The randomness source of an IV comes from the IvParameterSpec class and not from init methods of the Cipher class.

# References:

1. Java Cryptography Architecture Standard Algorithm Name Documentation for JDK 8: https://docs.oracle.com/javase/8/docs/technotes/guides/security/StandardNames.html
2. Java Cryptography Architecture (JCA) Reference: https://docs.oracle.com/javase/8/docs/technotes/guides/security/crypto/CryptoSpec.html
3. RFC 2898 : Password-Based Cryptography Specification Version 2.0 https://www.ietf.org/rfc/rfc2898.txt
4. NIST SP 800-132 Recommendation for Password Based Key Derivation: http://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-132.pdf
5. Side-Channel Attacks on Symmetric Encryption Schemes: The Case for authenticated Encryption - https://www.cs.colorado.edu/~jrblack/papers/padding.pdf
6. Chosen Cipher Text Attacks against protocols, based on the RSA Encryption Standard PKCS #1: http://archiv.infsec.ethz.ch/education/fs08/secsem/Bleichenbacher98.pdf
7. Cryptography Engineering - Niels Ferguson, Bruce Schneider and Tadayoshi Kohno.
8. RFC 3447: Public-Key Cryptography (PKCS) #1: RSA Cryptography Specification Version 2.1: https://www.ietf.org/rfc/rfc3447.txt
9. Understanding Cryptography - Christof Paar and Jan Pelzi
10. AES Lounge: http://www.iaik.tugraz.at/content/research/krypto/aes/#security
11. NIST SP 800-131AR1: Transitions: Recommendation for Transitioning the Use of Cryptographic Algorithms and Key Lengths: http://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-131Ar1.pdf
12. NIST SP 800-38A: Recommendation for Block Cipher Modes of Operation, Methods and Techniques: http://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-38a.pdf
13. Agilebits Blog: Guess why we're moving to 256-bits AES keys: https://blog.agilebits.com/2013/03/09/guess-why-were-moving-to-256-bit-aes-keys/
14. http://www.oracle.com/technetwork/java/javase/downloads/jce8-download-2133166.html
15. The Galois/Counter Mode of Operation: http://csrc.nist.gov/groups/ST/toolkit/BCM/documents/proposedmodes/gcm/gcm-spec.pdf
16. OWASP Key Management Cheatsheet: https://www.owasp.org/index.php/Key_Management_Cheat_Sheet
17. OWASP Cryptographic Storage Cheatsheet: https://www.owasp.org/index.php/Cryptographic_Storage_Cheat_Sheet
18. Cryptosense - Java Cryptography White Paper