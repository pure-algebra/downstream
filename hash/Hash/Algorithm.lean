import Hash.Sha256
import Hash.Sha3

/-!
# `Hash.Algorithm` — the surface over both families

Three things live here: the algorithm tag, plain aliases for the three hash
functions, and an algorithm-indexed dispatch that is uniform in `ByteArray`.

## Why the dispatch is not dependently typed

Ruling HP-2 (parity later) leaves `Hash.Sha256.Digest` and `Hash.Sha3.Digest`
as two different types with the same shape. A dependently typed

```lean
def Algorithm.Digest : Algorithm → Type
  | .sha256 => Sha256.Digest 32
  | .sha224 => Sha256.Digest 28
  | .sha3_512 => Sha3.Digest 64

def digest : (alg : Algorithm) → ByteArray → alg.Digest
```

does typecheck, but it is not clean: `alg.Digest` reduces only when `alg` is
a literal, so a caller holding a variable algorithm cannot so much as write
`(digest alg msg).toHex` without matching on the algorithm first and getting
a different `toHex` in each branch. Every generic statement about the result
would need the same case split. That is a worse surface than the problem it
solves.

So this file takes the alias route the extraction plan defaults to.
`Hash.sha256`, `Hash.sha224` and `Hash.sha3_512` are plain aliases at their
family's own `Digest` type, and the indexed dispatch is stated at `ByteArray`
and `String`, which both families agree on:

- `digestBytes : Algorithm → ByteArray → ByteArray`, with
  `size_digestBytes` proving the width is `alg.outputBytes`;
- `digestHex : Algorithm → ByteArray → String`.

When step 9 of `docs/HASH-PACKAGE-PLAN.md` unifies `Digest` and `Hex`, a
single `digest : (alg : Algorithm) → ByteArray → Digest alg.outputBytes`
becomes available with no case split, exactly as `Hash.Sha256.digest`
already is across SHA-256 and SHA-224 — those two share a `Digest` type, so
the dependent form is clean there today. This file is what changes then; the
aliases and the meaning theorems below do not.

## What the dispatch means

`digestBytes` is not a new hash. Each branch is the family's own API
function, and the three `_spec` theorems below carry the meaning through the
dispatch: what `digestBytes` computes is the transcription of the standard,
by the same refinement the family already proved.
-/

namespace Hash

/-- The hash functions this package provides. -/
inductive Algorithm
  | sha256
  | sha224
  | sha3_512
  deriving DecidableEq, Repr, Inhabited

namespace Algorithm

/-- Digest width in bytes: FIPS 180-4 §1 for the first two, FIPS 202 §6.1 for
the third. -/
def outputBytes : Algorithm → Nat
  | .sha256 => 32
  | .sha224 => 28
  | .sha3_512 => 64

/-- The spelling used in reports and on the command line. -/
def name : Algorithm → String
  | .sha256 => "sha256"
  | .sha224 => "sha224"
  | .sha3_512 => "sha3-512"

/-- Every algorithm, so that a gate iterating over all of them cannot quietly
miss one when a fourth is added. -/
def all : List Algorithm := [.sha256, .sha224, .sha3_512]

end Algorithm

/-- SHA-256 of a byte string. Meaning: `Hash.Sha256.sha256_spec`. -/
abbrev sha256 (msg : ByteArray) : Sha256.Digest 32 := Sha256.sha256 msg

/-- SHA-224 of a byte string. Meaning: `Hash.Sha256.sha224_spec`. -/
abbrev sha224 (msg : ByteArray) : Sha256.Digest 28 := Sha256.sha224 msg

/-- SHA3-512 of a byte string. Meaning: `Hash.Sha3.sha3_512_spec`. -/
abbrev sha3_512 (msg : ByteArray) : Sha3.Digest 64 := Sha3.sha3_512 msg

/-- The digest of `msg` under `alg`, as bytes. Uniform in the algorithm
because `ByteArray` is what both families agree on; see the module
documentation for why this is not `Digest alg.outputBytes`. -/
def digestBytes : Algorithm → ByteArray → ByteArray
  | .sha256, msg => (sha256 msg).toByteArray
  | .sha224, msg => (sha224 msg).toByteArray
  | .sha3_512, msg => (sha3_512 msg).toByteArray

/-- The digest of `msg` under `alg`, as lowercase hexadecimal. Each branch
uses its own family's codec, which is why this is a definition and not
`Hex.encode ∘ digestBytes`: HP-2 leaves two codecs in the package, and this
one commits to each family's own. -/
def digestHex : Algorithm → ByteArray → String
  | .sha256, msg => (sha256 msg).toHex
  | .sha224, msg => (sha224 msg).toHex
  | .sha3_512, msg => (sha3_512 msg).toHex

/-- The dispatch produces the width its tag advertises. -/
theorem size_digestBytes (alg : Algorithm) (msg : ByteArray) :
    (digestBytes alg msg).size = alg.outputBytes := by
  cases alg
  · exact Sha256.Digest.size_toByteArray (sha256 msg)
  · exact Sha256.Digest.size_toByteArray (sha224 msg)
  · exact Sha3.Digest.size_toByteArray (sha3_512 msg)

/-! ## Meaning

Each branch of the dispatch is its family's transcription of its standard,
carried through by that family's apex theorem. -/

theorem digestBytes_sha256 (msg : ByteArray) :
    (digestBytes .sha256 msg).data.toList = Sha256.Spec.sha256_bytes msg.data.toList :=
  Sha256.sha256_spec msg

theorem digestBytes_sha224 (msg : ByteArray) :
    (digestBytes .sha224 msg).data.toList = Sha256.Spec.sha224_bytes msg.data.toList :=
  Sha256.sha224_spec msg

theorem digestBytes_sha3_512 (msg : ByteArray) :
    (digestBytes .sha3_512 msg).data.toList = Sha3.Spec.sha3_512_bytes msg.data.toList :=
  Sha3.sha3_512_spec msg

/-! ## The dispatch is the family function

Stated so that a consumer can rewrite between the indexed and the direct
form without unfolding a definition. -/

theorem digestHex_sha256 (msg : ByteArray) : digestHex .sha256 msg = (sha256 msg).toHex := rfl
theorem digestHex_sha224 (msg : ByteArray) : digestHex .sha224 msg = (sha224 msg).toHex := rfl
theorem digestHex_sha3_512 (msg : ByteArray) :
    digestHex .sha3_512 msg = (sha3_512 msg).toHex := rfl

end Hash
