import Lean
import Lean.Util.CollectAxioms
import Hash.Verified

/-!
# Receipt extraction and the extraction join

Two commands, and the invocations that produce and check this repository's
receipt projections.

`#hash_receipts <tree> <excluded-module> <output>` writes one row per
declaration whose owning module lies under `<tree>` and is not under
`<excluded-module>`, as

```text
<declaration name>\t<comma-separated axiom names, sorted>
```

sorted by declaration name. The set is every declaration Lean compiled from
those modules, private and generated ones included, not only the exported
theorems — a receipt that covered only the names a human listed would not be
a receipt.

`#hash_receipt_join <before> <after> <from> <to>` decides whether the move
from another repository changed any receipt. It reads both files, rewrites
every occurrence of `<from>` in each *after* declaration name to `<to>` — the
namespace prefix is the only thing the move was allowed to change — and then
requires the two sets to be equal as `(declaration, axiom-set)` pairs. It
throws, listing every one, if any declaration differs in its axiom set,
appears only before, or appears only after. It is silent apart from one
`PASS` line.

Each family's `Audit` module is excluded on both sides. It is audit
implementation rather than a theorem, it runs in `MetaM`, and ruling R-11
deliberately changed it; including it would report a difference that is an
ordered edit rather than a drift in what is proved.

## Inputs and regeneration

Canonical inputs: the compiled environment of `Hash.Verified`, and the
before-receipts under `test/receipts/`, which were taken in the source
repositories at the commits named in their file names and are never
regenerated here.

```text
lake build HashVerified
lake env lean test/tools/Receipts.lean
```

This file is a projection generator, not a library module: it is deliberately
outside `Hash/`, `HashTest/` and `HashGates/` so that the module-closure gate
does not require a root to import it, and it is run explicitly rather than by
`lake build`. It writes only under `generated/`.
-/

open Lean Elab Command

namespace HashReceipts

private def moduleOf? (environment : Environment) (declaration : Name) : Option Name := do
  let index ← environment.getModuleIdxFor? declaration
  environment.header.moduleNames[index.toNat]?

private structure Row where
  name : String
  axioms : String
  deriving Inhabited, BEq

private def parseRows (text : String) : Array Row := Id.run do
  let mut rows : Array Row := #[]
  for line in text.splitOn "\n" do
    let line := if line.endsWith "\r" then String.ofList (line.toList.dropLast) else line
    if line.isEmpty then continue
    match line.splitOn "\t" with
    | [name, axioms] => rows := rows.push { name, axioms }
    | _ => rows := rows.push { name := line, axioms := "MALFORMED ROW" }
  return rows

private def find? (rows : Array Row) (name : String) : Option Row :=
  rows.find? fun row => row.name == name

elab "#hash_receipts" treeLit:str excludeLit:str outLit:str : command => do
  let environment ← getEnv
  let treePrefix := treeLit.getString.toName
  let excluded := excludeLit.getString.toName
  let mut rows : Array String := #[]
  for (name, _) in environment.constants.toList do
    let some moduleName := moduleOf? environment name | continue
    unless treePrefix.isPrefixOf moduleName do continue
    if excluded.isPrefixOf moduleName then continue
    let axioms ← collectAxioms name
    let names := (axioms.map toString).qsort (· < ·)
    rows := rows.push s!"{name}\t{String.intercalate "," names.toList}"
  let sorted := rows.qsort (· < ·)
  liftIO <| IO.FS.writeFile outLit.getString
    (String.intercalate "\n" sorted.toList ++ "\n")
  logInfo s!"receipts: {sorted.size} declarations under {treePrefix} (excluding {excluded}) written to {outLit.getString}"

elab "#hash_receipt_join" beforeLit:str afterLit:str fromLit:str toLit:str : command => do
  let beforeRows := parseRows (← liftIO <| IO.FS.readFile beforeLit.getString)
  let afterRaw := parseRows (← liftIO <| IO.FS.readFile afterLit.getString)
  let afterRows := afterRaw.map fun row =>
    { row with name := row.name.replace fromLit.getString toLit.getString }

  let mut differing : Array String := #[]
  let mut onlyBefore : Array String := #[]
  let mut onlyAfter : Array String := #[]
  let mut matched : Nat := 0
  for row in beforeRows do
    match find? afterRows row.name with
    | none => onlyBefore := onlyBefore.push row.name
    | some other =>
      if other.axioms == row.axioms then
        matched := matched + 1
      else
        differing := differing.push
          s!"{row.name}: before [{row.axioms}], after [{other.axioms}]"
  for row in afterRows do
    if (find? beforeRows row.name).isNone then
      onlyAfter := onlyAfter.push row.name

  unless differing.isEmpty && onlyBefore.isEmpty && onlyAfter.isEmpty do
    let mut report :=
      s!"FAIL receipt join {beforeLit.getString} -> {afterLit.getString}: {differing.size} differing, {onlyBefore.size} only before, {onlyAfter.size} only after"
    for entry in differing do report := report ++ s!"\n  differs: {entry}"
    for entry in onlyBefore do report := report ++ s!"\n  only before: {entry}"
    for entry in onlyAfter do report := report ++ s!"\n  only after: {entry}"
    throwError "{report}"

  logInfo s!"PASS receipt join: {matched} declarations, axiom sets identical before and after; 0 differing, 0 only before, 0 only after ({beforeLit.getString} -> {afterLit.getString}, rewriting {fromLit.getString} to {toLit.getString})"

end HashReceipts

#hash_receipts "Hash.Sha256" "Hash.Sha256.Audit" "generated/receipts-sha256.tsv"

#hash_receipt_join "test/receipts/sha256-before-a1383bc.tsv" "generated/receipts-sha256.tsv" "Hash.Sha256" "Sha256"

#hash_receipts "Hash.Sha3" "Hash.Sha3.Audit" "generated/receipts-sha3.tsv"

#hash_receipt_join "test/receipts/sha3-before-64be4b2c.tsv" "generated/receipts-sha3.tsv" "Hash.Sha3" "Sha3"
