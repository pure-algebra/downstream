# fips202

> **Moved document.** Authored in foldlab's `formal/fips202` and moved here,
> with its history, from commit `64be4b2c`. Declaration names and in-package
> paths have been rewritten to their `Hash.Sha3` spellings, so every name it
> cites resolves here. References to foldlab's own trees and tasks --
> `.reference/`, `mise.toml`, the estate's rulings -- describe that repository
> and are historical. Nothing this family proves changed in the move:
> `generated/receipts-sha3.tsv` is the evidence and
> `docs/EXTRACTION-RECORD.md` the account.

SHA3-512 from [NIST FIPS 202](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.202.pdf) in
Lean 4: a bit-level transcription of the standard, a native `ByteArray` library, and a
machine-checked refinement theorem for every byte-array input.

The central theorem:

```lean
theorem sha3_512_spec (msg : ByteArray) :
    (Hash.Sha3.sha3_512 msg).toList = Hash.Sha3.Spec.sha3_512_bytes msg.data.toList
```

`Hash.Sha3.Spec` is a direct transcription of the FIPS 202 prose — state arrays as functions
`Fin 5 → Fin 5 → Fin 64 → Bool`, the five step mappings θ ρ π χ ι, `pad10*1`, the sponge, and the
B.1 byte/bit conversions, each definition cited to its section of the standard. It is written to
be *read against the standard*, not to run. `Hash.Sha3.Fast` computes with 25 `UInt64` lanes and
reads directly from the byte buffer at rate 72 bytes. `Fast.sha3_512_eq_impl` connects it to
the frozen `Hash.Sha3.Impl` reference, which uses `BitVec 64`; `Bridge.sha3_512_bridge` connects
that reference to the transcription. Lane packing, padding, absorption, permutation and
squeeze each have refinement lemmas. The public API carries the 64-byte result width in
`Digest 64`. Compiled execution and file IO are tested separately from these pure theorems.

## What is proved

Theorems include:

- **Refinement**: the full bridge from `Impl.keccakF` = `Spec.keccakP` (per step mapping and per
  round) up to `sha3_512_bridge` above, plus the same pipeline result for pre-FIPS Keccak-512
  (`keccak512_prefips_bridge`).
- **Native implementation**: `Fast.sha3_512_eq_impl` and the public `sha3_512_spec` above,
  with native step, byte-addressing, padding, absorb and squeeze refinement lemmas.
- **Known answers in the kernel**: Keccak-f[1600] on the zero state and two NIST CAVP SHA3-512
  vectors, proved by `rfl` — the kernel itself runs the hash; no `native_decide`.
- **Structure**: `pad10*1` length and injectivity, output length, byte/bit round-trips, and the
  round-constant/rotation-offset tables proved equal to their generating definitions (LFSR walk,
  ρ walk).
- **Domain separation**: the SHA-3 `01` suffix changes the digest — `SHA3-512([]) ≠
  Keccak-512([])` at the specification level (`sha3_ne_prefips_spec`).

Four NIST CAVP vectors (message lengths 0, 24, 568, 576 bits — the rate boundary) are also
enforced as build-time `#guard`s.

## Library API

Pin consumers to `leanprover/lean4:v4.33.1` and import `Hash.Sha3`. The default library
root excludes the kernel known-answer evidence; `Hash.Sha3.Verified` includes it.

```lean
import Hash.Sha3

def digest : Hash.Sha3.Digest 64 := Hash.Sha3.sha3_512String "hello"
#eval digest.toHex

example (msg : ByteArray) :
    (Hash.Sha3.sha3_512 msg).toList = Hash.Sha3.Spec.sha3_512_bytes msg.data.toList :=
  Hash.Sha3.sha3_512_spec msg
```

`Hash.Sha3.sha3_512 : ByteArray → Digest 64` carries its 64-byte output width in the
result type. `Digest.toByteArray`, `toList`, and `toHex` expose bytes or lowercase
hex; `Digest.ofHex? n` accepts exactly `n` bytes of lowercase hex. `Hash.Sha3.Hex.encode`
and `decode?` provide the same codec for arbitrary byte arrays. Decoding rejects
odd lengths, uppercase digits, whitespace, and non-hex characters. Round-trip and
length facts are exported alongside these functions.

Build the command-line adapter with `lake build hash_sha3_512sum`. Run
`lake exe hash_sha3_512sum FILE`, or omit `FILE` (or pass `-`) to read binary
standard input. Output is `<128 lowercase hex digits>  <file name>`, with `-`
for stdin. File access and standard IO are adapter behavior, outside the pure
library's refinement theorem.

## Measured native throughput

Recorded 2026-09-02 on Windows x86-64, Lean v4.33.1, using the compiled
`hash_sha3_512sum` executable and seeded pseudo-random binary files. Each
median is three `Measure-Command` runs, including process startup, file
reading, hashing and output; fixture generation, independent .NET SHA3-512
calculation and compilation are outside the timed interval.

