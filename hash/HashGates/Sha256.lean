import Hash.Sha256
import HashGates.Common
import HashGates.Cavp

/-!
# HashGates.Sha256

The command-line face of the proved SHA-256 library. This module holds no
hash arithmetic of its own: every digest is `Hash.Sha256.sha256` or
`Hash.Sha256.sha224` and every hexadecimal spelling is
`Hash.Sha256.Hex.encode`, all from the `Hash/Sha256/` tree, whose meaning is
`Hash.Sha256.Bridge.sha256_bridge`.

**The self-test contains no literal.** It reads
`vendor/nist-cavp-sha256/SHA256ShortMsg.rsp` and
`vendor/nist-cavp-sha224/SHA224ShortMsg.rsp` — NIST CAVP, CAVS 11.0,
generated 2011-03-15, both sealed by `generated/vendor-manifest.tsv` — at run
time through `HashGates.Cavp` and reproduces every record in both. The `Len`
field, not the `Msg` text, is the authority for the message length; the
reason that matters is in `HashGates.Cavp` and in
`test/contracts/sha256.contract.md`, E5.

Run `lake exe hash_sha256 --self-test` or `lake exe hash_sha256 <file>`.

Copied from lean4-WHATWG-streams' `Gates/Sha256.lean` at commit `a1383bc`,
with the namespace changed and the CAVP parser lifted into `HashGates.Cavp` so
that `HashGates.Sha3` reads its own pinned file the same way.
-/

namespace HashGates.Sha256

/-- Hexadecimal SHA-256 of a byte array, through the proved library. -/
def hexDigest (message : ByteArray) : String := (Hash.Sha256.sha256 message).toHex

/-- Hexadecimal SHA-224 of a byte array, through the proved library. Meaning:
`Hash.Sha256.sha224_spec`. Used by the self-test only; the vendor seal
computes SHA-256. -/
def hexDigest224 (message : ByteArray) : String := (Hash.Sha256.sha224 message).toHex

/-- Hexadecimal SHA-256 of the UTF-8 encoding of a string. -/
def hexDigestOfString (text : String) : String := hexDigest text.toUTF8

/-- Hexadecimal SHA-256 of a file's bytes. -/
def hexDigestOfFile (path : System.FilePath) : IO String := do
  return hexDigest (← IO.FS.readBinFile path)

def vectorsPath (root : System.FilePath) : System.FilePath :=
  root / "vendor" / "nist-cavp-sha256" / "SHA256ShortMsg.rsp"

/-- The SHA-224 response file, out of the same prior-art git object the
SHA-256 file came from. -/
def vectorsPath224 (root : System.FilePath) : System.FilePath :=
  root / "vendor" / "nist-cavp-sha224" / "SHA224ShortMsg.rsp"

/-- The five contract witnesses, by `Len` in bits: W1, W2, E1, E2, E3
(`test/contracts/sha256.contract.md`). E1, E2 and E3 are the padding
boundaries — the last length whose padding fits one block, the first that
spills into a second, and exactly one full block. The self-test refuses to
pass if the pinned file has stopped containing any of them. -/
def requiredLens : List Nat := [0, 24, 440, 448, 512]

/-- Reproduce every pinned CAVP record of both response files. Returns `true`
when all match. -/
def selfTest : IO Bool := do
  let root ← HashGates.Common.projectRoot
  let path256 := vectorsPath root
  let path224 := vectorsPath224 root
  let relative256 ← HashGates.Common.relativeTo root path256
  let relative224 ← HashGates.Common.relativeTo root path224
  let decode := Hash.Sha256.Hex.decode?
  let (failures256, count256) ←
    HashGates.Cavp.checkVectors root path256 decode requiredLens hexDigest
  let (failures224, count224) ←
    HashGates.Cavp.checkVectors root path224 decode requiredLens hexDigest224
  let failures := failures256 ++ failures224
  if failures.isEmpty then
    IO.println s!"PASS sha256 self-test: {count256} CAVP records from {relative256} and {count224} from {relative224} reproduced, including Len = 0, 24, 440, 448 and 512 in each"
    return true
  IO.eprintln s!"FAIL sha256 self-test: {failures.size} problem(s)"
  for failure in failures do IO.eprintln s!"  {failure}"
  return false

def usage : String :=
  "usage: lake exe hash_sha256 --self-test\n       lake exe hash_sha256 <file>..."

/-- Command-line entry, invoked by `hashbin/Sha256.lean`. -/
def cli (args : List String) : IO UInt32 := do
  match args with
  | ["--self-test"] =>
    if ← selfTest then return 0 else return 1
  | [] =>
    IO.eprintln usage
    return 2
  | paths =>
    if paths.any (fun p => p.startsWith "--") then
      IO.eprintln usage
      return 2
    for path in paths do
      IO.println s!"{← hexDigestOfFile path}  {path}"
    return 0

end HashGates.Sha256
