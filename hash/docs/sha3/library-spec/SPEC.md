# fips202 as a library — implementation spec

> **Moved document.** Authored in foldlab's `.staging/fips202-library/` and
> moved here, with its history, from commit `64be4b2c`. It is the library
> specification the SHA3 family was built to; declaration names and in-package
> paths have been rewritten to their spellings here. It describes stages S0-S2
> of that lane, which are complete; its later stages were not carried over and
> are not this package's plan. References to foldlab's own trees and tasks are
> historical.

Status: pre-grade, 2026-09-01. **R-1 APPROVED by the operator 2026-09-01 with the §9 defaults
for R-2–R-9 (docs/SPECS.md decision 45); §4 A1.S1 and A1.S2 are therefore the Pass B reopen
and their statements are FROZEN. The operator lifted the HOLD for S0–S2 on 2026-09-01 and
approved R-10's evidence split after S0 exposed the original import-graph contradiction.**
**S1 coordinator correction C-1 (2026-09-02): the S1 edit region includes only the existing
audit-verdict pin in `Hash/Sha3/Verified.lean`, as already required by S1 acceptance; and the
`Hash.Sha3.sha3_512` docstring is frozen with the exact trust-boundary sentence shown in A1.S1.**
**S2 coordinator correction C-2 (2026-09-02): S2 also permits updating the existing
`Hash/Sha3/Verified.lean` audit-count pin and the README's measured implementation description and
throughput record, as required by S2 acceptance. No frozen declaration changes.**
Author: coordinator (Fable), from a first-hand read of `formal/fips202` and the pinned Lean
`v4.33.1` sources.

Audience: the operator (rulings in §9) and the implementing seats (everything else). A seat
receives this document plus the name of ONE stage in §6 and nothing more.

## 0. How to use this document

**Roles.** The coordinator owns statements and this document. The operator owns rulings. A seat
implements one stage: definitions, proofs, gates, the report. A seat never changes a frozen
statement, never mints a ruling, never commits, never pushes.

**Reading order for a seat.** `AGENTS.md` at the repo root whole; then this document §1–§5, the
seat's stage in §6, and §7–§8. Then the files named in the stage's edit region and nothing else.

**Stop conditions (report and stop, do not work around).**

1. The stage cannot be completed without changing the body of any definition in
   `Hash/Sha3/Spec.lean` or `Hash/Sha3/Impl.lean`, or the statement of any theorem in §4.
2. A proof needs an axiom outside `[propext, Classical.choice, Quot.sound]`, or a tactic in
   §3.3's forbidden list.
3. A known-answer check fails. The literal is never adjusted; the failure is the finding.
4. A dependency (Mathlib, Batteries, any `[[require]]`) would be needed.
5. The per-stage budget in §6 is exceeded by more than half.

**Report shape (mandatory).** Every command run, verbatim; every log written to a file and the
path given; the exact pass line quoted from the file, never from the console; the timing table
the stage asks for; the audit summary line; the list of every new declaration with its statement;
anything left out, named. Exit codes are read from the file, never from a piped console (house
lesson, `docs/sha3/TOOLING-NOTES.md` items 3–5).

## 1. Goals and non-goals

**Goal.** `formal/fips202` becomes a Lean 4 library a consumer imports for a SHA3-512 digest
over `ByteArray`, at native speed, with the refinement theorem to the FIPS 202 transcription as
the documentation of what the digest means. Later stages extend the same proof spine to the SHA3
family and SHAKE, and add a streaming interface.

**Non-goals (unchanged from the ratified contract).** Security claims of any kind; injectivity of
the hash; conformance beyond the pinned vectors; performance CLAIMS as theorems (measurements are
recorded, never proved); bit-level (non-byte-aligned) messages at the executable layer.

**What is preserved untouched.** `Hash/Sha3/Spec.lean` byte for byte. Every definition body in
`Hash/Sha3/Impl.lean`. Every theorem statement already landed (the REV2 frozen list in
`test/contracts/sha3/PASSB-SNAPSHOT.md`). The trust statement in `docs/sha3/README.md`: two
things to trust, the transcription and the `v4.33.1` kernel.

## 2. Measured baseline (2026-09-01, Windows x86-64, toolchain v4.33.1)

Fresh `lake build` of `formal/fips202` after `lake clean`, 81.6 s wall, exit 0, zero warnings,
70 axiom reports all within the allowlist:

| Module | Wall | What the time is |
|---|---|---|
| `Hash.Sha3.Spec` | 17 s | ran concurrently with the next two; treat the three as one 17 s tranche |
| `Hash.Sha3.Impl` | 17 s | four compiled CAVP `#guard`s |
| `Hash.Sha3.KeccakProbe` | 17 s | a verbatim duplicate of Impl's permutation with the same KAT as `Hash.Sha3.Kats.kat_keccakF_zero` |
| `Hash.Sha3.Structural` | 0.8 s | |
| `Hash.Sha3.Theorems` | 4.7 s | T1/T2 by `decide` |
| `Hash.Sha3.Roundtrips` | 58 s | two `decide`s over 256 byte cases (`byte_roundtrip_fin`, `bits_byte_roundtrip`) |
| `Hash.Sha3.Kats` | 59 s | two SHA3-512 digests reduced in the kernel; the shell measured 41 s / 6.0 GB for the same module |
| `Hash.Sha3.Bridge` | 4.7 s | the whole refinement spine |

