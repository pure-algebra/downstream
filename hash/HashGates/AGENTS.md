# HashGates tooling routing

This boundary contains the repository's gates implemented in Lean: the two
hash command lines, the vendor seal, the internal-citation gate, and the
trust self-test. It is tooling that reads files, spawns processes, and
produces projections, and it is audited by exactly the same gate and the same
ceiling as the library.

## Why the gates are Lean

Every check that decides whether the tree is green runs under the same
toolchain as the proofs and is itself audited by the axiom gate. A gate is
never a shell one-liner whose behaviour differs between hosts. Shell and
PowerShell files, where they exist, only orchestrate `lake exe` invocations;
they decide nothing.

## Rules

- No semantic declaration lives here. A definition that models a standard
  belongs under `Hash/` behind a contract.
- Totality holds: no `partial`, no `unsafe`. Loops are bounded by fuel or by
  the structure they traverse.
- The ceiling is the package ceiling: `propext`, `Quot.sound`, and
  `Classical.choice`. `sorryAx`, `Lean.ofReduceBool`, `Lean.ofReduceNat`,
  and `Lean.trustCompiler` remain forbidden.
- A gate reports a stable `PASS` or `FAIL` line stating exactly what was
  checked and, on failure, every offending item. It never truncates the
  failure list.
- A gate that writes a projection under `generated/` records that it did,
  names the file, and never writes an `AGENTS.md`.
- Neither hash command line holds hash arithmetic of its own.
  `HashGates/Sha256.lean` computes every digest through `Hash.Sha256.sha256` and
  `Hash.Sha256.sha224` and every hexadecimal spelling through
  `Hash.Sha256.Hex.encode`; `HashGates/Sha3.lean` computes through
  `Hash.Sha3.sha3_512`. `HashGates/VendorSeal.lean` computes its row digests
  through the SHA-256 API. All of those are audited by the same gate as the
  library, and their meaning is the family's bridge theorem.
- Neither self-test contains a digest literal. Each reads its sealed CAVP
  `.rsp` at run time and reproduces every record in it, so it cannot drift
  from the pin: if the vendored bytes change the seal fails, and if an
  implementation changes the self-test fails. Each record's `Len` field, not
  the length of its `Msg` text, is the authority for the message length.
- Every gate resolves the repository root by searching upward for
  `Hash.lean`; none reads an environment variable for that.

## Gates

| Command | Checks | Writes |
| --- | --- | --- |
| `lake exe hash_sha256 --self-test` | the proved SHA-256 and SHA-224 against every record of both pinned NIST CAVP short-message files | nothing |
| `lake exe hash_sha256 <file>…` | nothing; prints the SHA-256 of each file | nothing |
| `lake exe hash_sha3_512sum --self-test` | the proved SHA3-512 against every record of the pinned NIST CAVP short-message file | nothing |
| `lake exe hash_sha3_512sum [FILE\|-]` | nothing; prints the SHA3-512 of a file or of standard input | nothing |
| `lake exe hash_selftest` | every `.rsp` found under `vendor/`, replayed through `Hash.digestHex`; a response file no algorithm claims fails | nothing |
| `lake exe hash_vendorseal` | `vendor/` against `generated/vendor-manifest.tsv` in both directions; Windows path validity | nothing |
| `lake exe hash_vendorseal --write` | Windows path validity | `generated/vendor-manifest.tsv` |
| `lake exe hash_citations` | no line-numbered citation into a protected authored document | nothing |
| `lake exe hash_trustselftest` | the declared red set; then planted `partial`, `unsafe`, `sorry`, `native_decide`, malformed literals, and an unreachable module are each rejected for the stated reason | a throwaway copy outside the tree, removed afterwards |
