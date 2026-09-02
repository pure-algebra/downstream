# Provenance

Every pin this repository relies on, with its digest, how it was fetched, the
cross-check performed, and its license. This file owns that the bytes are
what they are claimed to be.

The SHA-2 rows below arrived with the SHA-256 tree from
`lean4-WHATWG-streams` at `a1383bc`, where they were established; only the
rows for pins this package does not carry were removed. The two FIPS 202 rows
were vendored here from the digests foldlab had already established for them,
which `docs/sha3/PROVENANCE.md` still states in its own words.
`docs/EXTRACTION-RECORD.md` records both.

A digest appearing twice — once in a source repository's ledger, once here —
is the point. It is checked, not copied: the vendored bytes were re-digested
by this package's own proved library, and the number came out the same.

Digest cross-check protocol: every digest is computed by the in-tree
`lake exe hash_sha256` and independently by PowerShell `Get-FileHash -Algorithm
SHA256`; both spellings must agree. The in-tree implementation is not merely
executable evidence here — its meaning is
`Hash.Sha256.Bridge.sha256_bridge` — but the second implementation is still
the reason a wrong in-tree digest could not have entered this file silently.

## Vendored, sealed

| Pin | Fetched | Command | Cross-check |
| --- | --- | --- | --- |
| NIST FIPS 180-4, *Secure Hash Standard (SHS)*, August 2015 (`vendor/nist-fips-180-4/NIST.FIPS.180-4.pdf`) | 2026-09-01, vendored under ruling R-8 | fetched with `Invoke-WebRequest https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.180-4.pdf`, then copied into `vendor/` byte-for-byte with `[IO.File]::WriteAllBytes` on the result of `[IO.File]::ReadAllBytes` (no text mode, no EOL handling) | `0455b406d89648d20cbde375561e19c245b9815e894164c2670772e3d54deb82`, 833,315 bytes; both implementations agree on the vendored copy and on the fetched copy, and the two copies have the same digest |
| NIST CAVP `SHA256ShortMsg.rsp`, CAVS 11.0, generated 2011-03-15, 65 vectors (`vendor/nist-cavp-sha256/SHA256ShortMsg.rsp`) | 2026-09-01 | read out of the **git object**, not a working tree: `git -C <clone> ls-tree -r 54e6068abd4658fd91203cae1c2316188ffa0e89 -- validation/vectors/nist/SHA256ShortMsg.rsp` gives blob `e14f5cbdb5d65468a0d8ada158bbcffcbf031742`, then `cmd /c "git -C <clone> cat-file blob e14f5cbd… > vendor/nist-cavp-sha256/SHA256ShortMsg.rsp"` (`cmd` redirection is binary-safe; PowerShell's is not). The clone is `kim-em/lean-crypto-hash` at `54e6068abd4658fd91203cae1c2316188ffa0e89` under foldlab `.reference/clones/` | `git hash-object --no-filters` on the vendored file returns `e14f5cbdb5d65468a0d8ada158bbcffcbf031742`, equal to the upstream `ls-tree` object hash, which no host setting or `text` attribute can affect; SHA-256 `294ecec26959357405a621121bbfb01db4d45b9e834624b2d71aedd94ffde019`, 10,031 bytes, agreed by both implementations |
| NIST CAVP `SHA224ShortMsg.rsp`, CAVS 11.0, generated 2011-03-15, 65 vectors (`vendor/nist-cavp-sha224/SHA224ShortMsg.rsp`) | 2026-09-02 | read out of the **git object**, the same way: `git -C <clone> ls-tree -r 54e6068abd4658fd91203cae1c2316188ffa0e89 -- validation/vectors/nist/SHA224ShortMsg.rsp` gives blob `ab3b099c73048c279c97f88c3a549e7545c3887b`, then `cmd /c "git -C <clone> cat-file blob ab3b099c… > vendor/nist-cavp-sha224/SHA224ShortMsg.rsp"` | `git hash-object --no-filters` on the vendored file returns `ab3b099c73048c279c97f88c3a549e7545c3887b`, equal to the upstream `ls-tree` object hash; SHA-256 `4cf7c594ec3a540880756e5cf5095a8b5c9194a8a7868d686efb47187c2e0330`, 9,511 bytes, agreed by `lake exe hash_sha256` (the proved library) and PowerShell `Get-FileHash -Algorithm SHA256` |
| NIST FIPS 202, *SHA-3 Standard*, August 2015 (`vendor/nist-fips-202/NIST.FIPS.202.pdf`) | 2026-08-24 by foldlab, vendored here 2026-09-02 | the transcription source `Hash/Sha3/Spec.lean` was written against, fetched by foldlab from `nvlpubs.nist.gov` and held at `.reference/papers/nist-2015-fips202-sha3-standard.pdf`; copied into `vendor/` byte-for-byte with `[IO.File]::WriteAllBytes` on the result of `[IO.File]::ReadAllBytes` (no text mode, no EOL handling) | `1592607831ff0908cc590632ce371c6c95e94025bb1a0c8ae90a4d0ec1ed025e`, 1,459,683 bytes — **equal to the digest foldlab's `docs/sha3/PROVENANCE.md` pinned for the file the transcription was read from**, so the bytes sealed here are the bytes the specification layer was written against. Source and vendored copy also share the git blob hash `deb8de5e588505c95f59081e337019b2817a58ee`, and `lake exe hash_sha256` and `Get-FileHash` agree |
| NIST CAVP `SHA3_512ShortMsg.rsp`, 73 vectors (`vendor/nist-cavp-sha3-512/SHA3_512ShortMsg.rsp`) | 2026-09-02 | read out of the **git object**, as the two SHA-2 files were: `git -C <clone> ls-tree -r 54e6068abd4658fd91203cae1c2316188ffa0e89 -- validation/vectors/nist/SHA3_512ShortMsg.rsp` gives blob `d9e6e36428a9db11834f106c80d153b2d03465ce`, then `cmd /c "git -C <clone> cat-file blob d9e6e364… > vendor/nist-cavp-sha3-512/SHA3_512ShortMsg.rsp"` | `git hash-object --no-filters` on the vendored file returns `d9e6e36428a9db11834f106c80d153b2d03465ce`, equal to the upstream `ls-tree` object hash; SHA-256 `11d0676f4c6f10e30c5025204f4e15cd1ef6b1e34f6660d586d8ae9dfab4d721`, 16,502 bytes — **equal to the digest foldlab pinned for the copy its known-answer theorems were transcribed from**, and independently re-fetched from NIST by foldlab on 2026-08-24 with the canonical texts byte-identical |

Every vendored file's digest and size are also in
`generated/vendor-manifest.tsv`, written by `lake exe hash_vendorseal --write`
through the proved library, and the seal checks the tree against it in both
directions.

The NIST pins carry no upstream license file. FIPS 180-4, FIPS 202, and the
CAVP response files are works of the US Government, not subject to copyright
in the United States; they are retained unmodified and are cited by section
and by record. The repository's own `LICENSE` (MIT since 2026-09-02) does not apply to
anything under `vendor/`.

`.gitattributes` disables end-of-line conversion for the whole repository
(`* -text`), so a checkout on any host reproduces the committed bytes and the
seal holds without a host-specific `core.autocrlf` setting.

**Why the blob-hash check exists.** In the repository this tree came from, a
first vendoring copied files out of a Windows working tree where the upstream
repository's own `text` attributes had converted every text file to CRLF on
checkout; `git archive` applied the same conversion. Two independent SHA-256
implementations agreed with each other on those bytes, and the seal passed,
because both were measuring the converted file. Only a comparison against the
upstream raw content exposed an 8,401-byte difference. Vendored files are now
written directly from upstream blob objects (`git cat-file blob <sha>`) and
verified against `git ls-tree` object hashes, which no attribute or host
setting can affect. Two agreeing digests of the same wrong bytes are not
provenance; the reference point has to be upstream's own identity of the
object.

## Toolchain and hosts

| Pin | Evidence |
| --- | --- |
| `leanprover/lean4:v4.33.1` | `lean-toolchain`; `elan show` lists the toolchain as installed. Every claim in this package names this kernel |
| Extraction host | Windows 11 (NT 10.0.26200), AMD Ryzen 7 8700F |

## Source repositories

Both families were moved here with their history preserved. These are not
third-party pins; they are the commits this package's own history continues
from, and `docs/EXTRACTION-RECORD.md` owns the detail.

| Source | Commit | Moved here |
| --- | --- | --- |
| `mepuka/lean4-WHATWG-streams` | `a1383bc09f945d37e464900a10515278c8a455b1` | `Hash/Sha256/**`, its witnesses, contract, proof graph, and the first three NIST pins above |
| `mepuka/foldlab`, `formal/fips202` and `.staging/fips202-library` | `64be4b2c8182f92997bffb3d47f7598d6a558ed4` | `Hash/Sha3/**`, `HashGates/Sha3.lean`, the FIPS 202 contract chain under `test/contracts/sha3/` and `docs/sha3/`. The two FIPS 202 pins above were vendored here at the same time, from the digests that repository had already established |

## Process precedents (not semantic pins)

| Source | Commit | Used for |
| --- | --- | --- |
| `mepuka/lean4-effect4` | `e9075e192bb3065e3900ccabe7c0c2a6df1ddffc` | the router hierarchy, breaker/builder order, counterexample register, assurance threshold, and the axiom gate, which reached this repository through `lean4-WHATWG-streams` |
| `kim-em/lean-crypto-hash` | `54e6068abd4658fd91203cae1c2316188ffa0e89`, Apache-2.0 | prior art read first-hand; no code imported. API shapes and the streaming technique are credited in `docs/SHA256-DAG.md` §3.5, and the two CAVP response files above are vendored out of its git objects |

## Pending

| Row | Needed by | State |
| --- | --- | --- |
| NIST SHA-256 example values (`abc`, the two-block message) | a future stage | not fetched. Nothing depends on it: every witness now in the tree comes from a sealed `.rsp` |
| A second external checker (lean4lean) | assurance diversity | admitted in the tool ledger, not run; it did not target v4.33.1 when this was written |
| macOS arm64 replay of this package's verified closure | dual-host assurance | not run here. Both families were replayed on two hosts in their source repositories; this package's own closure has been replayed on Windows x86-64 only |