Runtime of the executable layer, from the F-47 commit record (compiled, this host): 1 MB hashes
in 20.7 s. Cause: `BitVec 64` is `Fin (2^64)` and therefore a `Nat` at runtime
(`Init/Prelude.lean`, `structure BitVec`), so lanes with the top bit set are bignums and every
xor and rotate allocates; `List UInt8` boxes every byte.

Consumer today (`experiments/entity-store-shell`): `import Hash.Sha3` (pays all of the above), calls
`Hash.Sha3.Impl.sha3_512 : List UInt8 → List UInt8`, re-implements hex in `Shell/Hex.lean`, bridges
`ByteArray` to `List` by hand, and asserts the 64-byte width at its boundary with no theorem
behind it because no Impl-level length theorem exists.

## 3. Standing constraints

### 3.1 Estate law that binds every stage

- Toolchain `leanprover/lean4:v4.33.1` exactly (`formal/fips202/lean-toolchain`). No change.
- Zero Lake dependencies (`lake-manifest.json` packages stay `[]`).
- Axiom allowlist: `propext`, `Quot.sound`, `Classical.choice`. Nothing else, ever.
- `Hash/Sha3/Spec.lean`: no edits. `Hash/Sha3/Impl.lean`: no edits to existing definitions; additions only
  where a stage says so.
- Every `Hash.Sha3.*` module is free of `unsafe`, `opaque`, `partial`, `implemented_by`, `extern`,
  and `IO`. The consumer's whole-package gate scans the `Hash.Sha3` namespace for the first two
  (`experiments/entity-store-shell/Shell/Gate.lean`); keep it green.
- `lake --wfail build` is the build. Warnings are errors.
- Commit minting is a gated step performed by the coordinator, never by a seat
  (`TOOLING-NOTES.md` item 7).

### 3.2 Built-ins to use (the API sweep, pinned to the v4.33.1 sources)

Paths are under `.reference/clones/lean4-v4.33.1/src/`.

| Need | Use | Where | Why this one |
|---|---|---|---|
| Native lane | `UInt64` with `^^^ &&& ||| ~~~ <<< >>>` | `Init/Data/UInt/Basic.lean` | Unboxed at runtime. Each operator has a `rfl` lemma to `BitVec`: `UInt64.toBitVec_xor/and/or/not/shiftLeft/shiftRight` (`Init/Data/UInt/Bitwise.lean:30–35`), so `Fast = Impl` is pointwise `simp` |
| Lane rotate | own `rotl x n := (x <<< n.toUInt64) ||| (x >>> (64 - n).toUInt64)` | core has no `UInt64.rotateLeft` (only `BitVec.rotateLeft`, `Init/Data/BitVec/Basic.lean:642`) | one lemma `toBitVec_rotl` is owed, via `BitVec.eq_of_getLsbD_eq` (`BitVec/Bootstrap.lean:36`), `getLsbD_or` (Lemmas 1375), `getLsbD_shiftLeft` (1881), `getLsbD_ushiftRight` (2083), `getLsbD_rotateLeft` (5028), and `omega`. Note the shift lemmas take the amount as `b.toBitVec % 64`; `getLsbD_shiftLeft'` (2063) covers the BitVec-amount form |
| Byte↔lane arithmetic | `UInt64.toUInt8`, `UInt8.toUInt64`, `UInt64.toNat_toUInt8`, `toNat_toUInt64` | `UInt/BasicAux.lean:302,323`; `UInt/Lemmas.lean:218,239` | `toNat_toUInt8 : x.toUInt8.toNat = x.toNat % 2^8` is `rfl`; pair with `Nat.testBit_mod_two_pow`, `BitVec.testBit_toNat` as `Hash.Sha3.Bridge.byteSliceBit` already does |
| Fixed-size state | `Vector UInt64 25` | `Init/Data/Vector/Basic.lean` | keep the flat 25-lane layout of Impl (index `x + 5y`); do not adopt the nested 5×5 of the prior art. `Vector.ofFn` + `getElem_ofFn` (`Vector/OfFn.lean:27`), `getElem_set_self/ne` (Lemmas 1304/1309), `getElem_map` (1490), `getElem_replicate` (2139), `getElem_zipWith` (3008), `mapFinIdx` + `getElem_mapFinIdx` (`MapIdx.lean:23`) |
| Byte carrier | `ByteArray` | `Init/Data/ByteArray/Basic.lean` | the runtime's contiguous bytes. Reason through `bs.data` (an `Array UInt8`) and `bs.data.toList`, NOT through `ByteArray.toList` (a loop with two lemmas). Lemmas: `size_append`, `getElem_append_left/right`, `size_extract`, `getElem_extract`, `getElem_eq_getElem_data`, `ext_getElem`, `data_append`, `toList_data_append'` (`ByteArray/Lemmas.lean`, `Bootstrap.lean`) |
| List ↔ ByteArray | `List.toByteArray`, `List.toList_data_toByteArray`, `List.size_toByteArray`, `List.getElem_toByteArray`, `List.toByteArray_append` | `ByteArray/Bootstrap.lean`, `Lemmas.lean` | the correspondence the Impl bridge is stated on |
| Total byte read | own `byteAt (bs : ByteArray) (i : Nat) : UInt8 := if h : i < bs.size then bs[i] else 0` | | no `!`, no panic path, and it is exactly `List.getD _ 0` on `bs.data.toList` |
| Bounded loops in definitions | `Nat.fold n (fun i h acc => …)` | `Init/Data/Nat/Fold.lean:268–274` (`fold_zero`, `fold_succ`, `fold_eq_finRange_foldl`) | index with proof, and an induction principle. `List.range n |>.foldl` as Impl uses is also fine; do not mix styles inside one stage |
| Round trip of 8 bits | `Nat.eq_of_testBit_eq`, `Nat.testBit_lt_two_pow`, `Nat.testBit_shiftRight`, `Nat.testBit_and` | `Init/Data/Nat/Bitwise` | replaces the 256-case `decide`s |
| Hex | own two-char table over `Fin 16` | | `Nat.toDigits 16` (`Init/Data/Repr.lean:217`) has no padding and no lemmas; `BitVec.toHex` (`BitVec/Basic.lean:209`) uses `String.Internal` and its own comment says not to prove about it |
| UTF-8 convenience | `String.toUTF8` (`Init/Data/String/Defs.lean:76`), `String.fromUTF8?` (`String/Basic.lean:185`) | | wrappers only; no theorem is stated about either |
| Kernel-side decision | `decide +kernel` | `Init/Tactics.lean:1385,1416` | kernel reduction, no new axiom; allowed where a finite check is wanted and `rfl` is awkward |
| Axiom audit | `Lean.collectAxioms` | `Lean/Util/CollectAxioms.lean:149` | what `#print axioms` calls (`Lean/Elab/Print.lean:241`); lets a module fail the build on an offender instead of printing 70 info lines |
| Lake metadata | `description`, `keywords`, `license`, `licenseFiles`, `readmeFile`, `version`, `testDriver`, `leanOptions` | `lake/Lake/Config/PackageConfig.lean:112–263`, `LeanConfig.lean` | see §5.2 |

