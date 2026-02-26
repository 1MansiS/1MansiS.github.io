---
layout: post
title:  "Java Crypto Libraries Go Modular"
date:   2018-10-05
tags: [Java Cryptography]
---
Original post was published on Veracode blog [here](https://www.veracode.com/blog/secure-development/java-crypto-libraries-go-modular)

To complement my recent Java Crypto blog series (["How to get Started Using Java Cryptography Securely"](https://1mansis.github.io/2017/03/17/How_to_Get_Started_Using_Java_Cryptography_Securely.html), ["Cryptographically Secure Pseudo-Random Number Generator (CSPRNG)"](https://1mansis.github.io/2017/03/29/Cryptographically_Secure_Pseudo-Random_Number_Generator.html), ["Encryption and Decryption in Java Cryptography"](https://1mansis.github.io/2017/04/18/Encryption_and_Decryption_in_Java_Cryptography.html), ["Message Digests, aka Hashing Functions"](https://1mansis.github.io/2017/06/13/Message_Digests_aka_Hashing_Functions.html)), I have been referencing corresponding working code on the [GitHub repository](https://github.com/1MansiS/java_crypto).

I am happy to announce a brand-new, shiny, modularized, micro-serviced, and dockerized version of this monolithic secure Java crypto code base.

The benefits of re-architecting monolithic applications into [microservices](https://www.veracode.com/node/27661) and employing modular programming is well understood and supported. With more and more organizations embracing DevOps principles, development organizations are overwhelmed with growing responsibilities. In this situation, security is often not a top priority. But with the growing popularity of DevSecOps, there is increasing motivation to incorporate security into DevOps pipelines. However, there seems to be a lack of modular security libraries filling this gap. 

In an effort to support these modern principles and methodologies, I re-architected my [monolithic](https://github.com/1MansiS/java_crypto) Java Crypto library into easily-injectable modules on my [Java Crypto repository](https://github.com/1MansiS/JavaCrypto) on Github. This repository has:

1.  [SecureJavaCrypto](https://github.com/1MansiS/JavaCrypto/tree/main/JavaCryptoModule): Module that provides all cryptography primitives as an API, in a secure way, through Java, mainly using Java Cryptography Architecture (JCA). Out of box, this provides APIs for:
	* Generating a cryptographically secure pseudo random number, in an OS agnostic way
	* Encryption and decryption
	* Calculating message digests
	* Calculating message authentication codes
	* Signing and verifying digital signatures
	* Secured password storage
2. [SecureMicroService](https://github.com/1MansiS/JavaCrypto/tree/main/SecureCryptoMicroservice), which represents typical use cases on how to use the above module, trying to mimic a service (for example, Lamba, microservice etc). 
3.  [Dockerfile](https://github.com/1MansiS/JavaCrypto/blob/main/Dockerfile), for easy containerization.
4. [docker hub](https://hub.docker.com/r/1mansis/javacrypto/), for experimenting with the above modules/microservices. Also eases deployment of code into production through your CI/CD pipeline.

For details on API use, please refer to [README](https://github.com/1MansiS/JavaCrypto/blob/main/ReadMe.md). As per your architecture, you can choose to pick just the core crypto module (1), or SecureMicroservice (2) as well, or the entire docker container (4).

Happy Java Cryptographying!!!

# References

1. Secure Crypto Module: https://github.com/1MansiS/JavaCrypto/tree/main/JavaCryptoModule
2. Secure Crypto Microservice: https://github.com/1MansiS/JavaCrypto/tree/main/SecureCryptoMicroservice
3. Docker Hub Image: https://hub.docker.com/r/1mansis/javacrypto/
4. Monolithic Older version: https://github.com/1MansiS/java_crypto