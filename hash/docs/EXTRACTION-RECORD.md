# Extraction record

What this package is made of, where each part came from, the evidence that
nothing changed in the move, and every deviation from
`docs/HASH-PACKAGE-PLAN.md` as it was handed to the extracting seat.

Written 2026-09-02 by the extraction seat, on Windows 11 (NT 10.0.26200),
AMD Ryzen 7 8700F, toolchain `leanprover/lean4:v4.33.1`.

## 0. The five commits

| | Commit | |
| --- | --- | --- |
| S1 | `3779fed` | the skeleton, gates and routers |
| S2 | `d3f980e` | SHA-256 moved from `lean4-WHATWG-streams`, a merge commit with the filtered history as its second parent; ruling R-11 applied here (D4) |
| S3 | `9991548` | SHA3-512 moved from foldlab, likewise a merge commit |
| S4 | `ed9deba` | `Hash.Algorithm`, the aliases, and the combined self-test |
| S5 | this commit | this record |

Not tagged and not pushed: the coordinator does both after review.

## 1. Sources

| Source | Commit | What came from it |
| --- | --- | --- |
| `mepuka/lean4-WHATWG-streams`, branch `main` | `a1383bc09f945d37e464900a10515278c8a455b1` | the SHA-256 and SHA-224 family, its witnesses, its contract, its proof graph, three NIST pins, and the package skeleton (gates, routers, axiom gate, trust self-test, CI) |
| `mepuka/foldlab`, branch `main` | `64be4b2c8182f92997bffb3d47f7598d6a558ed4` | the SHA3-512 family, its contract chain, its library specification, and its command-line adapter |
| `kim-em/lean-crypto-hash` | `54e6068abd4658fd91203cae1c2316188ffa0e89` | the three CAVP response files, read out of its git objects; no code |

Neither source repository was written to. Both were cloned into a scratch
directory and read there; every extraction ran on a throwaway clone, never on
a checkout. The `lean4-WHATWG-streams` working tree happened to be dirty at
the time, with a conflicted `test/counterexamples/REGISTER.md`, so every read
of it went through git objects at `a1383bc` rather than through its files.

## 2. The moves

Both moves were made by `git filter-repo` on a fresh `--no-local` clone, and
fetched into this repository and merged with
`--allow-unrelated-histories`, so blame survives: a line of
`Hash/Sha256/Bridge.lean` still points at the commit that authored it in
`lean4-WHATWG-streams`, and a line of `Hash/Sha3/Bridge.lean` at the commit
that authored it in foldlab.

`git filter-repo` is installed but not on `PATH`; it was invoked as
`python -m git_filter_repo` from the mise Python 3.13.14. Its first run
refused a plain local clone ("does not look like a fresh clone"); the clones
were remade with `git clone --no-local`.

### SHA-256, from `lean4-WHATWG-streams` at `a1383bc`

```text
python -m git_filter_repo \
  --path Sha256.lean \
  --path Sha256/ \
  --path WhatwgStreamsTest/Counterexamples/Sha/ \
  --path test/contracts/sha256.contract.md \
  --path test/counterexamples/sha/ \
  --path test/counterexamples/REGISTER.md \
  --path docs/SHA256-DAG.md \
  --path docs/PROVENANCE.md \
  --path vendor/nist-cavp-sha256/ \
  --path vendor/nist-cavp-sha224/ \
  --path vendor/nist-fips-180-4/ \
  --path-rename Sha256/:Hash/Sha256/ \
  --path-rename Sha256.lean:Hash/Sha256.lean \
  --path-rename WhatwgStreamsTest/Counterexamples/Sha/:HashTest/Counterexamples/Sha256/ \
  --path-rename test/counterexamples/sha/:test/counterexamples/sha256/
```

25 commits in, 12 out, 24 files. Merged as `S2`.

### SHA3-512, from foldlab at `64be4b2c`