### 3.3 Built-ins and idioms NOT to use, with the reason

| Do not | Because |
|---|---|
| `bv_decide`, `native_decide`, `decide +native` | they close through `Lean.ofReduceBool` (`Init/Core.lean:2436`), outside the allowlist; the gate fails |
| `BitVec 64` in any definition an executable calls | `Nat` at runtime (§2) |
| `xs[i]!` in new code | forces the `vget` plumbing every Bridge lemma opens with, and compiles to a bounds check plus panic path; index with a proof |
| `Id.run do` with `for`/`mut` in a definition a theorem is stated about | the prior art's style; unfoldable only through `forIn` lemmas; use `Vector.ofFn`, `Nat.fold`, or structural recursion |
| `ByteArray.toList`, `ByteArray.foldl`, `ByteArray.toUInt64LE!` | thin or no lemma support; the last one panics on size ≠ 8 |
| `#print axioms` inside library modules | 70 info lines into every consumer's build log; the audit module (§6 S0.4) replaces them with one typed verdict |
| A `rfl`/`decide` KAT on the `Fast` layer | the kernel never runs `Fast`; KATs stay on `Impl`, `Fast` is proved equal to it |
| Adding `[[require]]` | zero-dependency is a property of this artifact's trust statement |
| Lean's `module` system (`module`, `public import`, `@[expose]`) | optional and consequential: `requiresModuleSystem` forces every downstream package to adopt module headers (`lake/Lake/Config/LeanConfig.lean:280`), and the shell has none. Ruling §9 R-6; default: not adopted |

## 4. Statement addendum A1 (FROZEN 2026-09-01, decision 45)

New public declarations, by stage. Names are final; a seat that needs a different shape stops.
`Impl` means `Hash.Sha3.Impl`, `Spec` means `Hash.Sha3.Spec`, `Bridge` means `Hash.Sha3.Bridge`.

### A1.S0 (no new statements; retargeted proofs only)

The public statements of `Hash.Sha3.Roundtrips` (`byte_roundtrip`, `bytes_bits_roundtrip`,
`bits_bytes_roundtrip`, `bits_state_roundtrip`, the three length lemmas) are unchanged. Only
private helpers may change. The fully qualified name and proposition of
`Hash.Sha3.Bridge.sha3_ne_prefips_spec` are unchanged; R-10 moves that evidence theorem from the API
module `Hash.Sha3.Bridge` to the evidence-only module `Hash.Sha3.BridgeEvidence`.

### A1.S1 — API over Impl