| Input | Median wall time |
|---|---:|
| 1 MiB (1,048,576 bytes) | 0.634853 s |
| 16 MiB (16,777,216 bytes) | 9.875716 s |

Every measured digest agreed with .NET SHA3-512 and all three runs agreed.
These are host/workload measurements, not performance or security theorems.
Peak working-set data was unavailable after process exit. Reproduction and
full raw receipts are in `docs/sha3/library-spec/runs/S2/benchmark.ps1`
and `benchmark.log` at the repository root.

## Trust statement

To believe the theorems you must trust exactly two things:

1. **The transcription**: that `Hash/Sha3/Spec.lean` says what the FIPS 202 prose says. Every
   definition carries its section citation; the pinned PDF and its digest are in
   [PROVENANCE.md](PROVENANCE.md). This is the irreducible prose-to-formal step every
   formalization has.
2. **The Lean 4 kernel**, toolchain `v4.33.1` (the post-soundness-fix release). Every theorem's
   axiom profile in the verified closure is checked by the typed audit and is contained in
   `[propext, Classical.choice, Quot.sound]` — no custom axioms, no `native_decide`, no
   `bv_decide`, no dependencies (core only, no Mathlib). The current S2 receipt, recorded on
   2026-09-02, is a fresh replay of the verified closure under the toolchain's bundled external
   checker (`leanchecker`) on Windows x86-64. A current-tree arm64 replay is pending and deferred
   to S5.

What is **not** claimed: injectivity of the hash (false by counting), any security property
(collision resistance, preimage resistance), and conformance beyond the sampled vectors — the
CAVP checks are evidence, never proof.

## Checking it yourself

```
lake --wfail build HashVerified
lake env leanchecker --fresh Hash.Sha3.Verified
```

A clean verified build elaborates every proof and runs the CAVP guards. The pinned
`sha3 axiom audit: …` line in `Hash/Sha3/Verified.lean` is the axiom record: it reports the declaration
and module coverage, the exact allowlist, and zero offenders; count or message drift fails the
build. `leanchecker` (bundled with the toolchain) replays `Hash.Sha3.Verified` through a fresh kernel
and is silent on success.

## Files

| File | Content |
|---|---|
| `Hash/Sha3/Spec.lean` | FIPS 202 transcription (frozen; the meaning of every claim) |
| `Hash/Sha3/Impl.lean` | Executable lane-level SHA3-512 + pre-FIPS Keccak-512, CAVP guards |
| `Hash/Sha3/Fast.lean` | Native UInt64/ByteArray implementation and refinement to Impl |
| `Hash/Sha3/Api.lean`, `Hash/Sha3/Digest.lean`, `Hash/Sha3/Hex.lean` | Typed public API, checked widths, canonical hex and their theorems |
| `Hash/Sha3/Lengths.lean` | Reference output-length and padding theorems |
| `HashGates/Sha3.lean` | Binary file/stdin command-line adapter |
| `Hash/Sha3/Bridge.lean` | The refinement: abstraction function, round bridges, sponge ladder, apex |
| `Hash/Sha3/BridgeEvidence.lean` | Evidence-only domain-separation theorem at its unchanged name |
| `Hash/Sha3/Verified.lean`, `Hash/Sha3/Audit.lean` | Full evidence closure and fail-closed typed axiom audit |
| `Hash/Sha3/Kats.lean` | Kernel-reduction known-answer theorems with literal statement pins |
| `Hash/Sha3/Structural.lean`, `Hash/Sha3/Roundtrips.lean`, `Hash/Sha3/Theorems.lean` | Padding, lengths, byte/bit round-trips, table correctness |
| `Hash/Sha3/KeccakProbe.lean` | The original feasibility probe (Keccak-f[1600] KAT by `rfl`) |
| `PASSA-CONTRACT.md`, `MODEL-INVARIANTS.md`, `PASSB-SNAPSHOT.md` | The contract chain: scope, carriers, and frozen theorem statements the proofs were built against |
| `PROVENANCE.md` | Source pins, tool admissions, verification record |
| `TOOLING-NOTES.md` | Gate-tooling edge cases recorded for the lab's verification-tooling work |
| `CODEX-HANDOFF.md` | The bounded proof-loop handoff under which the sponge ladder was completed |

## Relation to neighboring work

Two Lean 4 hash developments existed when this was built, and this artifact deliberately occupies
the gap between them: [kim-em/lean-crypto-hash](https://github.com/kim-em/lean-crypto-hash)
(SHA-2/SHA-3 with structural/API theorems and a strong CAVP validation harness, but no
specification layer) and emberian/dregg (a FIPS 202 specification-and-refinement architecture,
but covering SHAKE128/256 only, not the fixed SHA3 variants). The statement-pin discipline used
in the known-answer files follows dregg's method. To our knowledge this is the first Lean 4
development proving an executable implementation of SHA3-512 equal to a transcription of the
FIPS 202 specification.