```text
python -m git_filter_repo \
  --path formal/fips202/Sha3.lean \
  --path formal/fips202/Sha3/ \
  --path formal/fips202/Sha3Sum.lean \
  --path formal/fips202/README.md \
  --path formal/fips202/PROVENANCE.md \
  --path formal/fips202/TOOLING-NOTES.md \
  --path formal/fips202/PASSA-CONTRACT.md \
  --path formal/fips202/PASSB-SNAPSHOT.md \
  --path formal/fips202/MODEL-INVARIANTS.md \
  --path formal/fips202/CODEX-HANDOFF.md \
  --path .staging/fips202-library/ \
  --path-rename formal/fips202/Sha3/:Hash/Sha3/ \
  --path-rename formal/fips202/Sha3.lean:Hash/Sha3.lean \
  --path-rename formal/fips202/Sha3Sum.lean:Gates/Sha3.lean \
  --path-rename formal/fips202/README.md:docs/sha3/README.md \
  --path-rename formal/fips202/PROVENANCE.md:docs/sha3/PROVENANCE.md \
  --path-rename formal/fips202/TOOLING-NOTES.md:docs/sha3/TOOLING-NOTES.md \
  --path-rename formal/fips202/PASSA-CONTRACT.md:test/contracts/sha3/PASSA-CONTRACT.md \
  --path-rename formal/fips202/PASSB-SNAPSHOT.md:test/contracts/sha3/PASSB-SNAPSHOT.md \
  --path-rename formal/fips202/MODEL-INVARIANTS.md:test/contracts/sha3/MODEL-INVARIANTS.md \
  --path-rename formal/fips202/CODEX-HANDOFF.md:test/contracts/sha3/CODEX-HANDOFF.md \
  --path-rename .staging/fips202-library/:docs/sha3/library-spec/
```

632 commits in, 4 out, 29 files. Four is the whole of it: `git log -- formal/fips202`
at `64be4b2c` also lists four commits, so no history was dropped. Merged as `S3`.

## 3. The receipt join — the acceptance bar

The bar was that every theorem's receipt is identical before and after. It is
checked in Lean, not by a shell script, by `test/tools/Receipts.lean`, which
writes one `(declaration, axiom-set)` row per declaration and then joins the
two sides by name modulo the namespace prefix, failing on any declaration
that differs, appears only before, or appears only after.

The "before" sides were taken by running the same extractor inside each
source checkout at its named commit, and are committed here as evidence:

| Before | Taken in | Rows |
| --- | --- | --- |
| `test/receipts/sha256-before-a1383bc.tsv` | `lean4-WHATWG-streams` at `a1383bc` | 685 |
| `test/receipts/sha3-before-64be4b2c.tsv` | foldlab `formal/fips202` at `64be4b2c` | 583 |

Both joins pass, quoted from `lake env lean test/tools/Receipts.lean`:

```text
PASS receipt join: 685 declarations, axiom sets identical before and after; 0 differing, 0 only before, 0 only after (test/receipts/sha256-before-a1383bc.tsv -> generated/receipts-sha256.tsv, rewriting Hash.Sha256 to Sha256)
PASS receipt join: 583 declarations, axiom sets identical before and after; 0 differing, 0 only before, 0 only after (test/receipts/sha3-before-64be4b2c.tsv -> generated/receipts-sha3.tsv, rewriting Hash.Sha3 to Sha3)
```

The set joined is every declaration Lean compiled from the tree — private,
generated and internal ones included — not only the exported theorems. Each
family's `Audit` module is excluded on both sides: it is audit
implementation rather than a theorem, and ruling R-11 deliberately changed
it, so including it would report an ordered edit as a drift.

## 4. Axioms, per family

Ruling R-11 (operator, 2026-09-02) gives the whole package one ceiling,
`[propext, Quot.sound, Classical.choice]`, and removes the admission
machinery: nothing needs admitting, so there is no exact-module or
exact-declaration list and no staleness check, and `docs/PARITY-DEBT.md` is
not written. What the ceiling still forbids is `sorryAx`,
`Lean.ofReduceBool`, `Lean.ofReduceNat`, `Lean.trustCompiler`, and the
`_native` auxiliary axioms — that is, no compiler and no `sorry` in the trust
path.

The two families do not reach the same axioms, and the counts are recorded
here as information rather than enforced:

| Family | Declarations audited | Reaching `Classical.choice` |
| --- | --- | --- |
| `Hash.Sha256` | 422 across 12 modules | **0** |
| `Hash.Sha3` | 571 across 14 modules | **45** |

The SHA-256 figure is the one its source repository's stricter ceiling used
to enforce; it survived the move unchanged.

### A finding about the SHA-3 45