```lean
namespace Hash.Sha3

/-- A byte string whose length is carried by its type. -/
structure Digest (n : Nat) where
  bytes : ByteArray
  size_eq : bytes.size = n

namespace Digest
def toByteArray (d : Digest n) : ByteArray := d.bytes
def toList (d : Digest n) : List UInt8 := d.bytes.data.toList
def toHex (d : Digest n) : String
def ofHex? (n : Nat) (s : String) : Option (Digest n)
theorem ext {a b : Digest n} (h : a.bytes = b.bytes) : a = b
theorem size_toByteArray (d : Digest n) : d.toByteArray.size = n
theorem length_toList (d : Digest n) : d.toList.length = n
theorem length_toHex (d : Digest n) : d.toHex.length = 2 * n
theorem ofHex?_toHex (d : Digest n) : ofHex? n d.toHex = some d
instance : BEq (Digest n)
instance : DecidableEq (Digest n)
end Digest

namespace Hex
def encode (bs : ByteArray) : String          -- lowercase, two chars per byte, no separators
def decode? (s : String) : Option ByteArray   -- lowercase digits only; none on odd length or bad char
theorem length_encode (bs : ByteArray) : (encode bs).length = 2 * bs.size
theorem decode?_encode (bs : ByteArray) : decode? (encode bs) = some bs
theorem encode_lower (bs : ByteArray) : ∀ c ∈ (encode bs).toList, c.toLower = c
end Hex

/-- SHA3-512 of a byte string. Meaning: `sha3_512_spec`. Trust boundary: the FIPS 202
transcription and the Lean v4.33.1 kernel. -/
def sha3_512 (msg : ByteArray) : Digest 64

/-- SHA3-512 of a string's UTF-8 bytes. -/
def sha3_512String (s : String) : Digest 64 := sha3_512 s.toUTF8

theorem sha3_512_impl (msg : ByteArray) :
    (sha3_512 msg).toList = Impl.sha3_512 msg.data.toList
theorem sha3_512_spec (msg : ByteArray) :
    (sha3_512 msg).toList = Spec.sha3_512_bytes msg.data.toList
theorem sha3_512_ofList (l : List UInt8) :
    (sha3_512 l.toByteArray).toList = Impl.sha3_512 l

end Hash.Sha3

namespace Hash.Sha3.Impl
theorem length_sha3_512 (msg : List UInt8) : (sha3_512 msg).length = 64
theorem length_keccak512_prefips (msg : List UInt8) : (keccak512_prefips msg).length = 64
theorem padBytes_prefix (msg : List UInt8) : (padBytes msg).take msg.length = msg
theorem length_padBytes (msg : List UInt8) : (padBytes msg).length % rateBytes = 0
theorem length_padBytes_pos (msg : List UInt8) : msg.length < (padBytes msg).length
end Hash.Sha3.Impl
```

The two `Impl` length theorems live in a new file `Hash/Sha3/Lengths.lean`, not in `Impl.lean`.

### A1.S2 — the native layer

```lean
namespace Hash.Sha3.Fast

abbrev Lane := UInt64
abbrev State := Vector Lane 25

def rotl (x : Lane) (n : Nat) : Lane
def rcv : Vector Lane 24                       -- the same 24 literals as Impl.rcv
def rhov : Vector Nat 25                       -- the same 25 literals as Impl.rhov
def theta (a : State) : State
def rhoPi (a : State) : State
def chi (a : State) : State
def rnd (a : State) (i : Fin 24) : State
def keccakF (a : State) : State

def byteAt (bs : ByteArray) (i : Nat) : UInt8
def laneAt (bs : ByteArray) (off i : Nat) : Lane   -- bytes off+8i … off+8i+7, little-endian, absent = 0
def absorbBlock (s : State) (bs : ByteArray) (off : Nat) : State
def absorbAll (P : ByteArray) : State              -- Nat.fold over P.size / 72 blocks at offset 72*i
def padBytes (msg : ByteArray) : ByteArray
def squeeze (s : State) : ByteArray                -- 64 bytes: lanes 0–7 little-endian
def sha3_512 (msg : ByteArray) : ByteArray

/-- Abstraction to the proved layer. -/
def abs (s : State) : Impl.St := s.map UInt64.toBitVec

theorem toBitVec_rotl (x : Lane) (n : Nat) (h : n < 64) :
    (rotl x n).toBitVec = x.toBitVec.rotateLeft n
theorem rcv_eq (i : Fin 24) : (rcv[i]).toBitVec = Impl.rcv[i]
theorem rhov_eq : rhov = Impl.rhov
theorem theta_abs (s : State) : abs (theta s) = Impl.theta (abs s)
theorem rhoPi_abs (s : State) : abs (rhoPi s) = Impl.rhoPi (abs s)
theorem chi_abs (s : State) : abs (chi s) = Impl.chi (abs s)
theorem rnd_abs (s : State) (i : Fin 24) : abs (rnd s i) = Impl.rnd (abs s) i.val
theorem keccakF_abs (s : State) : abs (keccakF s) = Impl.keccakF (abs s)
theorem byteAt_eq (bs : ByteArray) (i : Nat) : byteAt bs i = bs.data.toList.getD i 0
theorem laneAt_eq (bs : ByteArray) (off i : Nat) :
    (laneAt bs off i).toBitVec = Impl.laneOfBytes (bs.data.toList.drop off) i
theorem padBytes_eq (msg : ByteArray) :
    (padBytes msg).data.toList = Impl.padBytes msg.data.toList
theorem absorbAll_abs (P : ByteArray) : abs (absorbAll P) = Impl.absorbAll P.data.toList
theorem squeeze_eq (s : State) :
    (squeeze s).data.toList = ((List.range 8).map fun i => Impl.bytesOfLane (abs s)[i]!).flatten
theorem size_squeeze (s : State) : (squeeze s).size = 64

/-- The apex of the native layer. -/
theorem sha3_512_eq_impl (msg : ByteArray) :
    (sha3_512 msg).data.toList = Impl.sha3_512 msg.data.toList
theorem size_sha3_512 (msg : ByteArray) : (sha3_512 msg).size = 64

end Hash.Sha3.Fast
```

