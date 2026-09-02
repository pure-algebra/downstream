import Lean
import Lean.Util.CollectAxioms

/-!
# `Hash.Sha256` axiom audit

`#sha256_axiom_audit` walks the compiled environment, keeps every declaration
whose owning module lies under the `Hash.Sha256` namespace and is not this module,
collects the axioms each one reaches, and emits exactly one line stating what
was scanned and against which ceiling. It replaces the `#print axioms` lines
that would otherwise put one info line per declaration into every consumer's
build log (`docs/SHA256-DAG.md` §3.3).

The ceiling is the package's one ceiling under operator ruling R-11
(2026-09-02): `propext`, `Quot.sound`, and `Classical.choice`, the same for
every tree in `lean4-hash`. That is wider than the ceiling this tree was
proved under in `lean4-WHATWG-streams` (`docs/SHA256-DAG.md` §3.1, `propext`
and `Quot.sound`), so the verdict line also reports how many declarations
actually reach `Classical.choice`. For this family that number is `0`, which
is the stricter fact, kept visible without being a gate.

This audit is the library's own typed verdict. It is not the repository's
trust boundary: `HashTest/Audit/AxiomGate.lean` is, and it audits
every declaration of this tree, including the private and compiler-generated
ones that `Name.isInternal` filters out here.

Shape adapted from foldlab `.staging/fips202-library/SPEC.md` §6 item S0.4 and
from the repository's own `HashTest/Audit/AxiomGate.lean`.
-/

open Lean

namespace Hash.Sha256.Audit

/-- The package ceiling under ruling R-11. -/
private def allowedAxioms : List Name :=
  [``propext, ``Quot.sound, ``Classical.choice]

/-- The audit must be shown to have scanned something before its verdict
means anything. Stages S1.1 to S1.6 landed 422 declarations across twelve
modules; this floor is a coarse tripwire well below that, so that an audit
which silently stopped seeing the tree fails here rather than passing
vacuously. The *exact* count is pinned separately by `#guard_msgs` in
`Hash.Sha256.Verified`, which is what catches a single declaration appearing or
disappearing. -/
private def minimumDeclarations : Nat := 380

/-- Every module under this prefix is audited. -/
private def treePrefix : Name := `Hash.Sha256

/-- This module is excluded from its own audit: it is the audit
implementation, it runs in `MetaM`, and it therefore reaches
`Classical.choice`, which would make the choice-reaching count report on the
audit rather than on the tree it audits. -/
private def auditModule : Name := `Hash.Sha256.Audit

private def moduleOf? (environment : Environment) (declaration : Name) : Option Name := do
  let index ← environment.getModuleIdxFor? declaration
  environment.header.moduleNames[index.toNat]?

/-- Lean compiles a safe definition into an auxiliary unsafe recursor. The
companion of a safe definition is not an authored `unsafe` declaration and is
not audit material. Same test as `HashTest/Audit/AxiomGate.lean`. -/
private def isGeneratedSafeRecursor (environment : Environment) (name : Name) : Bool :=
  match Lean.Compiler.isUnsafeRecName? name with
  | none => false
  | some sourceName =>
      match environment.find? sourceName with
      | some (.defnInfo sourceInfo) => sourceInfo.safety == .safe
      | _ => false

private def isAuditedModule (moduleName : Name) : Bool :=
  treePrefix.isPrefixOf moduleName && moduleName != auditModule

/-- Render a name list as a plain `String`. The audit line is pinned by
`#guard_msgs`, and `MessageData` formatting of a `List` inserts breakable
separators whose rendering depends on the surrounding width. A `String` has
no break points, so the pinned line is stable. -/
private def renderNames (names : List Name) : String :=
  "[" ++ String.intercalate ", " (names.map toString) ++ "]"

open Lean Elab Command in
/-- Audit every `Hash.Sha256.*` declaration against the package ceiling and
emit one verdict line. Throws, listing every offender, if any declaration
reaches an axiom outside the ceiling. -/
elab "#sha256_axiom_audit" : command => do
  let environment ← getEnv
  let mut declarations : Array Name := #[]
  let mut modules : Array Name := #[]
  for (name, _) in environment.constants.toList do
    if name.isInternal then continue
    if isGeneratedSafeRecursor environment name then continue
    let some moduleName := moduleOf? environment name | continue
    if !isAuditedModule moduleName then continue
    declarations := declarations.push name
    if !modules.contains moduleName then
      modules := modules.push moduleName

  if declarations.size < minimumDeclarations then
    throwError "sha256 axiom audit: scanned only {declarations.size} declarations; at least {minimumDeclarations} were expected, so the audit has not been shown to cover the tree"

  let mut offenders : Array (Name × Name) := #[]
  let mut choiceCount : Nat := 0
  for declaration in declarations do
    let axioms ← collectAxioms declaration
    if axioms.contains ``Classical.choice then
      choiceCount := choiceCount + 1
    for axiomName in axioms do
      if !allowedAxioms.contains axiomName then
        offenders := offenders.push (declaration, axiomName)

  unless offenders.isEmpty do
    let mut report := s!"sha256 axiom audit: {offenders.size} offender(s) outside the ceiling {renderNames allowedAxioms}"
    for (declaration, axiomName) in offenders do
      report := report ++ s!"\n  {declaration} reaches {axiomName}"
    throwError "{report}"

  logInfo s!"sha256 axiom audit: {declarations.size} declarations across {modules.size} modules; ceiling {renderNames allowedAxioms}; {choiceCount} reach Classical.choice; 0 offenders"

end Hash.Sha256.Audit
