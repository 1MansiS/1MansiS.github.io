---
layout: post
title:  "How to Get Started Using Java Cryptography Securely"
date:   2017-03-17T20:20:46.000Z
tags: java_crypto
---

Skip to the [tl;dr](#tldr)

Cryptography is the backbone of today's information systems. Its applications are all around us: secure email communications, storage of our login credentials, digital cash and mobile payments, to name just a few. Cryptography is one of the most complicated topics in information security, but the good news is we already have well-defined algorithms, implementations and protocols available to us. To ensure the security of a crypto-system while designing it, it’s extremely important to use these pieces with utmost precision.

Please note that the use of cryptography does not solve every security problem. You still need to safeguard your application against numerous other threats, such as injection attacks, exploitation of authentication controls and path manipulation attacks, for example. (You can get details of these types of attacks along with remediation advice on the [OWASP](https://www.owasp.org/index.php) site.

There are a few open source, security-focused libraries that you can use to introduce some of these security controls into your application<sup>[6]</sup><sup>[7]</sup>. Do not be tempted to implement your own homegrown libraries if you can leverage one of these libraries, as these have already been vetted for security. Modern frameworks also provide some security controls; make sure to use them. Lastly, never implement your own cryptography libraries. There are just too many pitfalls. Most modern languages have implemented crypto-libraries and modules, so choose one based on your application’s language. There are some third-party libraries that can be used to build higher-level tools. One of our favorites is [NaCl](https://nacl.cr.yp.to/).

# Don’t Just Get it Working, Use it Securely: What to Expect in This Blog Series

A few months ago, I was researching all possible misconfigurations/misuses of the [Java Cryptography Architecture (JCA)](https://docs.oracle.com/javase/8/docs/technotes/guides/security/crypto/CryptoSpec.html). I must confess, it was a horrendous process. To begin with, there were no recent books, blogs or practical resources on using cryptography in Java, let alone resources that were security focused. The JCA Reference guide is, in all fairness, exhaustive; however, it is focused more on the Architect or Developer roles, and is more oriented toward getting it working than how to use it securely. System implementers and cryptographers should work in concert while designing any cryptographic system. However, this is seldom the case, which makes having a security-focused JCA resource indispensable. This will be the primary aim of this blog series, with blog posts every two weeks on various basics of cryptography.

This blog series should serve as a one-stop resource for anyone who needs to implement a crypto-system in Java. My goal is for it to be a complimentary, security-focused addition to the JCA Reference Guide. Each post will be dedicated to various aspect of cryptography, such as:

### ToDo: Add links to actual markdowns below
* Cryptographically Secure Random Number Generators 
* Encryption and Decryption
* Message Digest
* HMAC

Most of the pitfalls from the Java side can be categorized as follows, which I will try to discuss in this series:

* Ambiguous documentation, followed with examples that are not necessarily the most secure usage.
* Over-abundance of choices, with the majority of them insecure or deprecated options. * Java, in its drive to support legacy options, provides an overwhelmingly large number of options, making it difficult to discern which choices are secure or insecure.
* Insecure defaults out of the box.
* Poor architectural designs.

I will strive to ensure that each blog post will:

* Point out areas that require careful attention.
* Supplement my claims with examples of misleading/ambiguous documentation.
* Provide code examples of some of anti-patterns found on famous Internet sources, like stack overflow and github. This is to help avoid CPV (copy-paste vulnerabilities). 
* Provide code examples of the secure way to achieve your goal.
* Help to make the correct choices from all of those that are provided.

Lastly, each post will maintain a "Lessons Learned" checklist, summarized in a conclusion entry.

There is a trove of resources and books written on this topic; some of my favorites are listed in the references below. Thus, I don't plan to touch upon those that are already covered. This series also assumes a basic understanding of cryptography and some experience with Java.

This blog series is based on Java 8. However, most of it should be translatable for older versions as well. I will try to point out version discrepancies.

Lastly, I don't claim to know it all. With limited time, but comparatively a lot more time, motivation and perspective than most developers, I hope this will be a helpful reference with which we all learn along the way. 


Starting with some of the basics:

# Architectural Details

The JCA (Java Cryptography Architecture) was built around provider architecture. JCA defines and supports a set of APIs for cryptographic services, included in packages [java.security](https://docs.oracle.com/javase/8/docs/api/java/security/package-summary.html), [javax.crypto](https://docs.oracle.com/javase/8/docs/api/javax/crypto/package-summary.html), [javax.crypto.spec](https://docs.oracle.com/javase/8/docs/api/javax/crypto/spec/package-summary.html), and [javax.crypto.interfaces](https://docs.oracle.com/javase/8/docs/api/javax/crypto/interfaces/package-summary.html). The providers that ship with JDK, such as Sun, SunJCE, SunRsaSign, supply the actual implementations for these APIs. The [Oracle Providers Documentation](https://docs.oracle.com/javase/8/docs/technotes/guides/security/SunProviders.html) describes technical details of these providers. There are many third-party providers as well, such as [bouncy castle](https://www.bouncycastle.org/java.html) and [IBMJCE](https://www.ibm.com/support/knowledgecenter/SSYKE2_7.1.0/com.ibm.java.security.component.71.doc/security-component/JceDocs/installingproviders.html), but we won't be focusing on those for the time being.

Providers are listed in order of potential requests by developer code. This is configured in the security configuration file java.security under your `$JAVA_HOME/Contents/Home/jre/lib/security/` location. If a specific implementation is requested (by explicitly specifying it through API, for example), it would be served based on this preference order. When a default API is being used (something like new SecureRandom()), based on OS (and additional parameters you will see later), implementation is served based on this provider preference order.

If you plan to use one of the external providers, you would need to explicitly install it as per the ["Install Providers"](https://docs.oracle.com/javase/8/docs/technotes/guides/security/crypto/CryptoSpec.html#ProviderInstalling) section in JCA. Make sure that you are registering a provider in the java.security configuration file, in the required order of priority, and not using the [Security.addProvider()](https://docs.oracle.com/javase/8/docs/api/java/security/Security.html#addProvider-java.security.Provider-). This method adds the provider to the end of the list, so future references to the default provider would most likely never invoke the provider you registered.

# Unlimited Strength Jurisdiction Policy

If you need to use the AES algorithm with a key size larger than 128 bits (as I would recommend), you will need to explicitly install Unlimited Strength Jurisdiction Policy. The default JRE ships with limited strength cryptography. Installation instructions can be found in the README.txt file inside the policy .jar file. This is annoying, considering that they are external .jar files, which we would need to explicitly download and configure for each JRE version upgrade. This situation is mainly due to certain countries' import restrictions, which forbid software using flexible-strength cryptographic algorithms. Countries outside the USA have particular laws regarding unlimited-strength cryptographic algorithms. So, if you fall into that category, you may wish to use default limited strength.

There are many ways to compromise a crypto-system. If you have chosen all cryptographic parameters correctly (algorithm, mode, padding, IV etc.), and a limited key size of 128, you might be safe for now, but still may not be future-proofed. We will discuss this in a future dedicated post on encryption/decryption algorithms.

# Debugging

According to Oracle, if you need to troubleshoot anything related to security, you can use the java.security.debug System property, which contains various options. Details can be found on [this](https://docs.oracle.com/javase/8/docs/technotes/guides/security/troubleshooting-security.html) page.

So far, the biggest uses I've found are in each provider's implementation parameters. A typical way to use it would be:

```
java -Djava.security.debug="provider=SUN" SecuredRSAUsage "Hello"
```

**Output:**

```
provider: NativePRNG egdUrl: file:/
provider: NativePRNG.MIXED seedFile: / nextFile: /dev/urandom
Provider: Set SUN provider property [SecureRandom.SHA1PRNG/sun.security.provider.SecureRandom]
provider: NativePRNG.BLOCKING seedFile: /dev/random nextFile: /dev/random
Provider: Set SUN provider property [SecureRandom.NativePRNGBlocking/sun.security.provider.NativePRNG$Blocking]
provider: NativePRNG.NONBLOCKING seedFile: /dev/urandom nextFile: /dev/urandom
Provider: Set SUN provider property [SecureRandom.NativePRNGNonBlocking/sun.security.provider.NativePRNG$NonBlocking]
Provider: Set SUN provider property [Signature.SHA1withDSA/sun.security.provider.DSA$SHA1withDSA]
Provider: Set SUN provider property [Signature.NONEwithDSA/sun.security.provider.DSA$RawDSA]
Provider: Set SUN provider property [Alg.Alias.Signature.RawDSA/NONEwithDSA]
Provider: Set SUN provider property [Signature.SHA224withDSA/sun.security.provider.DSA$SHA224withDSA]
Provider: Set SUN provider property [Signature.SHA256withDSA/sun.security.provider.DSA$SHA256withDSA]
Provider: Set SUN provider property [Signature.SHA1withDSA SupportedKeyClasses/java.security.interfaces.DSAPublicKey|java.security.interfaces.DSAPrivateKey]
Provider: Set SUN provider property [Signature.NONEwithDSA SupportedKeyClasses/java.security.interfaces.DSAPublicKey|java.security.interfaces.DSAPrivateKey]
Provider: Set SUN provider property [Signature.SHA224withDSA SupportedKeyClasses/java.security.interfaces.DSAPublicKey|java.security.interfaces.DSAPrivateKey]
Provider: Set SUN provider property [Signature.SHA256withDSA SupportedKeyClasses/java.security.interfaces.DSAPublicKey|java.security.interfaces.DSAPrivateKey]
.
.
.
```

# tldr

* Cryptography is not the solution to all security problems. 
* You still need to perform data validation, encoding, authentication, authorizations, etc. to safeguard against various categories of attacks. 
* Don't write your own security libraries. Use well-vetted security libraries or framework-specific security options.
* Never, ever write your own cryptography libraries. If cryptography is implemented incorrectly, it renders the system completely insecure.
* For registering a new provider, make sure to add to the java.security file in order of required priority. Using Security.addProvider will add a provider towards the end of the list, which might not be invoked when using a default provider.
* Explicitly install [Unlimited Strength Jurisdiction Policy](https://www.oracle.com/technetwork/java/javase/downloads/jce8-download-2133166.html) to support 256-bit AES encryption.
* Security troubleshooting using java.security.debug System property comes in handy.

# References

1. Applied Cryptography - Bruce Schneier: https://www.amazon.com/gp/product/1119096723
2. Code Book - Simon Singh: https://www.amazon.com/Code-Book-Science-Secrecy-Cryptography/dp/0385495323
3. Course Notes of Introduction to Modern Cryptography - Mihir Bellare: cseweb.ucsd.edu/ ~mihir/cse207/classnotes.html
4. Stanford Coursera Course - Cryptography: https://www.coursera.org/learn/crypto
5. CryptoAnalysis Challenges: https://cryptopals.com
6. OWASP-ESAPI : https://www.owasp.org/index.php/ESAPI
7. Java Encoder Project: https://www.owasp.org/index.php/OWASP_Java_Encoder_Project