On S2 landing, `Hash.Sha3.sha3_512` (A1.S1) is redefined to call `Fast.sha3_512`; the statements
`sha3_512_impl`, `sha3_512_spec`, `sha3_512_ofList` do not change and are re-proved through
`Fast.sha3_512_eq_impl`.

### A1.S3 — the family (statements to be elaborated by the coordinator after S2 lands)

Shapes, not yet frozen: `Impl.spongeBytes (rateBytes : Nat) (suffixBits : List Bool)
(outBytes : Nat) (msg : List UInt8) : List UInt8` with a multi-block squeeze;
`Impl.sha3_512_eq_sponge : sha3_512 msg = spongeBytes 72 [false, true] 64 msg`;
`Bridge.spongeBytes_bridge` relating it to `Spec.sponge (8 * rateBytes) (bitsOfBytes msg ++
suffixBits) (8 * outBytes)` under `0 < rateBytes ≤ 200` and `suffixBits.length < 8`;
`Fast.sponge` mirroring it; API `digest : Algorithm → ByteArray → Digest (outputBytes alg)`,
`shake128`, `shake256`. SHAKE spec definitions (§6.2 of FIPS 202, suffix `1111`) go in a NEW file
`Hash/Sha3/SpecXof.lean`; `Spec.lean` stays byte-identical. Ruling §9 R-4 opens this stage.

### A1.S4 — streaming (after S3)

`Hash.Sha3.Context` with `init`, `update`, `finalize`; laws `update_empty`, `update_append`
(`(c.update a).update b = c.update (a ++ b)`), and `finalize_init_update`
(`((init .sha3_512).update m).finalize = sha3_512 m`). Statements elaborated after S3.

## 5. Target layout

### 5.1 Modules

```
formal/fips202/
  Hash/Sha3.lean               -- API root: imports Spec, Impl, Lengths, Theorems, Structural,
                          --   Roundtrips, Bridge, Hex, Digest, Api (S1), Fast (S2)
  Hash/Sha3/Spec.lean          -- frozen
  Hash/Sha3/Impl.lean          -- frozen definitions; the `!`-indexed proved reference
  Hash/Sha3/Lengths.lean       -- A1.S1 Impl length/padding theorems
  Hash/Sha3/Theorems.lean, Structural.lean, Roundtrips.lean  -- as today, minus #print axioms
  Hash/Sha3/Bridge.lean       -- refinement spine; Kats-free under R-10, minus #print axioms
  Hash/Sha3/BridgeEvidence.lean -- R-10: unchanged sha3_ne_prefips_spec, evidence closure only
  Hash/Sha3/Hex.lean           -- A1.S1
  Hash/Sha3/Digest.lean        -- A1.S1
  Hash/Sha3/Api.lean           -- A1.S1 public functions and their theorems
  Hash/Sha3/Fast.lean          -- A1.S2
  Hash/Sha3/Verified.lean      -- imports Hash.Sha3, Kats, KeccakProbe, BridgeEvidence, Audit; runs the audit
  Hash/Sha3/Kats.lean          -- as today (kernel KATs); reached only from Hash.Sha3.Verified
  Hash/Sha3/KeccakProbe.lean   -- as today; reached only from Hash.Sha3.Verified (ruling R-3 may delete)
  Hash/Sha3/Audit.lean         -- S0.4 axiom audit elaborator
  Gates/Sha3.lean            -- S1 executable root, top-level namespace (keeps Hash.Sha3.* IO-free)
```

Lake attributes a module to a library when a root is a prefix of its name
(`lake/Lake/Config/LeanLibConfig.lean`, `isLocalModule`/`isBuildableModule`), and `lake build
<lib>` builds the import closure of the library's roots. So two libraries with roots `Hash.Sha3` and
`Hash.Sha3.Verified` give: `import Hash.Sha3` builds spec, impl, bridge, API; `lake build HashVerified`
builds everything. A consumer that wants the KATs imports `Hash.Sha3.Verified`.

### 5.2 `lakefile.toml` (target)

```toml
name = "fips202"
version = "0.2.0"
description = "SHA3-512 from FIPS 202 in Lean 4: bit-level specification, native implementation, and the machine-checked refinement between them"
keywords = ["sha3", "keccak", "fips-202", "verified"]
license = "Apache-2.0"
readmeFile = "README.md"
defaultTargets = ["Hash.Sha3"]
testDriver = "HashVerified"
leanOptions = { autoImplicit = false, relaxedAutoImplicit = false, warningAsError = true }

[[lean_lib]]
name = "Hash.Sha3"

[[lean_lib]]
name = "HashVerified"
roots = ["Hash.Sha3.Verified"]

[[lean_exe]]
name = "sha3_512sum"
root = "Sha3Sum"
```

`testDriver` naming a library means `lake test` builds it (`PackageConfig.lean:112–121`); the
audit's `#guard_msgs` pin is the test. `licenseFiles` defaults to `LICENSE`; ruling R-7 decides
whether the artifact carries its own copy or the repo root's.

### 5.3 `mise.toml` (`check:fips202`, target)

```toml
run = [
  "lake --wfail build HashVerified",
  "lake env leanchecker --fresh Hash.Sha3.Verified",
]
```

