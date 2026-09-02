import Hash.Sha256
import Hash.Sha3
import Hash.Algorithm

/-!
# `Hash` — proved hash functions in Lean 4

The public root of the `Hash` library. A consumer imports this module and
nothing else.

`Hash.Sha256` carries SHA-256 and SHA-224 from FIPS 180-4, moved from
`lean4-WHATWG-streams` at `a1383bc`. `Hash.Sha3` carries SHA3-512 from FIPS
202, moved from foldlab's `formal/fips202` at `64be4b2c`. The
algorithm-indexed surface over both arrives at S4.

Ruling HP-2 is in force: each family keeps its own `Digest` and `Hex`, so
`Hash.Sha256.Digest 32` and `Hash.Sha3.Digest 64` are different types with
the same shape. Unifying them is a later step and is not done silently.

The known-answer tests and the per-family axiom audits stay out of this
closure and are reached only through `Hash.Verified`, so a consumer never
elaborates them.
-/
