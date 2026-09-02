# Counterexamples

This is the central, durable home for counterexamples that can change a
declaration, theorem, admission rule, or cutover decision.

`REGISTER.md` assigns stable IDs and records the exact attacked statement,
witness, evidence command, proof assumptions, forced repair, and current
status. Lean witnesses live under `HashTest/Counterexamples/<Family>/` and
are linked from the register; each family also keeps an `ATTACKS.md`
describing the attack shapes in prose. Negative fixtures and gate mutants are
recorded separately, under `test/fixtures/trust-gate/`, because they attack
gates rather than semantic statements.

## Stable ID scheme

`HASH-<FAMILY>-CE-<nnn>`, where the family token is `SHA256` or `SHA3`. IDs
are never reused.

Rows extracted from another repository keep their evidence and acquire a new
ID here, with the old ID recorded beside it in a mapping table at the foot of
`REGISTER.md`. The mapping table exists so that a citation written against
the source repository still resolves; it is never removed.

## Statuses

- `PINNED`: the witness exists at a named immutable source revision.
- `SEEDED`: the packet has frozen the attack, but no immutable provenance pin
  for its witness has been recorded yet.
- `RESERVED`: the stable row and forced repair are frozen now; the executable
  witness belongs to a later packet whose declarations are not open yet.
- `CLOSED`: the witness is retained and the repaired declaration mechanically
  rejects the attack.