## 6. Stages

Each stage: purpose, edit region, work, acceptance, budget. Budgets are wall-clock for one seat
on one host, excluding waiting on rulings. Stages are sequential; S1 may start once S0 is
reviewed, S2 once S1 is reviewed.

### S0 — Build cost and audit (no statement changes)

**Purpose.** A consumer's `import Hash.Sha3` stops paying for known-answer evidence and a retired
probe; the axiom profile becomes one typed verdict instead of 70 log lines.

**Edit region.** `Hash/Sha3.lean`, new `Hash/Sha3/Verified.lean`, new `Hash/Sha3/Audit.lean`, new
`Hash/Sha3/BridgeEvidence.lean`, `Hash/Sha3/Bridge.lean` only for R-10's import/theorem move,
`lakefile.toml`, `Hash/Sha3/Roundtrips.lean` (private helpers only), removal of `#print axioms` lines
from every `Hash/Sha3/*.lean`, `mise.toml` task `check:fips202`, `README.md` checking/trust wording,
and the R-7 `LICENSE` copy.

**Work.**

- S0.1 Root split per §5.1 and §5.2. `Hash/Sha3.lean` drops `Hash.Sha3.KeccakProbe` and `Hash.Sha3.Kats`.
  Under R-10, `Hash/Sha3/Bridge.lean` also drops its `Hash.Sha3.Kats` import and the unchanged declaration
  `Hash.Sha3.Bridge.sha3_ne_prefips_spec` moves to new `Hash/Sha3/BridgeEvidence.lean`, which imports
  `Hash.Sha3.Bridge` and `Hash.Sha3.Kats`. `Hash/Sha3/Verified.lean` imports `Hash.Sha3`, `Hash.Sha3.Kats`,
  `Hash.Sha3.KeccakProbe`, `Hash.Sha3.BridgeEvidence`, `Hash.Sha3.Audit` and ends with the audit command under a
  `#guard_msgs` pin. Thus `import Hash.Sha3` is evidence-free while `import Hash.Sha3.Verified` retains the
  theorem at the same fully qualified name and proposition.
- S0.2 Retarget the two `decide`s in `Hash/Sha3/Roundtrips.lean`. Route A (preferred): structural
  proofs. `byte_roundtrip_fin` becomes a proof of `byteOfBits (bitsOfByte b) = b` through
  `UInt8.toNat` injectivity (`UInt8.toNat_inj` or `UInt8.ext`) and `Nat.eq_of_testBit_eq`, after
  rewriting `List.range 8` to its literal (`rfl`) and unfolding the eight-term fold. Route B
  (fallback, only if A exceeds 2 h): `decide +kernel`, with the measured time in the report. The
  module's fresh build must drop below 5 s on Route A; Route B is reported with its number and
  is a finding, not a completion.
- S0.3 `Hash/Sha3/KeccakProbe.lean` is unchanged and reached only from `Hash.Sha3.Verified`.
- S0.4 `Hash/Sha3/Audit.lean`: `elab "#sha3_axiom_audit" : command`. Walk `env.constants`; keep
  constants whose module (via `env.getModuleIdxFor?` and `env.allImportedModuleNames`) has the
  prefix `Hash.Sha3` and is not `Hash.Sha3.Audit`; skip compiler-generated names the way
  `experiments/entity-store-shell/Shell/Gate.lean` (`isInternal`) does; for each remaining
  theorem or definition call `Lean.collectAxioms`; any axiom outside
  `[propext, Classical.choice, Quot.sound]` is an offender. `throwError` listing offenders if
  any; `logInfo` exactly one line otherwise:
  `sha3 axiom audit: <N> declarations across <M> modules; allowlist [propext, Classical.choice, Quot.sound]; 0 offenders`.
  Also `throwError` if `N < 70` (the gate must be shown to have scanned something). In
  `Hash/Sha3/Verified.lean`: `/-- info: sha3 axiom audit: … -/ #guard_msgs in #sha3_axiom_audit` with
  the exact counts, so any drift in the declaration count is a build error to be updated
  deliberately.
- S0.5 Delete every `#print axioms` line from `Hash/Sha3/*.lean`. Update `README.md` §Checking it
  yourself to the §5.3 commands and to say the audit's line is the axiom record.
- S0.6 `lakefile.toml` per §5.2 (the `lean_exe` entry waits for S1).

**Acceptance (all from log files).**

1. `lake clean; lake --wfail build` (root `Hash.Sha3`): exit 0, "Build completed successfully", and
   `Hash.Sha3.Kats`/`Hash.Sha3.KeccakProbe` absent from the job list.
2. `lake --wfail build HashVerified`: exit 0; the `#guard_msgs` pin passes.
3. `lake env leanchecker --fresh Hash.Sha3.Verified`: exit 0, empty output, and the report shows the
   command was run against that module (item 3 of `TOOLING-NOTES.md`).
4. Timing table, fresh build, per module, for both `Hash.Sha3` and `HashVerified`. Targets:
   `Hash.Sha3` closure ≤ 30 s wall on this host; `Hash.Sha3.Roundtrips` ≤ 5 s.
5. `experiments/entity-store-shell`: `lake --wfail build` exit 0 unchanged (it imports `Hash.Sha3`;
   its `Shell/Hash.lean` relies on `Hash.Sha3.Kats` existing only in prose, verify it still elaborates).