The plan expects step 9 to empty this count by restating fips202's
`String`-length theorems on `List Char`. **The receipts refute that.** The 45
are, by name, from `generated/receipts-sha3.tsv`:

| Group | Count | Examples |
| --- | --- | --- |
| the hexadecimal codec | 10 | `Hex.decode?`, `Hex.decode?_encode`, `Hex.length_encode`, `Hex.encode_lower`, `Digest.ofHex?`, `Digest.length_toHex`, `Digest.ofHex?_toHex`, `Impl.toHex` |
| `Bridge`, the refinement to the specification | 21 | `theta_bridge`, `chi_bridge`, `rhoPi_bridge`, `rnd_bridge`, `keccakF_bridge`, `absorbBlock_bridge`, `absorbBlocks_bridge`, `squeeze_bridge`, `keccak512_prefips_bridge`, `sha3_ne_prefips_spec`, and **`sha3_512_bridge`, the apex** |
| `Fast`, the native layer's refinement to `Impl` | 11 | `theta_abs`, `chi_abs`, `keccakF_abs`, `absorbAll_abs`, `squeeze_eq`, and **`sha3_512_eq_impl`, the apex** |
| the public API theorems that compose them | 3 | `sha3_512_spec`, `sha3_512_impl`, `sha3_512_ofList` |

Only the first group is the `String`-typed one step 9 addresses. The other 35
are the refinement proof itself: SHA3-512's two apex theorems reach
`Classical.choice`, where SHA-256's `Bridge.sha256_bridge` and
`Fast.sha256_eq_impl` do not.

This is not a defect and not something the move introduced — the join in §3
shows every one of these receipts is byte-identical to what foldlab's kernel
reported at `64be4b2c`, under a ceiling that always admitted
`Classical.choice`. It is a correction to the plan's estimate of what step 9
costs: retiring the SHA-3 family's `Classical.choice` means reworking its
sponge and permutation refinement proofs, not restating five `String`
theorems. The coordinator should re-scope step 9 on this basis, or rule that
the SHA-3 family keeps `Classical.choice` permanently — which ruling R-11 has
in effect already made survivable.

Both audit lines are pinned by `#guard_msgs`, so either number moving is a
build error:

```text
sha256 axiom audit: 422 declarations across 12 modules; ceiling [propext, Quot.sound, Classical.choice]; 0 reach Classical.choice; 0 offenders
sha3 axiom audit: 571 declarations across 14 modules; ceiling [propext, Quot.sound, Classical.choice]; 45 reach Classical.choice; 0 offenders
```

The repository-wide gate, which audits every declaration in `Hash/`,
`HashTest/` and `HashGates/` including private and compiler-generated ones,
reports:

```text
Hash module and axiom gate: checked 47 modules and 1618 declarations (223 in the HashGates tooling tree); ceiling is [propext, Quot.sound, Classical.choice] for every tree; 122 declaration(s) reach Classical.choice; 0 offenders
```

## 5. Vendored bytes

Five files, sealed by `generated/vendor-manifest.tsv`, every digest computed
by this package's own proved SHA-256:

| Path | SHA-256 | Bytes |
| --- | --- | --- |
| `vendor/nist-cavp-sha224/SHA224ShortMsg.rsp` | `4cf7c594ec3a540880756e5cf5095a8b5c9194a8a7868d686efb47187c2e0330` | 9,511 |
| `vendor/nist-cavp-sha256/SHA256ShortMsg.rsp` | `294ecec26959357405a621121bbfb01db4d45b9e834624b2d71aedd94ffde019` | 10,031 |
| `vendor/nist-cavp-sha3-512/SHA3_512ShortMsg.rsp` | `11d0676f4c6f10e30c5025204f4e15cd1ef6b1e34f6660d586d8ae9dfab4d721` | 16,502 |
| `vendor/nist-fips-180-4/NIST.FIPS.180-4.pdf` | `0455b406d89648d20cbde375561e19c245b9815e894164c2670772e3d54deb82` | 833,315 |
| `vendor/nist-fips-202/NIST.FIPS.202.pdf` | `1592607831ff0908cc590632ce371c6c95e94025bb1a0c8ae90a4d0ec1ed025e` | 1,459,683 |

