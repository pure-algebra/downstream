import Lean

/-!
# `Hash.Sha3` axiom audit

Moved from foldlab's `formal/fips202/Sha3/Audit.lean` at commit `64be4b2c`.
Two things changed here and nothing else: the tree prefix, and the ceiling,
which is now the package's one ceiling under operator ruling R-11
(2026-09-02) and is spelled in the same order as `Hash.Sha256.Audit`'s so the
two verdict lines can be read side by side. The set of axioms admitted is the
same set fips202 admitted.

The verdict line also reports how many declarations actually reach
`Classical.choice`. For this family that number is not zero: 45 of 571, and
they are not only the hexadecimal codec but the sponge and permutation
refinement lemmas, `Bridge.sha3_512_bridge` and `Fast.sha3_512_eq_impl`
included. `docs/EXTRACTION-RECORD.md` lists them by group and compares them
with the SHA-256 family's zero. The count is what keeps that visible without
making it a gate.
-/

open Lean Elab Command

namespace Hash.Sha3.Audit

private def allowedAxioms : List Name := [`propext, `Quot.sound, `Classical.choice]

private def isInternal (n : Name) : Bool :=
  match n with
  | .str _ s =>
      s == "_unsafe_rec" || s.startsWith "_cstage" || s.startsWith "_sparse" ||
        s.startsWith "_lambda" || s.startsWith "_elambda" || s.startsWith "_closed" ||
        s.startsWith "_spec_" || s == "match_1" || s == "eq_def"
  | _ => n.hasMacroScopes

elab "#sha3_axiom_audit" : command => do
  let env ← getEnv
  let mods := env.allImportedModuleNames
  let mut scanned : Nat := 0
  let mut covered : NameSet := {}
  let mut offenders : Array (Name × Array Name) := #[]
  let mut choiceCount : Nat := 0
  for (n₀, _) in env.constants.toList do
    let some idx := env.getModuleIdxFor? n₀ | continue
    let some m := mods[idx.toNat]? | continue
    unless (`Hash.Sha3).isPrefixOf m && m != `Hash.Sha3.Audit do continue
    let n := privateToUserName n₀
    if isInternal n then continue
    scanned := scanned + 1
    covered := covered.insert m
    let axioms ← Lean.collectAxioms n₀
    if axioms.contains `Classical.choice then choiceCount := choiceCount + 1
    let stray := axioms.filter fun ax => !allowedAxioms.contains ax
    unless stray.isEmpty do offenders := offenders.push (n, stray)
  if scanned < 70 then
    throwError "sha3 axiom audit FAILED: scanned only {scanned} declarations; expected at least 70"
  unless offenders.isEmpty do
    throwError "sha3 axiom audit FAILED: axioms outside allowlist: {offenders}"
  logInfo s!"sha3 axiom audit: {scanned} declarations across {covered.toList.length} modules; ceiling [propext, Quot.sound, Classical.choice]; {choiceCount} reach Classical.choice; 0 offenders"

end Hash.Sha3.Audit