6. `git diff --stat` in the report; no commit.

**Budget.** 1 day.

### S1 — Public API over Impl

**Purpose.** A consumer imports `Hash.Sha3` and gets a `ByteArray → Digest 64` function whose
docstring names the theorem that gives it meaning, plus hex and length facts.

**Edit region.** New `Hash/Sha3/Lengths.lean`, `Hash/Sha3/Hex.lean`, `Hash/Sha3/Digest.lean`, `Hash/Sha3/Api.lean`,
`Gates/Sha3.lean`; `Hash/Sha3.lean` imports; `lakefile.toml` `lean_exe`; `README.md` §Library API (new);
`Hash/Sha3/Verified.lean` only to update the existing audit-verdict count pin;
`Hash/Sha3/Bridge.lean` ONLY to remove `private` from `length_squeezeBytes`, `getD_squeezeBytes`,
`getD_bitsOfBytes` if a Lengths proof needs them.

**Work.** Implement A1.S1 exactly. `sha3_512 msg := ⟨(Impl.sha3_512 msg.data.toList).toByteArray,
by rw [List.size_toByteArray, Impl.length_sha3_512]⟩`. `sha3_512_impl` is
`List.toList_data_toByteArray`; `sha3_512_spec` composes it with `Bridge.sha3_512_bridge`.
Docstring of `sha3_512` names `sha3_512_spec` and states the trust base in one sentence.
`Hash/Sha3/Api.lean` ends with the four CAVP `#guard`s restated on the API (`(sha3_512
ByteArray.empty).toHex == "a69f…"` etc.; literals copied from `Hash/Sha3/Impl.lean`, never retyped).
`Gates/Sha3.lean`: `main` reads a file path argument or stdin, prints `<hex>  <name>` like
`sha3sum`; it is the only IO in the package and lives outside the `Hash.Sha3` namespace.

**Acceptance.** S0's items 1–3, 5, 6, plus: `lake exe sha3_512sum` on an empty file prints the
Len=0 CAVP digest; `#check` of every A1.S1 name in the report; the audit line's counts updated in
`Hash/Sha3/Verified.lean`; consumer migration note (§8) attached but not applied.

**Budget.** 1.5 days.

### S2 — Native layer

**Purpose.** Digest throughput at native speed with no change to what is proved.

**Edit region.** New `Hash/Sha3/Fast.lean`; `Hash/Sha3/Api.lean` (retarget `sha3_512` to
`Fast.sha3_512`, re-prove the three API theorems); `Hash/Sha3.lean` import; `Gates/Sha3.lean` unchanged
(it calls the API); `Hash/Sha3/Verified.lean` only for the existing audit-count pin; `README.md`
only for the native implementation description and measured throughput record.

**Work.** Implement A1.S2. Definitions mirror `Impl` line for line with `UInt64` for `BitVec 64`,
`rotl` for `rotateLeft`, proof-indexed access for `!`. Proof order: `toBitVec_rotl`; the
table lemmas by `decide` (24 and 25 literal comparisons; if `decide` is slow use `rfl` per
entry via `Vector.ext`); the four step lemmas by `funext`-free `Vector.ext` + `getElem_ofFn`
+ `getElem_map` + the `UInt64.toBitVec_*` simp set; `keccakF_abs` by the same list induction
as `Bridge.keccakF_bridge`; `laneAt_eq` by unfolding both eight-term folds and
`byteAt_eq`; `absorbAll_abs` by induction on the block count with `Nat.fold_succ` against
`Bridge.absorbAll_eq`'s indexed form (each step: `absorbBlock` at offset `72*i` equals
`Impl.absorbBlock` on `(P.drop (72*i)).take 72`, pointwise through `laneAt_eq` and
`List.getD` on `take`/`drop`); `squeeze_eq` by `ByteArray.ext_getElem` against
`Bridge.getD_squeezeBytes` (made public in S1 if needed); `sha3_512_eq_impl` composes.

**Acceptance.** S0's items 1–3, 5, 6; `Hash.Sha3.Fast` fresh build ≤ 30 s; the four API `#guard`s
now exercise `Fast`; throughput protocol: build `sha3_512sum`, generate a 1 MiB file of pseudo-
random bytes and a 16 MiB one, run each three times with `Measure-Command`, report the median.
Target: 1 MiB ≤ 1.0 s wall (baseline 20.7 s). Report peak memory if the host makes it cheap to
read. Both numbers are recorded in the report and in `README.md` as measurements, not claims.

**Budget.** 3 days.

### S3 — Family and SHAKE (opens on ruling R-4)

Coordinator freezes A1.S3 statements first. Then: `Impl.spongeBytes` and `Fast.sponge`; the
generalized padding, absorb, and multi-block squeeze bridges; `Hash/Sha3/SpecXof.lean`; API
`Algorithm`, `digest`, `shake128`, `shake256`; compiled `#guard`s for two vectors per variant
(one short, one at the rate boundary) from the vendored CAVP files
`.reference/clones/lean-crypto-hash/validation/vectors/nist/SHA3_{224,256,384}ShortMsg.rsp`,
`SHAKE{128,256}ShortMsg.rsp`, `SHAKE{128,256}VariableOut.rsp`, each pinned into
`.reference/provenance/fips202.lock.json` by the coordinator before the seat starts. Kernel KATs
for the new variants are a ruling (R-8), default none. Budget 5 days.

