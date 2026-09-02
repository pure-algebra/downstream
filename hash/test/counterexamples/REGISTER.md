# Counterexample register

Stable IDs in this file are never reused. A row closes only when its witness
is retained and the repaired declaration or theorem mechanically rejects the
attack. Statuses are defined in `README.md` beside this file.

| ID | Status | Attacked statement | Witness / evidence | Forced repair |
| --- | --- | --- | --- | --- |
| `HASH-SHA256-CE-001` | `CLOSED` | `Hash.Sha256.Spec.H0` is FIPS 180-4 §5.3.3 and not §5.3.2 | `HashTest/Counterexamples/Sha256/Mutants.lean`, `ce001_sha224IV` with its control `ce001_control`; `Hash.Sha256.Bridge.sha256_ne_sha224_iv` on the constants | none: the shipped `H0` is §5.3.3, and the witness pins that the choice is load-bearing |
| `HASH-SHA256-CE-002` | `CLOSED` | `Hash.Sha256.Impl.padBytes` appends the 64-bit big-endian length of FIPS 180-4 §5.1.1 | same file, `ce002_noLengthField` on W2, with `ce002_padBytes_eq_on_empty` proving why W1 cannot discriminate | none to the implementation; the contract's claim that W1 catches this mutant is corrected in `test/counterexamples/sha256/ATTACKS.md` |
| `HASH-SHA256-CE-003` | `CLOSED` | `Hash.Sha256.Impl.wordOfBytes` reads four bytes big-endian per FIPS 180-4 §3.1 | same file, `ce003_littleEndianWords` on W2 | none: the shipped reading is big-endian |
| `HASH-SHA256-CE-004` | `CLOSED` | `Hash.Sha256.Spec.bitsOfByte` is most-significant-bit-first per FIPS 180-4 §3.1, not FIPS 202 Appendix B.1's least-significant-first | same file, `ce004_lsbFirstBitOrder` on W1, with `ce004_padMarker` identifying the mutant's `0x01` padding byte | none: `Hash.Sha256.Spec` reproduces rather than imports the FIPS 202 conversion, precisely because the conventions differ. Both conventions now sit side by side in this package, which makes the difference easy to check and easy to get wrong |
| `HASH-SHA256-CE-005` | `CLOSED` | `Hash.Sha256.Impl.sha224` keeps the **left-most** 28 bytes of the untruncated output, per FIPS 180-4 §6.3 exception 2 | same file, `ce005_rightmostTruncation` on the SHA-224 `Len = 0` vector, with its control `ce005_control` and the statement of the shipped truncation `ce005_truncation_is_leftmost` | none: the shipped truncation is the left-most, and the witness pins that the byte range is load-bearing |

Every row's evidence command is `lake build HashTest`, which elaborates the
witnesses. Each inequality is closed by `decide +kernel`, so it is checked by
the Lean kernel with no compiler in the trust path, and the expected digests
come from `Hash.Sha256.Kats`, produced mechanically from the sealed
`vendor/nist-cavp-sha256/SHA256ShortMsg.rsp` and, for `HASH-SHA256-CE-005`,
`vendor/nist-cavp-sha224/SHA224ShortMsg.rsp`. The attack shapes are described
in `test/counterexamples/sha256/ATTACKS.md`.

The SHA3 family arrives with its own breaker batteries but with no rows in a
register of this shape. Minting `HASH-SHA3-CE-*` rows for them is owed, and
is not done here: this seat moves what exists and invents nothing.

## Renumbering from the source repository

These rows were moved, with their witnesses and their history, from
`mepuka/lean4-WHATWG-streams` at commit `a1383bc`, where `SHA` was one area
among several. This table exists so that a citation written against that
repository still resolves. It is never removed.

| Here | There |
| --- | --- |
| `HASH-SHA256-CE-001` | `WS-SHA-CE-001` |
| `HASH-SHA256-CE-002` | `WS-SHA-CE-002` |
| `HASH-SHA256-CE-003` | `WS-SHA-CE-003` |
| `HASH-SHA256-CE-004` | `WS-SHA-CE-004` |
| `HASH-SHA256-CE-005` | `WS-SHA-CE-005` |

The witness file moved with them, from
`WhatwgStreamsTest/Counterexamples/Sha/Mutants.lean` to
`HashTest/Counterexamples/Sha256/Mutants.lean`. No attacked statement, no
witness, and no acceptance condition changed in the move; the namespace and
the IDs did.
