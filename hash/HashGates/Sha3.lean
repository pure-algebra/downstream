import Hash.Sha3
import HashGates.Common
import HashGates.Cavp

/-!
# HashGates.Sha3

The command-line face of the proved SHA3-512 library, and the file and
standard-input adapter. `IO` stays outside the pure `Hash.Sha3` namespace:
this module holds no hash arithmetic of its own, computing every digest
through `Hash.Sha3.sha3_512` and every hexadecimal spelling through
`Hash.Sha3.Digest.toHex`, whose meaning is
`Hash.Sha3.Bridge.sha3_512_bridge`. File access and standard IO are adapter
behaviour, outside the pure library's refinement theorem.

**The self-test contains no literal.** It reads
`vendor/nist-cavp-sha3-512/SHA3_512ShortMsg.rsp` — NIST CAVP, vendored out of
the prior art's git object and sealed by `generated/vendor-manifest.tsv` — at
run time through `HashGates.Cavp` and reproduces every record in it. It mirrors
`lake exe hash_sha256 --self-test`, and like it cannot drift from the pin: if the
vendored bytes change the seal fails, and if the implementation changes this
fails.

This file continues the history of foldlab's `formal/fips202/Sha3Sum.lean`,
moved here from commit `64be4b2c`. The adapter's behaviour is unchanged — one
optional argument, `-` or nothing meaning standard input, output
`<128 lowercase hex digits>  <name>` — and `--self-test` is added beside it,
so that `hashbin/Sha3Sum.lean` can be the one-line entry point `hashbin/` is
allowed to hold.
-/

namespace HashGates.Sha3

/-- Hexadecimal SHA3-512 of a byte array, through the proved library. -/
def hexDigest (message : ByteArray) : String := (Hash.Sha3.sha3_512 message).toHex

/-- Hexadecimal SHA3-512 of a file's bytes. -/
def hexDigestOfFile (path : System.FilePath) : IO String := do
  return hexDigest (← IO.FS.readBinFile path)

def vectorsPath (root : System.FilePath) : System.FilePath :=
  root / "vendor" / "nist-cavp-sha3-512" / "SHA3_512ShortMsg.rsp"

/-- The four witnesses fips202's build-time guards use, by `Len` in bits.
SHA3-512 has rate 72 bytes, so `568` is the last message whose padding still
fits the block it shares and `576` is exactly one rate's worth, where the
padding forces a further permutation. The self-test refuses to pass if the
pinned file has stopped containing any of them. -/
def requiredLens : List Nat := [0, 24, 568, 576]

/-- Reproduce every pinned CAVP record. Returns `true` when all match. -/
def selfTest : IO Bool := do
  let root ← HashGates.Common.projectRoot
  let path := vectorsPath root
  let relative ← HashGates.Common.relativeTo root path
  let (failures, count) ←
    HashGates.Cavp.checkVectors root path Hash.Sha3.Hex.decode? requiredLens hexDigest
  if failures.isEmpty then
    IO.println s!"PASS sha3_512 self-test: {count} CAVP records from {relative} reproduced, including Len = 0, 24, 568 and 576"
    return true
  IO.eprintln s!"FAIL sha3_512 self-test: {failures.size} problem(s)"
  for failure in failures do IO.eprintln s!"  {failure}"
  return false

def usage : String :=
  "usage: lake exe hash_sha3_512sum --self-test\n       lake exe hash_sha3_512sum [FILE|-]"

/-- Digest one file, or standard input when the name is `-`. -/
def emit (name : String) : IO UInt32 := do
  let bytes ← if name == "-" then (← IO.getStdin).readBinToEnd
    else IO.FS.readBinFile name
  (← IO.getStdout).putStrLn s!"{hexDigest bytes}  {name}"
  return 0

/-- Command-line entry, invoked by `hashbin/Sha3Sum.lean`. -/
def cli (args : List String) : IO UInt32 := do
  match args with
  | ["--self-test"] =>
    if ← selfTest then return 0 else return 1
  | [] => emit "-"
  | [name] =>
    if name.startsWith "--" then
      IO.eprintln usage
      return 2
    emit name
  | _ =>
    IO.eprintln usage
    return 2

end HashGates.Sha3
