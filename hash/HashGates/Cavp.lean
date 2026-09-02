import HashGates.Common

/-!
# HashGates.Cavp

The NIST CAVP response-file format, parsed once. Both families' self-tests
read `.rsp` files of the same shape, so there is one parser for it; what
differs between them is the hexadecimal codec used to read a record's message
and the digest function used to reproduce its answer, and both are supplied
by the caller so that each family's self-test stays inside its own family.

A record is three fields:

```text
Len = <bit length>
Msg = <hexadecimal text>
MD  = <expected digest, lowercase hexadecimal>
```

**`Len` is the authority for the message length, not the length of the `Msg`
text.** The `Len = 0` record writes `Msg = 00`, one byte of hexadecimal text
standing for a zero-length message; reading `Msg` and ignoring `Len` would
hash the single byte `0x00` and produce a different digest, and the self-test
would then pass against the wrong thing.

Nothing here holds a digest literal. A self-test built on this parser reads
its sealed file at run time and reproduces every record in it, so it cannot
drift from the pin: if the vendored bytes change the vendor seal fails, and
if an implementation changes the self-test fails.
-/

namespace HashGates.Cavp

open HashGates.Common

/-- One `Len` / `Msg` / `MD` record of a CAVP response file. -/
structure Record where
  len : Nat
  msg : ByteArray
  md : String
  deriving Inhabited

/-- The field value after an `n`-character `key = ` prefix, with any carriage
return removed so the parser reads the same on a host whose checkout converted
line endings. The vendored files are LF-only and sealed; this is defence in
depth, not a repair. `String.drop` and `String.trim` return a `String.Slice`
under v4.33.1 and are deprecated, so the character list is the stable route. -/
private def fieldAfter (line : String) (n : Nat) : String :=
  String.ofList ((line.toList.drop n).filter fun c => c != '\r')

/-- Parse a CAVP `.rsp` file, decoding each `Msg` with `decode`. Surplus
hexadecimal text beyond `Len` is dropped, which is what makes the `Len = 0`
placeholder record read as the empty message. -/
def parseRecords (decode : String → Option ByteArray) (text : String) :
    Except String (Array Record) := do
  let mut out : Array Record := #[]
  let mut len : Option Nat := none
  let mut msgHex : Option String := none
  let mut lineNumber : Nat := 0
  for line in lines text do
    lineNumber := lineNumber + 1
    if line.startsWith "Len = " then
      match (fieldAfter line 6).toNat? with
      | some value => len := some value
      | none => throw s!"line {lineNumber}: malformed Len field"
    else if line.startsWith "Msg = " then
      msgHex := some (fieldAfter line 6)
    else if line.startsWith "MD = " then
      match len, msgHex with
      | some bitLength, some hex =>
        if bitLength % 8 != 0 then
          throw s!"line {lineNumber}: Len {bitLength} is not a whole number of bytes"
        match decode hex with
        | some bytes =>
          if bytes.size * 8 < bitLength then
            throw s!"line {lineNumber}: Msg is shorter than its Len"
          out := out.push
            { len := bitLength, msg := bytes.extract 0 (bitLength / 8),
              md := fieldAfter line 5 }
          len := none
          msgHex := none
        | none => throw s!"line {lineNumber}: malformed Msg hexadecimal"
      | _, _ => throw s!"line {lineNumber}: MD without a preceding Len and Msg"
  return out

/-- Reproduce every record of one pinned response file through `hex`, and
require the file to still contain a record at each of `requiredLens` — the
lengths its family's contract names as witnesses, so that a pin quietly
losing its boundary cases is a failure rather than a smaller pass. Returns
the failures, empty on success, and the number of records checked. Every
failure names the file it came from, because a self-test may read more than
one. -/
def checkVectors (root path : System.FilePath)
    (decode : String → Option ByteArray) (requiredLens : List Nat)
    (hex : ByteArray → String) : IO (Array String × Nat) := do
  let relative ← relativeTo root path
  unless ← path.pathExists do
    return (#[s!"missing pinned vectors {relative}"], 0)
  let records ←
    match parseRecords decode (← IO.FS.readFile path) with
    | .ok records => pure records
    | .error message => return (#[s!"{relative}: {message}"], 0)
  let mut failures : Array String := #[]
  for record in records do
    let actual := hex record.msg
    if actual != record.md then
      failures := failures.push
        s!"{relative} Len = {record.len}: expected {record.md}, computed {actual}"
  for required in requiredLens do
    if (records.find? fun record => record.len == required).isNone then
      failures := failures.push s!"{relative} has no record with Len = {required}"
  return (failures, records.size)

end HashGates.Cavp
