# 36 — TLS/crypto posture tightened

| | |
|---|---|
| **Category** | Environment, distribution & build toolchain |
| **Introduced** | ⚠ Cumulative across releases — no single JEP; enforced via `jdk.tls.disabledAlgorithms` and related security properties, updated nearly every release |
| **Symptom** | TLS 1.0/1.1 disabled by default; SHA-1-signed JARs treated as unsigned; default keystore type JKS → PKCS12 (JDK 9); connections to legacy endpoints fail with `SSLHandshakeException` |
| **Detect** | Integration-test against every external and legacy internal endpoint; audit keystores and signed JARs |
| **Fix** | Upgrade the endpoint's TLS config; re-sign JARs with SHA-256+; migrate keystores to PKCS12 explicitly. |
| **Not in the deck.** |

## What this test does — and why it only asserts on one sub-claim

This item bundles several sub-claims of very different character. This test
verifies the one that's a clean, version-pinned, deterministic default:
`KeyStore.getDefaultType()` — JKS on JDK 8, PKCS12 on JDK 25 (since JDK 9).

The `jdk.tls.disabledAlgorithms` security property is printed for comparison but
**not asserted on**, for a reason worth recording: this sandbox's JDK 8 build
(a current Temurin 8u502 patch) *already* disables `TLSv1`/`TLSv1.1` by default
— that hardening gets backported into ongoing JDK 8 security patches too, not
just introduced fresh in later majors. "JDK 8 allows weak TLS, JDK 25 doesn't"
depends on exactly which **patch level** of JDK 8 a team is running, not just
the major version — an old, long-unpatched JDK 8u install would show a starker
contrast than a freshly-downloaded one does. Worth keeping in mind before citing
a specific before/after on stage: the "before" side of this particular claim is
a moving target.

## Verified output (sandbox, Temurin 8u502 / Temurin 25.0.4)

```
Default keystore type:
  JDK 8:  keystore.type = jks
  JDK 25: keystore.type = pkcs12

jdk.tls.disabledAlgorithms (informational only, not asserted on):
  JDK 8:  SSLv3, TLSv1, TLSv1.1, RC4, DES, MD5withRSA, DH keySize < 1024, EC keySize < 224, 3DES_EDE_CBC, anon, NULL, ECDH, include jdk.disabled.namedCurves
  JDK 25: SSLv3, TLSv1, TLSv1.1, DTLSv1.0, RC4, DES, MD5withRSA, DH keySize < 1024, EC keySize < 224, 3DES_EDE_CBC, anon, NULL, ECDH, TLS_RSA_*, rsa_pkcs1_sha1 usage HandshakeSignature, ecdsa_sha1 usage HandshakeSignature, dsa_sha1 usage HandshakeSignature
```

Note both lists already disable `TLSv1`/`TLSv1.1` — the JDK 25 list is longer
(covers DTLS and specific handshake-signature algorithms JDK 8 never had),
but it's an extension of an already-hardened JDK 8 baseline in this sandbox,
not a stark "before" vs. "after."
