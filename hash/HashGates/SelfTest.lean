import Hash
import HashGates.Common
import HashGates.Cavp
import HashGates.Sha256
import HashGates.Sha3

/-!
# HashGates.SelfTest

One self-test over **every** sealed NIST CAVP response file, through
`Hash.digestHex` — the algorithm-indexed surface — rather than through either
family's own entry point.

The word "every" is meant literally, and that is the point of this gate
existing beside the two per-family ones. It does not read a list of files
someone maintained by hand: it walks `vendor/`, takes every `.rsp` it finds,
and looks each one's directory up in `algorithmOfTree`. **A response file
that no algorithm claims is a failure**, so sealing a new set of vectors
without replaying them cannot pass quietly — which is exactly the mistake a
hand-maintained list invites.

Between them, the vendor seal and this gate close the loop: the seal says the
bytes under `vendor/` are the pinned bytes and nothing there is unaccounted
for, and this says every vector in those bytes is reproduced by the proved
library.

Run `lake exe hash_selftest`.
-/

namespace HashGates.SelfTest

open HashGates.Common

/-- The algorithm whose vectors a sealed response-file directory holds.
Adding a directory under `vendor/` with `.rsp` files in it and not adding it
here fails this gate. -/
def algorithmOfTree : String → Option Hash.Algorithm
  | "nist-cavp-sha256" => some .sha256
  | "nist-cavp-sha224" => some .sha224
  | "nist-cavp-sha3-512" => some .sha3_512
  | _ => none

/-- Each family reads its own file with its own hexadecimal codec. -/
def decoderOf : Hash.Algorithm → (String → Option ByteArray)
  | .sha256 => Hash.Sha256.Hex.decode?
  | .sha224 => Hash.Sha256.Hex.decode?
  | .sha3_512 => Hash.Sha3.Hex.decode?

/-- The record lengths each family's contract names as witnesses; a pin that
has stopped containing one of them fails rather than passing smaller. -/
def requiredLensOf : Hash.Algorithm → List Nat
  | .sha256 => HashGates.Sha256.requiredLens
  | .sha224 => HashGates.Sha256.requiredLens
  | .sha3_512 => HashGates.Sha3.requiredLens

/-- Every `.rsp` under `vendor/`, sorted by path. -/
def responseFiles (root : System.FilePath) : IO (Array System.FilePath) := do
  let vendor := root / "vendor"
  unless ← vendor.isDir do
    throw <| IO.userError s!"combined self-test: {vendor} is not a directory"
  let files ← regularFilesBelow vendor
  return (files.filter fun path => path.extension == some "rsp").qsort
    fun a b => a.toString < b.toString

/-- The name of the directory a file sits in, which is how a vendored tree is
identified. -/
private def treeNameOf (path : System.FilePath) : Option String :=
  path.parent >>= System.FilePath.fileName

def run : IO Bool := do
  let root ← projectRoot
  let files ← responseFiles root
  if files.isEmpty then
    IO.eprintln "FAIL combined self-test: no sealed .rsp file found under vendor/"
    return false
  let mut failures : Array String := #[]
  let mut lines : Array String := #[]
  let mut total : Nat := 0
  for file in files do
    let relative ← relativeTo root file
    match treeNameOf file >>= algorithmOfTree with
    | none =>
      failures := failures.push
        s!"{relative} is sealed but no algorithm replays it; add its directory to HashGates.SelfTest.algorithmOfTree"
    | some alg =>
      let (problems, count) ← HashGates.Cavp.checkVectors root file
        (decoderOf alg) (requiredLensOf alg) (Hash.digestHex alg)
      failures := failures ++ problems
      total := total + count
      lines := lines.push s!"  {alg.name}: {count} records from {relative}"
  if failures.isEmpty then
    IO.println s!"PASS combined self-test: {total} CAVP records reproduced across {files.size} sealed response file(s) through Hash.digestHex"
    for line in lines do IO.println line
    return true
  IO.eprintln s!"FAIL combined self-test: {failures.size} problem(s)"
  for failure in failures do IO.eprintln s!"  {failure}"
  return false

/-- Command-line entry, invoked by `hashbin/SelfTest.lean`. -/
def cli (args : List String) : IO UInt32 := do
  unless args.isEmpty do
    IO.eprintln "usage: lake exe hash_selftest"
    return 2
  if ← run then return 0 else return 1

end HashGates.SelfTest
