# Agent routing

The router hierarchy, what each router may decide, and the assurance a claim
must close before it is stated.

## Router hierarchy

`AGENTS.md` at the repository root is always loaded and binds every boundary.
Five boundary routers refine it, and none of them may contradict it:

| Router | Boundary |
| --- | --- |
| `AGENTS.md` | the repository: authority map, ceilings, gates, standing constraints |
| `Hash/AGENTS.md` | the library: layer discipline, totality, the two-`Digest` situation |
| `HashTest/AGENTS.md` | witnesses, attacks, evidence classes, the axiom gate |
| `HashGates/AGENTS.md` | tooling: why the gates are Lean, what each one decides |
| `generated/AGENTS.md` | projections: byte-determinism, never hand-edited |
| `test/AGENTS.md` | contracts, the counterexample register, trust-gate fixtures |

A router is authored. No generator writes one, and no generator may create or
replace an `AGENTS.md` anywhere in the tree.

If two routers appear to own the same fact, that is a defect in the ownership
map: stop and repair it rather than choosing one.

## Reading order for a seat

1. `AGENTS.md` in full.
2. The router of the boundary being changed.
3. `docs/EXTRACTION-RECORD.md` if the question is where a file came from, or
   which axioms each family actually reaches.
4. The family's proof graph: `docs/SHA256-DAG.md` or the FIPS 202 contract
   chain under `docs/sha3/`.
5. The contract packet and counterexample rows for the slice.
6. The exact verification command the packet records, and nothing else.

## Assurance threshold

A proof graph is mandatory for: refinement between layers, transcription
fidelity to a standard, any statement that a native implementation computes
what a reference computes, and any declaration that gates a consumer's
cutover. Both families in this package are at that level and arrived with
their graphs closed.

A finite leaf receipt suffices for: a known-answer test over pinned vectors,
a length or padding fact discharged by `omega`, and a table equality
discharged by `decide` over literals. A leaf receipt records the declaration
and the exact axiom set it reaches, never a prose summary.

No category and no cutover may hide an open graph edge or an open leaf
receipt. A gate that is green while an edge is open is reported with that
edge named.

## How a claim is stated

Name the exact theorem or gate, its assumptions, and what remains open. A
compiling finite probe is reported as a finite probe. A CAVP replay is
reported as evidence over the sampled vectors, never as conformance. Axiom
receipts are reported as `(declaration, axiom-set)` pairs, never as raw
console lines.

Exit codes are read from the log file, never from a piped console: a pipeline
reports the exit status of the pipe, not of the command.
