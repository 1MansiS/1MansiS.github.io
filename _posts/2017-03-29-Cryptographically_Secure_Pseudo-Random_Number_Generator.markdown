---
layout: post
title:  "Cryptographically Secure Pseudo-Random Number Generator (CSPRNG)"
date:   2017-03-29
tags: java_crypto
---

Original post was published on veracode blog [here](https://www.veracode.com/blog/research/cryptographically-secure-pseudo-random-number-generator-csprng)

Skip to the [tl;dr](#tldr)

This is the second entry in a blog series on using Java cryptography securely. The [first entry](https://1mansis.github.io/2017/03/17/How_to_Get_Started_Using_Java_Cryptography_Securely.html) provided an overview and covered some architectural details, using stronger algorithms and some debugging tips . This entry covers Cryptographically Secure Pseudo-Random Number Generators. This blog series should serve as a one-stop resource for anyone who needs to implement a crypto-system in Java. My goal is for it to be a complimentary, security-focused addition to the [JCA Reference Guide](https://docs.oracle.com/javase/8/docs/technotes/guides/security/crypto/CryptoSpec.html). 

There are various steps in cryptography that call for the use of random numbers. Generating a nonce, initialization vector or cryptographic keying materials all require a random number. The security of basic cryptographic elements largely depends on the underlying random number generator (RNG) that was used. An RNG that is suitable for cryptographic usage is called a Cryptographically Secure Pseudo-Random Number Generator (CSPRNG). The strength of a cryptographic system depends heavily on the properties of these CSPRNGs. Depending on how the generated pseudo-random data is applied, a CSPRNG might need to exhibit some (or all) of these properties:

* It appears random
* Its value is unpredictable in advance
* It cannot be reliably reproduced after generation

In Java 8, the [SecureRandom](https://docs.oracle.com/javase/8/docs/api/java/security/SecureRandom.html) class provides CSPRNG functionality. The most OS-agnostic way to generate pseudo-random data that is suitable for general cryptographic use is to rely on the OS implementation's defaults, and never to explicitly seed it (i.e., don't use the setSeed method before a call to next* methods). This is done as below:

```
//returns an unseeded instance of default RNG algorithm based on most preferred provider from list of providers configured in java.security
// On Unix like system, NativePRNG algorithm, configured with seeding from non-blocking entropy source, is returned.
// On Windows, SHA1PRNG algorithm, which can be self-seeded or explicitly seeded is returned.
SecureRandom secRan = new SecureRandom(); 
byte[] ranBytes = new bytes[20];
secRan.nextBytes(ranBytes); // since, there is no setSeed method called before a call to next* method, self-seeding occurs
```

Note: This recommendation has the additional advantage of keeping code portable across operating systems, and will provide a secure randomizer if self-seeded. If you want complete assurance of randomness for a given operating system, I would suggest explicitly using the `Windows-PRNG` algorithm for Windows environments (using the getInstance method) and `NativePRNG` for Unix-like environments. Note that these options carry the downside of making code not easily portable. This is explained in detail later in this post.

On Windows, the default implementation will return the SHA1PRNG algorithm (assuming default configuration of java.security). If explicitly seeded, this provides randomness, directly proportional to the source of entropy provided by the initial seeding. It's most secure to rely on upon OS-specific implementations to provide seeding. Providing a low-entropy predictable source could easily lead to generating predictable pseudo-random data, which is inappropriate for any cryptographic applications.

The following are **anti-patterns** on a Windows OS and should be strictly avoided:

```
// ANTI-PATTERN, do not copy-paste
// On windows, default constructor would pick SHA1PRNG algorithm.
SecureRandom random1 = new SecureRandom() ; // unseeded random object
random1.setSeed(System.currentTimeMillis() % 1000); // seeding explicitly before next* methods, using low entropy source of seeding
random1.nextBytes(new byte[20]);
  
 
byte[] b = "123".getBytes() ;
SecureRandom random2 = new SecureRandom(b) ; // seeding with a static byte array
  
  
SecureRandom random4 = SecureRandom.getInstance("SHA1PRNG") ;
random4.setSeed(123); // SHA1PRNG should never be initially  explicitly seeded.
```

On a Unix-like OS, the following are **anti-patterns** and should be strictly avoided:

```
// ANTI-PATTERN, do not copy-paste
// Explicitly requesting SHA1PRNG and not relying on default implementation chosen
SecureRandom secRan = SecureRandom.getInstance("SHA1PRNG") ;
secRan.setSeed(12345) ; // explicitly seeding SHA1PRNG algorithm.
```

As a developer, you should be aware of what is going on behind the scenes and make sure your applications always generate cryptographically secure random numbers, regardless of other aspects like OS dependencies, default configurations (in java.security files) and seeding sources. So, while designing any CSPRNG, remember the following:

# Don't ever use Math.random

There is nothing random about [Math.random](https://docs.oracle.com/javase/8/docs/api/java/lang/Math.html#random--). It doesn't provide cryptographically secure random numbers. It generates random values deterministically, but its output is still considered vastly insecure. Want to see for yourself? This blog post<sup>[3]<sup>, explains how simple it is to crack the linear congruential PRNG from which Math.random derives.

# Sources of entropy

A real-world CSPRNG is composed of three things: 1) a CSPRNG algorithm (such as NativePRNG, Windows-PRNG, SHA1PRNG, etc.), 2) a source of randomness, at least during initial seeding and 3) a pseudo-random output. The task of generating a pseudo-random output from a predictable seed using a given algorithm is fairly straightforward. All of the algorithms provided by the Java providers are cryptographically secure<sup>[6]</sup> too. Thus, the strength of a CSPRNG is directly proportional to the source of entropy used for seeding it (and re-seeding it). We can safely conclude that the security of a crypto-system depends on configuring the highest level of entropy for seeding a CSPRNG algorithm.

The most practical, unpredictable and nearly computationally continuous source of randomness is attained by letting the underlying operating system pool random events into a system file, which can then be used for seeding. In Unix-like systems, the `file://dev/random` and `file://dev/urandom` files are continuously updated with random external OS-dependent events.

In most operating systems, the entropy pool used for seeding a randomizer comes in one of these two forms:

* **Blocking:** blocks your application until it finds sufficient entropy in its entropy pool. In Unix-like systems, this comes from `file://dev/random`
* **Non-Blocking:**  doesn't block the application, and works with whatever is available in your OS's entropy pool. In Unix-like systems, it comes from `file://dev/urandom`

Cryptographers tends to be pessimistic about their entropy sources but for most purposes using a non-blocking source of entropy seeding should suffice<sup>[8]</sup>. All providers and algorithms the Java provides are cryptographically secured<sup>[5]</sup><sup>[6]</sup> as long as they are initially seeded with the highest-entropy source possible. The recommended code sample above takes care of this by providing a default implementation that is seeded from a non-blocking entropy pool. 

However, if you need to use these numbers in an application that requires the absolute highest level of entropy or to avoid a security code review argument, you might need to make some precise configurations. 

There are a few ways that you can choose between these two pools in your application: 

* Configuring the `securerandom.source` (default is /dev/urandom) property in the `java.security` config file.

```
#Chosen algorithm would be seeded with a blocking entropy pool
securerandom.source=file:/dev/random
  
or
  
#Chosen algorithm would be seeded with a non-blocking entropy pool
securerandom.source=file:/dev/urandom
```

* Passing the System property `java.security.egd` to your application's command line.

```
#Blocking entropy pool would be used by SecureRandom in MainClass
% java -Djava.security.egd=file:/dev/random MainClass
  
or
  
#Non-Blocking entropy pool would be used by SecureRandom in MainClass
% java -Djava.security.egd=file:/dev/urandom MainClass
```

* Using the [SecureRandom.getInstance(algo)](https://docs.oracle.com/javase/8/docs/api/java/security/SecureRandom.html#getInstance-java.lang.String-) method and explicitly specifying an algorithm. In Unix-like OSes, `NativePRNG` and `NativePRNGNonBlocking` algorithms are seeded with non-blocking entropy pools, and the `NativePRNGBlocking` algorithm is seeded with a blocking source of entropy.

```
// On Unix like OS, NativePRNG algorithm, is being returned, which is self-seeded with non-blocking (file://dev/urandom) source of entropy.
SecureRandom nativePrng = SecureRandom.getInstance("NativePRNG");
  
or
  
// On Unix like OS, NativePRNGBlocking algorithm, is being returned, which is self-seeded with blocking (file://dev/random) source of entropy.
SecureRandom nativePrngNon = SecureRandom.getInstance("NativePRNGBlocking");
```

* [SecureRandom.getInstanceStrong](https://docs.oracle.com/javase/8/docs/api/java/security/SecureRandom.html#getInstanceStrong) method (available since Java 8). When this method is used, it picks up the algorithm or algorithm/provider configuration in `securerandom.strongAlgorithms` java.security config. By default, it is configured to use non-blocking.

```
// Algorithm used, is based on what is configured in securerandom.strongAlgorithms property of java.security config file. By default it's configured to use blocking algorithm.
SecureRandom strongRNG = SecureRandom.getInstanceStrong() ;
```

On Unix-like system, securerandom.strongAlgorithm is configured as:

```
#This is a comma-separated list of algorithm and/or algorithm:provider entries.
securerandom.strongAlgorithms=NativePRNGBlocking:SUN
```

This means that `SecureRandom.getInstanceStrong` will return a `NativePRNGBlocking` implementation provided by SUN provider.

# SecureRandom randomizer should always be self-seeded

In Java, the [SecureRandom](https://docs.oracle.com/javase/8/docs/api/java/security/SecureRandom.html) class provides the functionality of a CSPRNG. You can request the default implementation by using its constructor, or ask for a specific algorithm by using its getInstance method. The CSPRNG algorithm chosen and how this algorithm is seeded vary between different operating systems and selected implementations, which are in turn based on the provider order in java.security configuration files. To give you an idea of how complicated this gets, refer to the [CheckSecureRandomConfig.java](https://github.com/1MansiS/java_crypto/blob/master/securerandom/CheckSecureRandomConfig.java) program, which lists observations of various permutations and combinations, all of which play an important role in the strength of your randomizer.

We can see from [CheckSecureRandomConfig.java](https://github.com/1MansiS/java_crypto/blob/master/securerandom/CheckSecureRandomConfig.java) that regardless of which approach you take (constructor or getInstance method), the randomizer object returned will be seeded by the configured securerandom.source in the java.security configuration file, and this source is considered safe. However, there is an exception to this rule. While using SHA1PRNG and explicitly seeding the randomizer object initially, the randomness of the pseudo-random data generated is directly proportional to the explicit source of entropy. On Unix-like operating systems, default implementations, securerandom.source value and provider order will give us self-seeded randomizer objects using the NativePRNG algorithm, which is perfectly safe. However, while on Windows, the default implementation returned is always SHA1PRNG. If it's explicitly seeded, it's dangerously un-random. Thus, on Windows, explicitly ask for the Windows-PRNG algorithm. No matter what, stay away from poorly documented SHA1PRNG algorithms.

Java provides an option for explicitly seeding a secure randomizer. It's used mainly when you need to re-seed a randomizer object (to supplement existing seeding), but never for initial seeding. There are various situations in which a re-seeding is mandatory, for example, generating nonces, Initialization Vectors (IVs) and so on.

On Windows, the most secure way to create a randomizer object would be:

```
SecureRandom secRan = SecureRandom.getInstance("Windows-PRNG") ; // Default constructor would have returned insecure SHA1PRNG algorithm, so make an explicit call.
byte[] b = new byte[NO_OF_RANDOM_BYTES] ;
secRan.nextBytes(b);
```

On Unix-like systems, the most secure way would be:

```
SecureRandom secRan = new SecureRandom() ; // In Unix like systems, default constructor uses NativePRNG, seeded by securerandom.source property
byte[] b = new byte[NO_OF_RANDOM_BYTES] ;
secRan.nextBytes(b);
```

Due to OS dependencies, differences in the way that operating systems gather randomness, and obviously the importance of using the correct entropy source in a CSPRNG algorithm, I would highly encourage everyone to run [CheckSecureRandomConfig.java](https://github.com/1MansiS/java_crypto/blob/master/securerandom/CheckSecureRandomConfig.java) on your target systems. This can double-check the algorithm used, and how the randomizer is seeded (`file:/dev/urandom` or `file:/dev/random` if needed). Run this code a few times to make sure that the same data is not generated across multiple calls (as would occur with a static explicit seeding). Such output would immediately prove a low entropy source for pseudo-random data.

I only wish that Java would have taken some responsibility for security, as [python](https://docs.python.org/2.7/library/xml.html#module-xml) does at the start of its modules, and alert its users.

A recent incident that illustrates how using a weak random number generator could compromise the security of a system is the attack against the Hacker News website. The attack is explained [here](https://blog.cloudflare.com/why-randomness-matters/),with precise technical details described [here](https://news.ycombinator.com/item?id=639976). To summarize; account thefts on this site took place due to the use of a CSPRNG seeded with time in milliseconds, a week entropy source.

This [SecureRandomAPI](https://github.com/1MansiS/JavaCrypto/blob/c6b11827bb43bf1815c2b6a89575a49a4412ca66/JavaCryptoModule/SecureJavaCrypto/src/main/java/com/secure/crypto/secure_random/SecureRandomAPI.java) code example shows how to use SecureRandom in the most secure manner for generating an Initialization Vector.

# Note on impacts of virtualization on sources of randomness:

In a virtual environment, the entropy pool is being shared between different instances. Situations have been observed<sup>[7]</sup> in which the co-existence and sharing of entropy pools leads to problems. In the case of a non-blocking pool, the pool can be drained out, leading to low entropy. For blocking pools, if all VM instances are started at the same time, they can block each other, effectively leading to a Denial of Service conditions or at best, longer start times. Such scenarios are observed by bitcoin miners, and AWS tomcat users as well. This situation might become more acute when full snapshots are taken that also clone the randomness pool. It adds to the problem of low entropy, since a virtual machine has limited hardware sources into an OS' randomness pool (for example, no keyboard, mouse, etc.). Currently, however there are no widely popular solutions to such behaviors, and I would recommend continuing with my suggestion above. This should still provide you with computationally secure randomness. Just keep in mind that if you observe this behavior in your applications, you can troubleshoot this further.

# tldr

* To keep code portable, use OS defaults with OS-specific self-seeding. On Windows, explicitly seeding could lead to dangerously predictable data.
* Don't ever use Math.random for any cryptographic needs.
* Use non-blocking sources of entropy seeding over blocking, unless you're absolutely sure that your application needs the highest level of entropy.
* Never, ever explicitly seed a SHA1PRNG algorithm. In Windows, SHA1PRNG is the default implementation used.
* The preferred algorithms on Windows and Unix-like OSes are, respectively, "Windows-PRNG" and "NativePRNG".
* Always double-check your randomizer configurations. The most important details are the algorithm used, the seeding source for the algorithm, the way the algorithm is seeded (i.e., self-seeded or explicitly seeded) and whether the output generated is sufficiently random.
* In virtualized environments circumstances can lead to low entropy for non-blocking pools of entropy and delayed starts or deadlock for blocking pools of entropy. 

# References

1. Java SecureRandom updates as of April 2016: https://www.cigital.com/blog/proper-use-of-javas-securerandom/
2. CSPRNG Wikipedia: https://en.wikipedia.org/wiki/Cryptographically_secure_pseudorandom_number_generator
3. Cracking Random Number Generators - James Roper https://jazzy.id.au/2010/09/20/cracking_random_number_generators_part_1.html
4. Use /dev/urandom for CSPRNG seeding http://sockpuppet.org/blog/2014/02/25/safely-generate-random-numbers/
5. NIST Recommendation for Random Bit Generator Constructions : https://csrc.nist.gov/CSRC/media/Publications/sp/800-90c/draft/documents/sp800_90c_second_draft.pdf
6. Challenges with Randomness In Multi-tenant Linux container platforms: https://content.pivotal.io/blog/challenges-with-randomness-in-multi-tenant-linux-container-platforms
7. Professor D.J.Bernstein comments on /dev/random vs /dev/urandom arguments: https://gist.github.com/tarcieri/6347417