# Hash library routing

This boundary contains the package's semantic declarations and their proofs.
The repository root rules remain in force.

## Layout

One directory per family, each with the same three-layer split, plus the
shared surface at the top:

```text
Hash.lean                 the public root; a consumer imports this and nothing else
Hash/Algorithm.lean       the tag, the three aliases, and the indexed dispatch
Hash/Verified.lean        the audited root; imports both families' verified roots
Hash/Sha256/…             FIPS 180-4: Spec, Impl, Lengths, Bridge, Fast, Hex, Digest, Api, Vec, Context, Sha224
Hash/Sha3/…               FIPS 202:   Spec, Impl, Lengths, Structural, Roundtrips, Theorems, Bridge, BridgeEvidence, Fast, Hex, Digest, Api
```

`Spec` is a transcription of the standard, written to be read against the
standard rather than to run. `Impl` is a byte-level or lane-level reference
the kernel can reduce; every known-answer test lives on it. `Fast` computes
with native machine words and is proved equal to `Impl`. `Bridge` carries
`Impl = Spec`. The public API is stated on `Impl` and `Spec` through those
two refinements.

## Rules

- Nothing here reads a file, spawns a process, or performs `IO`. A gate that
  needs to do any of those belongs under `HashGates/`.
- Totality holds: no `partial`, no `unsafe`, no `opaque`, no `implemented_by`,
  no `extern`.
- The ceiling is the package ceiling, `propext`, `Quot.sound`, and
  `Classical.choice` (ruling R-11). Reaching `Classical.choice` is not a
  violation, but it is counted: each family's audit line reports how many of
  its declarations do, and a proof that avoids it is still worth more than
  one that does not.
- No `#print axioms` in a library module: it puts one info line per
  declaration into every consumer's build log. Each family's `Audit` module
  emits exactly one typed verdict instead.
- A definition a theorem is stated about is written with `Vector.ofFn`,
  `Nat.fold`, or structural recursion — never `Id.run do` with `for`/`mut`,
  and never `xs[i]!`. Index with a proof or through a total accessor.
- No `#guard` or `decide` on a `Fast` definition: the kernel never runs
  `Fast`. Known-answer tests stay on `Impl`, which `Fast` is proved equal to.
- `Hash.lean` never imports a `Kats`, `Audit`, or `Verified` module. That is
  what keeps a consumer from elaborating the known-answer tests.

## Two `Digest` and two `Hex` copies

Ruling HP-2 (parity later, `docs/HASH-PACKAGE-PLAN.md`) is in force:
`Hash.Sha256.Digest` and `Hash.Sha3.Digest` coexist, as do the two `Hex`
codecs. They are not unified here, and no theorem of either family is
restated to make them agree; a conversion between the two `Digest` types is
explicit at every call site. Step 9 of the plan owns the unification.

HP-2 is now only about duplication: ruling R-11 removed the ceiling
difference that used to be the other half of the debt. The axiom difference
itself did not go away, and it is larger than the plan assumed — see
`docs/EXTRACTION-RECORD.md` §4.

## Changing a statement

Every statement in both families arrived already proved, from
`lean4-WHATWG-streams` at `a1383bc` and foldlab's `formal/fips202` at
`64be4b2c`. A statement that would have to change for the tree to build is a
stop condition: report it, do not adjust it. The same applies to a
known-answer literal — the literal is never adjusted; the failure is the
finding.
