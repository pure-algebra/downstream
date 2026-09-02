import Hash
import Hash.Sha256.Verified
import Hash.Sha3.Verified

/-!
# `Hash.Verified` — the audited root

The root of the `HashVerified` Lake library and the package's `testDriver`.
It imports the public library and, as each family lands, that family's
verified root: the known-answer tests and the axiom audit whose verdict line
is pinned by `#guard_msgs`.

Two families coexist here under ruling HP-2 (parity later), both under the
one package ceiling of ruling R-11, `[propext, Quot.sound,
Classical.choice]`:

- `Hash.Sha256.Verified` (S2), whose audit reports `0` of 422 declarations
  reaching `Classical.choice`;
- `Hash.Sha3.Verified` (S3), whose audit reports 45 of 571 — its hexadecimal
  codec and its refinement lemmas, both apex theorems included.
  `docs/EXTRACTION-RECORD.md` lists them.

Nothing imported here is reachable from `Hash`, so a consumer of the library
does not build the known-answer tests or the audits.

Each family's verified root carries its own `#guard_msgs`-pinned audit line,
so a change in either family's declaration count, module count, ceiling, or
admission count is a build error that must be updated deliberately rather
than noticed later.
-/