The three SHA-2 rows moved with the SHA-256 history and their blob hashes are
unchanged: `git rev-parse a1383bc:vendor/…` in the source, `git rev-parse
HEAD:vendor/…` here, and `git hash-object --no-filters` on the working-tree
file all return the same object for each, and the manifest rows are
byte-identical to the source repository's.

The two FIPS 202 pins were added here. The CAVP file was extracted by git
object, never through a working tree:

```text
git -C <lean-crypto-hash clone> ls-tree -r 54e6068abd4658fd91203cae1c2316188ffa0e89 \
    -- validation/vectors/nist/SHA3_512ShortMsg.rsp
    -> blob d9e6e36428a9db11834f106c80d153b2d03465ce
cmd /c "git -C <clone> cat-file blob d9e6e364… > vendor/nist-cavp-sha3-512/SHA3_512ShortMsg.rsp"
git hash-object --no-filters vendor/nist-cavp-sha3-512/SHA3_512ShortMsg.rsp
    -> d9e6e36428a9db11834f106c80d153b2d03465ce
```

`cmd` redirection is used because PowerShell's re-encodes. The FIPS 202 PDF
was copied byte-for-byte with `[IO.File]::WriteAllBytes` on
`[IO.File]::ReadAllBytes`; source and copy share the git blob
`deb8de5e588505c95f59081e337019b2817a58ee`.

Both FIPS 202 digests equal the ones foldlab had already pinned for them, so
the bytes sealed here are the bytes the SHA3 transcription was written
against and the bytes its known-answer theorems were transcribed from. The
match was computed, not copied across.

## 6. Deviations from the plan as handed over

Each is a decision, not an accident, except where it says otherwise.

**D1 — `.staging/fips202-library/runs/**` was not moved.** It is untracked in
foldlab at `64be4b2c`: only `SPEC.md` and `contracts/{S0,S1,S2}.contract.md`
are in that commit. There was no history to preserve, and reading foldlab's
working tree would have gone outside the commit this seat was told to read.
The S2 acceptance report and the benchmark logs the plan cites therefore did
not come across; the benchmark was rerun here instead (§8).

**D2 — fips202's package configuration was not moved.** `lakefile.toml`,
`lean-toolchain`, `lake-manifest.json` and `.gitignore` are superseded by
this package's own, which carry the same toolchain pin, the same zero
dependencies and the same `leanOptions`. `formal/fips202/LICENSE` is the
Apache-2.0 blob `d645695673349e3947e8e5ae42332d0ac3164cd7`, which is already
this repository's root `LICENSE`, extracted from that same object.

**D3 — `HashVerified` is a Lake library, not a directory.** The brief's prose
put each family's `Kats`, `Audit` and `Verified` under `HashVerified/…`,
which would name them `HashVerified.Sha256.Audit`. Two other requirements
contradict that: the axiom gate was to admit `Hash.Sha256.Audit` and
`Hash.Sha3.Audit` *by those exact names*, and the lakefile was to declare
`HashVerified` with `roots = ["Hash.Verified"]` rather than a glob. A Lean
module's name is its path, so both fix the files under `Hash/`. They stay at
`Hash/Sha256/{Kats,Audit,Verified}.lean` and
`Hash/Sha3/{Kats,KeccakProbe,Audit,Verified}.lean`; `HashVerified` is the
Lake library rooted at `Hash/Verified.lean`, which imports both families'
verified roots and nothing else. `Hash.lean` does not import them, which is
what keeps a consumer from elaborating the known-answer tests.

**D4 — ruling R-11 landed inside the S2 commit.** It arrived from the
coordinator while S2 was being verified. Folding it in kept the five-commit
shape the brief asked for; a sixth commit would have been cleaner history and
was traded away for that. S1's commit message therefore describes a
two-ceiling design that S2 replaces.

**D5 — the executables arrive with the libraries they call.**
`HashGates.Sha256`, `HashGates.Sha3` and `HashGates.VendorSeal` compute every
digest through the proved library, so none of them can compile before that
library exists. S1 shipped `hash_citations` and `hash_trustselftest`;
`hash_sha256` and `hash_vendorseal` arrived at S2, `hash_sha3_512sum` at S3.
The CI workflow was written in its final form at S1 and became true at S3.

**D6 — a sixth executable, `hash_selftest`.** The plan asked for "one combined
self-test that replays every record of every sealed `.rsp`". It is
`lake exe hash_selftest`, and it discovers the files by walking `vendor/`
rather than reading a list, so a sealed response file that no algorithm claims
is a failure.

