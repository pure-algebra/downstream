# lean4-hash

Proved hash functions in Lean 4, with no dependencies.

Two families live here, each with a bit-level transcription of its standard,
a native `ByteArray` implementation, and a machine-checked refinement theorem
connecting them for every byte-array input:

- **SHA-256 and SHA-224**, from [NIST FIPS 180-4](https://csrc.nist.gov/publications/detail/fips/180-4/final);
- **SHA3-512**, from [NIST FIPS 202](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.202.pdf).

The central theorems:

```lean
theorem Hash.Sha256.sha256_spec (msg : ByteArray) :
    (Hash.Sha256.sha256 msg).toList = Hash.Sha256.Spec.sha256_bytes msg.data.toList

theorem Hash.Sha3.sha3_512_spec (msg : ByteArray) :
    (Hash.Sha3.sha3_512 msg).toList = Hash.Sha3.Spec.sha3_512_bytes msg.data.toList
```

Each `Spec` namespace is a direct transcription of its standard's prose, with
every definition carrying its section citation, written to be *read against
the standard* rather than to run. Each `Fast` layer computes with native
machine words and is proved equal to the kernel-reducible `Impl` reference,
which in turn is proved equal to the transcription.

## Using it

Pin `leanprover/lean4:v4.33.1` and import `Hash`.

```lean
import Hash

#eval (Hash.sha256 "abc".toUTF8).toHex
#eval (Hash.sha3_512 "abc".toUTF8).toHex

-- or indexed by algorithm
#eval Hash.digestHex .sha3_512 "abc".toUTF8
```

`Hash.sha256`, `Hash.sha224` and `Hash.sha3_512` return their own family's
`Digest`, whose type carries the width. `Hash.digestBytes` and
`Hash.digestHex` take a `Hash.Algorithm` and are uniform in it;
`Hash.size_digestBytes` proves the result is as wide as the tag says.

The public root excludes the known-answer evidence and the axiom audits, so a
consumer never elaborates them; `Hash.Verified` includes them.

Command lines: `lake exe hash_sha256 <file>…` and
`lake exe hash_sha3_512sum [FILE|-]`.
Each also accepts `--self-test`, which replays every record of its sealed
NIST CAVP file at run time.

## What is proved, and what is not

Proved: that each native implementation computes what its `Impl` reference
computes, and that each reference computes what the transcription of the
standard computes, for every byte-aligned message. Padding lengths, output
lengths, byte/bit round trips, and the constant tables are proved separately.
Known-answer vectors from the NIST CAVP files are enforced as build-time
guards and, for selected vectors, reduced by the kernel itself.

Not claimed: injectivity, any security property (collision or preimage
resistance), and conformance beyond the sampled vectors. A known-answer test
is evidence, never proof.

## Trust base

To believe the theorems you must trust exactly two things:

1. **The transcriptions** — that `Hash/Sha256/Spec.lean` says what FIPS 180-4
   says, and `Hash/Sha3/Spec.lean` what FIPS 202 says. Every definition
   carries its section citation; the pinned PDFs and their digests are in
   `docs/PROVENANCE.md`. This is the irreducible prose-to-formal step every
   formalization has.
2. **The Lean 4 kernel**, toolchain `v4.33.1`, replayed by the toolchain's
   bundled external checker.

No custom axioms, no `native_decide`, no `bv_decide`, no `sorry`, no
dependencies. The package ceiling is `[propext, Quot.sound,
Classical.choice]`, and each family's audit line reports how much of that it
actually uses.

The two families differ here, and the difference is worth stating plainly.
The SHA-256 family reaches no `Classical.choice` at all: its bridge to
FIPS 180-4 and its native-layer refinement are closed at
`[propext, Quot.sound]`. The SHA3-512 family reaches it in 45 of its 571
audited declarations — its hexadecimal codec, and also its sponge and
permutation refinement lemmas, including both apex theorems.
`docs/EXTRACTION-RECORD.md` lists them by group.

## Checking it yourself

```text
lake --wfail build
lake --wfail build HashVerified
lake env leanchecker --fresh Hash.Verified
lake exe hash_sha256 --self-test
lake exe hash_sha3_512sum --self-test
lake exe hash_selftest
lake exe hash_vendorseal
lake exe hash_citations
lake exe hash_trustselftest
```

`leanchecker` is bundled with the toolchain and is silent on success. The
pinned `#guard_msgs` audit lines in each family's `Verified` module are the
axiom record: they report declaration and module coverage, the exact
allowlist, and zero offenders, and any drift fails the build.

## Provenance

Both families were moved here with their history preserved, by
`git filter-repo`, from repositories where they were developed and proved:
SHA-256 from `lean4-WHATWG-streams` at `a1383bc`, SHA3-512 from foldlab's
`formal/fips202` at `64be4b2c`. `docs/EXTRACTION-RECORD.md` records the exact
commands, the receipt comparison that shows no theorem's axiom set changed in
the move, and every deviation from the plan.

## Licence

MIT, unified with the rest of the family. See `LICENSE`.
