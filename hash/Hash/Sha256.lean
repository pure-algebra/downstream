import Hash.Sha256.Spec
import Hash.Sha256.Impl
import Hash.Sha256.Lengths
import Hash.Sha256.Bridge
import Hash.Sha256.Hex
import Hash.Sha256.Digest
import Hash.Sha256.Fast
import Hash.Sha256.Api
import Hash.Sha256.Context
import Hash.Sha256.Sha224

/-!
# `Hash.Sha256` — SHA-256 and SHA-224 from FIPS 180-4

The public root of the `Hash.Sha256` library. A consumer imports this module and
nothing else.

`docs/SHA256-DAG.md` §5.1 fixes what this root imports: `Hash.Sha256.Spec`,
`Hash.Sha256.Impl`, `Hash.Sha256.Lengths`, `Hash.Sha256.Bridge`, `Hash.Sha256.Hex`,
`Hash.Sha256.Digest`, `Hash.Sha256.Api`, and `Hash.Sha256.Fast`, plus the two modules §5.1's
layout adds after S1.4, `Hash.Sha256.Context` (A1.S5, incremental hashing) and
`Hash.Sha256.Sha224` (A1.S6). The known-answer tests and the axiom audit stay out of
this closure and are reached only through `Hash.Sha256.Verified`, so a consumer
never pays for them.

The axiom ceiling of every `Hash.Sha256.*` module is the repository's semantic
ceiling, `propext` and `Quot.sound`. `Hash.Sha256.Audit` is the one exception, named
exactly in `HashTest/Audit/AxiomGate.lean`, because `MetaM` reaches
`Classical.choice`.
-/