**D7 — `Sha3Sum.lean` became `HashGates/Sha3.lean`, not a `hashbin/` file.**
The brief sent it to "the `sha3_512sum` bin entry", but `hashbin/` in this
package holds one-line wrappers and no logic, and the file had to grow a
`--self-test` mode. The CLI logic keeps its history at `HashGates/Sha3.lean`;
`hashbin/Sha3Sum.lean` is a new four-line entry point.

**D8 — the CAVP parser was lifted into `HashGates.Cavp`.** Both self-tests
read the same file format. The parser takes its hexadecimal codec and its
digest function from the caller, so each family's self-test still runs
entirely inside its own family.

**D9 — moved documents were rewritten and headed.** Declaration names and
in-package paths in `docs/SHA256-DAG.md`, `test/contracts/sha256.contract.md`,
`test/counterexamples/sha256/ATTACKS.md` and the eleven SHA3 documents were
rewritten to their spellings here, so the names they cite resolve. Each
carries a "Moved document" header naming its source repository and commit and
saying that references to that repository's *other* trees are historical.
`docs/PROVENANCE.md` was cut to the NIST and SHA rows and given rows for the
two FIPS 202 pins; `test/counterexamples/REGISTER.md` was renumbered
`WS-SHA-CE-*` to `HASH-SHA256-CE-*` with a mapping table that is never
removed. No attacked statement, witness, or acceptance condition changed.

**D10 — the SHA3 audit line changed twice over.** Its ceiling is spelled in
the same order as the SHA-256 one so the two pinned lines can be read side by
side, and it gained the `N reach Classical.choice` clause. Both were ordered
by R-11; the set of axioms admitted is the set fips202 admitted.

**D11 — `test/receipts/` and `test/tools/Receipts.lean` are new.** The brief
asked for the join to be "checked by a script". It is checked in Lean
instead, and the before-receipts are committed, so the whole comparison can
be rerun in-tree by anyone at any later commit rather than depending on a
scratch directory that no longer exists.

**D12 — two mistakes of the seat's own, both caught before they were
committed.** The first document-rename script rewrote `Sha256/` to
`Hash/Sha256/` in place and then applied the namespace rule, whose lookaround
does not exclude `/`; that double-prefixed 35 paths in `docs/SHA256-DAG.md`
to `Hash/Hash.Sha256/`. It was found by grepping for `Hash/Hash` and
repaired. The second used low control characters as substitution sentinels;
`U+000A` is a newline, so restoring it replaced every line break in
`docs/sha3/library-spec/SPEC.md`, collapsing 445 lines to one. The file was
restored from the index and the pass redone with private-use-area sentinels.
Both are recorded because a rename that silently corrupts prose is exactly
the failure this kind of move invites.

**D13 — not moved, not asked for.** `workshop/Sha256KernelProbe.lean` exists
in `lean4-WHATWG-streams` at `a1383bc` and is not in the brief's list; it
stayed there.

## 7. What the plan's checks returned

Every command below was run from the repository root with its output written
to a log file and its exit code appended to that file; the lines are quoted
from the files, not from a console.

| Command | Result |
| --- | --- |
| `lake --wfail build` | exit 0 in 92.2 s from a clean tree, `.lake/build` removed first |
| `lake --wfail build HashVerified` | exit 0 |
| `lake env leanchecker --fresh Hash.Verified` | exit 0 in 137.0 s, **empty output**, on the closure of that clean build |
| `lake env leanchecker --fresh Hash.NoSuchModule` | exit 1, `uncaught exception: Could not find any oleans for: Hash.NoSuchModule` — the control that shows the checker ran, and that an empty output above means "checked and silent" rather than "checked nothing" |
| `lake exe hash_sha256 --self-test` | `PASS sha256 self-test: 65 CAVP records from vendor/nist-cavp-sha256/SHA256ShortMsg.rsp and 65 from vendor/nist-cavp-sha224/SHA224ShortMsg.rsp reproduced, including Len = 0, 24, 440, 448 and 512 in each` |
| `lake exe hash_sha3_512sum --self-test` | `PASS sha3_512 self-test: 73 CAVP records from vendor/nist-cavp-sha3-512/SHA3_512ShortMsg.rsp reproduced, including Len = 0, 24, 568 and 576` |
| `lake exe hash_selftest` | `PASS combined self-test: 203 CAVP records reproduced across 3 sealed response file(s) through Hash.digestHex` |
| `lake exe hash_vendorseal` | `PASS vendor seal: manifest and vendor/ agree in both directions; every path is valid on Windows` |
| `lake exe hash_citations` | `PASS internal citations: 100 files scanned; no line-numbered citation into a protected authored document` |
| `lake exe hash_trustselftest` | `PASS trust self-test: every planted declaration was rejected for its stated reason and every control was accepted` |