### S4 — Streaming (after S3)

`Hash.Sha3.Context` per A1.S4 with the buffered-update law. The technique is the prior art's
`updateBuffered_append` (kim-em/lean-crypto-hash, `Crypto/Hash/Streaming.lean`), credited in the
file header and reproved here. Budget 2 days.

### S5 — Assurance record

Run lean4lean against `Hash.Sha3.Verified` and record it in `PROVENANCE.md` (the open follow-up);
dual-host axiom parse (PC and Mac) as `(declaration, axiom-set)` pairs, never raw lines;
fetch and pin the NIST example-values file and add "abc" as a compiled guard. Budget 1 day.

## 7. Verification commands (run from `formal/fips202` unless stated)

```
lake clean
lake --wfail build                    2>&1 | Tee-Object -FilePath <log-root>.txt
lake --wfail build HashVerified       2>&1 | Tee-Object -FilePath <log-verified>.txt
lake env leanchecker --fresh Hash.Sha3.Verified 2>&1 | Tee-Object -FilePath <log-checker>.txt ; $LASTEXITCODE
lake exe sha3_512sum <file>
```

In `experiments/entity-store-shell`: `lake --wfail build`. The exit code of every command is
captured to the log file on its own line by the seat's script; a report that quotes a console
tail is returned to the seat.

## 8. Consumer migration (entity-store-shell), for a later seat, not part of S0–S2

- `Shell/Hash.lean`: `H b := ⟨(Hash.Sha3.sha3_512 b.toByteArray).toList⟩` or keep the `Impl` call;
  either way `H_bytes` stays `rfl` through `Hash.Sha3.sha3_512_ofList`. The width obligation the
  shell states in prose becomes `Hash.Sha3.Digest.length_toList`.
- `Shell/Hex.lean`: `hexOfBytes`/`bytesOfHex` become `Hash.Sha3.Hex.encode`/`decode?` on the
  `ByteArray` side of its own boundary; the lowercase-only rule is preserved by construction.
- `Shell/Gate.lean`: `coreNamespaces` gains nothing; the gate's module coverage is `Shell.*`
  and the roots, so the new `Hash.Sha3.*` modules are outside it. The G-S4 shadow scan now also sees
  `Hash.Sha3.sha3_512`, `Hash.Sha3.Hex.encode`, and the `Digest` names; confirm no `Shell` constant
  shadows them.
- `Shell/VectorTheorems.lean`: unchanged; it reasons about `Impl`, which is unchanged.

## 9. Rulings (R-1 approved 2026-09-01; R-2–R-9 ratified at their defaults the same day;
R-10 approved 2026-09-01 after S0's breaker/implementer loop)

| Id | Question | Ruling (was: default if silent) |
|---|---|---|
| R-1 | Approve §4 A1.S1 and A1.S2 as the Pass B reopen (additive statements, frozen bodies untouched) | approve |
| R-2 | Route B (`decide +kernel`) acceptable as a landing for S0.2 if Route A fails within budget | acceptable as a finding, not a completion |
| R-3 | Delete `Hash/Sha3/KeccakProbe.lean` (superseded by `Kats.kat_keccakF_zero` on identical definitions) or keep it under `Hash.Sha3.Verified` | keep under `Hash.Sha3.Verified` |
| R-4 | Open S3, including the additive `Hash/Sha3/SpecXof.lean` (Pass A scope: new spec definitions for §6.2 SHAKE, `Spec.lean` untouched) | closed until S2 is reviewed |
| R-5 | Hex decoding: lowercase-only (the shell's one-spelling rule) or case-insensitive (the prior art) | lowercase-only |
| R-6 | Adopt Lean's `module` system for sealed internals, forcing downstream packages to adopt it too | not adopted |
| R-7 | `LICENSE` file inside `formal/fips202` or `licenseFiles` pointed at the repo root | own copy, Apache-2.0 |
| R-8 | Kernel KATs for the S3 variants (each ~40–60 s and ~6 GB at build) | none; compiled guards only |
| R-9 | Toolchain policy for consumers: exact pin (today) or a stated floor | exact pin, stated in README |
| R-10 | Resolve the S0 contradiction `Hash.Sha3 → Bridge → Kats` while preserving the frozen evidence theorem | move unchanged `Hash.Sha3.Bridge.sha3_ne_prefips_spec` to new evidence-only `Hash.Sha3.BridgeEvidence`; expose it through `Hash.Sha3.Verified`, not `Hash.Sha3` |

## 10. Provenance of this document

Read first-hand on 2026-09-01: every file under `formal/fips202/`; the consumer modules named in
§2 and §8; the Lean sources at the `file:line` pins in §3 (clone
`.reference/clones/lean4-v4.33.1`, toolchain-matched); the prior art at
`.reference/clones/lean-crypto-hash` (`Crypto/SHA3/*.lean`, `Crypto/ByteVector.lean`,
`Crypto/Hash.lean`, `validation/CryptoValidation/Proofs.lean`, `README.md`). Measurements in §2
were taken in this session on this host; the 20.7 s figure is the F-47 commit's own record
(`git show 4603b3d6`).
