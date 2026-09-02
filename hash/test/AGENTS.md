# Test-material routing

This boundary holds the authored material the Lean batteries are written
against: contracts, the counterexample register, and the trust-gate fixtures.
No Lean library module lives here; the executable witnesses live under
`HashTest/`.

| Path | Owns |
| --- | --- |
| `test/contracts/` | breaker-authored contract packets, one per family, and their claim-domain tables |
| `test/counterexamples/REGISTER.md` | stable counterexample IDs, attacked statements, witnesses, and forced repairs |
| `test/counterexamples/<family>/ATTACKS.md` | the attack shapes in prose, per family |
| `test/fixtures/trust-gate/` | the planted declarations the trust self-test appends, and `known-red.txt` |
| `test/receipts/` | the `(declaration, axiom-set)` receipts each family had in the repository it was extracted from, at the named commit |
| `test/tools/Receipts.lean` | the generator that writes `generated/receipts-*.tsv` and the join that compares them against `test/receipts/` |

## Rules

- A contract packet is frozen before the implementation it constrains, and
  the Lean battery, not the packet's prose, is the authority on names and
  propositions.
- A counterexample ID is never reused. A row closes only when its witness is
  retained and the repaired declaration mechanically rejects the attack.
- Every expected digest in this tree names the sealed `.rsp` record it was
  transcribed from. A digest typed from memory is a defect even when it
  happens to be right.
- `known-red.txt` is self-checking in both directions: an undeclared failure
  fails the gate, and a declared module that is actually green fails it too,
  so an entry cannot outlive the red phase it describes.
- A fixture under `test/fixtures/trust-gate/` is planted into a throwaway
  copy of the tree, never into the tree itself. Each one exists to prove that
  the gate rejects it for a *stated* reason; a fixture whose rejection reason
  is not asserted is not evidence.
- A file under `test/receipts/` is a record of what another repository's
  kernel reported, at a commit that cannot change. It is never regenerated
  here, and never edited to make a join pass. A join that fails is a finding
  about the move.