## 8. Throughput

Recorded 2026-09-02 on this host from a clean build. The compiled binaries
under `.lake/build/bin/` are invoked directly, not through `lake exe`, so the
timed interval is process startup, file read, hash and output, and nothing
else. Three runs per case, median reported; all three runs agreed on the
digest in every case. Fixture generation and the independent cross-check are
outside the timed interval.

| Command | Input | Median | Runs (s) | Recorded before |
| --- | --- | --- | --- | --- |
| `hash_sha256` | 1 MiB | **0.059192 s** | 0.246169, 0.059192, 0.057193 | 0.058 s |
| `hash_sha256` | 16 MiB | **0.676698 s** | 0.676394, 0.676698, 0.758188 | 0.680 s |
| `hash_sha3_512sum` | 1 MiB | **0.664424 s** | 0.801481, 0.660297, 0.664424 | 0.823 s on this host; 0.634853 s in foldlab's own record |
| `hash_sha3_512sum` | 16 MiB | **9.701413 s** | 9.701413, 9.706067, 9.648456 | 9.875716 s in foldlab's own record |

Nothing regressed: both SHA-256 medians reproduce their recorded figures, and
both SHA3-512 medians are at or below theirs. The first run of a case is
sometimes slower — 0.246 s against 0.057 s on the 1 MiB SHA-256 case — which
is cold file cache, and is why the protocol takes a median of three rather
than a single reading.

**Independently cross-checked.** Every digest above was recomputed with .NET's
own implementations on the same files and agreed exactly:

| Input | Algorithm | Digest |
| --- | --- | --- |
| `rand-1.bin` | SHA-256 | `c1be467434050c686cd2b8901331e8c147b708c93febf097aae68e398a7954b5` |
| `rand-16.bin` | SHA-256 | `8849469a87e1f8dd39386df812053e3ca1ecc8fae358f68d6aa5994001332780` |
| `rand-1.bin` | SHA3-512 | `cc71aa08642a6e29fd73411a617341c6b3d6d97c1b67425cb69964548feab7f9186a6e9553bda3753204a988b33db187220c433432cde2ec86658216efb0f5bd` |
| `rand-16.bin` | SHA3-512 | `bca3e1f7c1cb51498610f08055d0a2205d2f929d4304464455c6f2e05fbd646d76f4881f78ebc59402df77cd905d6aa862a34509c2d640f8602b2914b6a0355c` |

SHA-256 through PowerShell `Get-FileHash -Algorithm SHA256`, SHA3-512 through
`[System.Security.Cryptography.SHA3_512]::HashData`. These are host
measurements and a finite agreement check on two files, not performance or
conformance theorems.

## 9. What is still open

- The macOS arm64 leg. Both families were replayed on two hosts in their
  source repositories; this package's own closure has been replayed on
  Windows x86-64 only. `lake env leanchecker --fresh Hash.Verified` and the
  gates need to be rerun there.
- lean4lean, which did not target v4.33.1 when this was written.
- Step 9 of the plan, **re-scoped by the finding in §4**: unifying `Digest`
  and `Hex` and restating the SHA3 `String`-typed theorems on `List Char`
  reaches 10 of the 45; the other 35 are refinement lemmas and would need
  their proofs reworked. A ruling is owed on whether that is worth doing or
  whether the SHA-3 family keeps `Classical.choice`.
- `HASH-SHA3-CE-*` rows. The SHA3 family arrived with its breaker batteries
  but with no counterexample register of the shape this repository keeps.
- Steps 6 to 9 of the plan, which are not this seat's: the two consumers
  taking the dependency, the tag, and strictness parity.

Nothing above is load-bearing for what §3 and §4 record.
