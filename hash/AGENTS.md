# lean4-hash — agent operating rules

This file is the always-loaded router for work in this repository. Read it in
full, then open only the authority documents named for the current task.

This package is one thing: hash functions whose meaning is a machine-checked
refinement to a transcription of their standard. It has zero Lake
dependencies and sits below every consumer.

## Authority map

| Path | Owns |
| --- | --- |
| `docs/AGENT-ROUTING.md` | the router hierarchy and the assurance threshold |
| `docs/EXTRACTION-RECORD.md` | where every file came from, the receipt joins, the per-family axiom counts, and every deviation from the extraction plan |
| `docs/PROVENANCE.md` | every pin: digest, fetch command, cross-check, license |
| `docs/SHA256-DAG.md` | the proof graph for SHA-256 and SHA-224 |
| `docs/sha3/` | the FIPS 202 contract chain, model invariants, provenance, and tooling notes |
| `test/contracts/` | breaker-authored contracts and executable falsifiers |
| `test/counterexamples/` | central counterexample register and durable witnesses |
| `Hash/` | library declarations and proofs |
| `HashTest/` | Lean witnesses, attacks, receipts, and the axiom gate |
| `HashGates/` | repository gates implemented in Lean |
| `generated/` | deterministic projections only; never hand-edited |
| `vendor/` | sealed pinned third-party bytes; never edited |

If two files appear to own the same fact, stop and repair the ownership map.

## What this package claims

Each family carries one apex theorem relating its native implementation to a
byte-level reference, and that reference to a bit-level transcription of the
standard:

- `Hash.Sha256.Bridge.sha256_bridge` and `Hash.Sha256.Fast.sha256_eq_impl`;
- `Hash.Sha3.Bridge.sha3_512_bridge` and `Hash.Sha3.Fast.sha3_512_eq_impl`.

What is **not** claimed anywhere: injectivity, any security property
(collision or preimage resistance), or conformance beyond the sampled CAVP
vectors. A known-answer test is finite evidence, never proof. Do not write
"sound", "equivalent", "conforms", or "complete" without naming the exact
theorem or gate, its assumptions, and what remains open.

## The ceiling

**One ceiling**, under operator ruling R-11 (2026-09-02): `propext`,
`Quot.sound`, and `Classical.choice`, the same for `Hash/`, `HashTest/` and
`HashGates/` alike. There is no admission list, no exemption, and no staleness
check, because nothing needs admitting.

`sorryAx`, `Lean.ofReduceBool`, `Lean.ofReduceNat`, and `Lean.trustCompiler`
are forbidden everywhere, as are the `_native` auxiliary axioms
`native_decide` and `bv_decide` mint. That is the substance of the ceiling:
no compiler and no `sorry` in the trust path. `partial` and `unsafe` are
forbidden in all four Lean trees.

The two families do not in fact reach the same axioms, and that difference
stays visible without being a gate: each family's audit line reports how many
of its declarations reach `Classical.choice`. SHA-256 reaches none. SHA3-512
reaches it in 45 of 571 — not only its hexadecimal codec but its sponge and
permutation refinement lemmas, including both apex theorems.
`docs/EXTRACTION-RECORD.md` lists them by group and explains why that makes
step 9 of the plan larger than the plan estimates. Ruling HP-2 (parity later)
governs the `Digest`/`Hex` unification, which is a separate question from the
ceiling.

## Standing constraints

- Toolchain `leanprover/lean4:v4.33.1` exactly.
- Zero Lake dependencies. `lake-manifest.json` packages stay `[]`. This
  package sits below every consumer and may depend on nothing.
- `lake --wfail build` is the build. Warnings are errors.
- No `Spec`, `Impl`, or `Bridge` definition body and no bridge or API theorem
  statement changes without a ruling. Both families arrived proved; a
  statement that has to change to build is a stop condition, not a repair.
- Every witness digest is transcribed from a sealed `.rsp` or a pinned
  standard, never typed from memory.
- `vendor/` bytes are extracted by git object and verified by blob hash.

## Gates

Every gate is Lean and runs under the pinned toolchain. Shell files only
orchestrate; they decide nothing.

| Command | Decides |
| --- | --- |
| `lake build` | the libraries elaborate; the elaboration-time axiom gate in `HashTest.lean` passes over every declaration |
| `lake --wfail build HashVerified` | the known-answer tests elaborate and both pinned audit lines still read as written |
| `lake env leanchecker --fresh Hash.Verified` | an independent kernel replays the verified closure |
| `lake exe hash_sha256 --self-test` | the proved SHA-256 and SHA-224 reproduce every record of both pinned CAVP files |
| `lake exe hash_sha3_512sum --self-test` | the proved SHA3-512 reproduces every record of the pinned CAVP file |
| `lake exe hash_selftest` | every sealed CAVP response file is replayed through `Hash.digestHex`, and none is left unclaimed by any algorithm |
| `lake exe hash_vendorseal` | `vendor/` and `generated/vendor-manifest.tsv` agree in both directions; every path is valid on Windows |
| `lake exe hash_citations` | no line-numbered citation into a protected authored document |
| `lake exe hash_trustselftest` | the declared red set is exact; planted violations are rejected for their stated reasons |

## Generated facts

Authored routers are never generated. Manifests, receipt tables, and census
rows are projections of canonical inputs and are checked for drift. Never
hand-edit a file under `generated/`: repair its input or its generator,
regenerate into a clean tree, and compare bytes.

## Handoff

Every handoff records base and head commits, file fence, changed files, exact
commands and results, public declarations, axiom output, open proof edges or
leaf receipts, counterexamples exercised, and whether any evidence is bounded
or host-only. Exit codes are read from the log file, never from a piped
console.
