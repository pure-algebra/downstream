import Lean
import Lean.Util.CollectAxioms
import Hash
import HashGates

/-!
# `Hash` axiom allowlist gate

This command tokenizes every authored source under `Hash/`, `HashTest/`, and
`HashGates/` and inspects every declaration compiled from them, including
definitions, instances, generated declarations, and private helpers. The
build fails on an authored `unsafe` or `partial` declaration modifier, on any
declaration that reaches a forbidden axiom, and on any declaration that
reaches an axiom outside the ceiling.

**One ceiling** binds every tree here, `Hash/`, `HashTest/` and `HashGates/`
alike, under operator ruling R-11 (2026-09-02): `propext`, `Quot.sound`, and
`Classical.choice`. `Classical.choice` needs no admission and no exemption,
so this gate carries no exact-module or exact-declaration admission list and
no staleness check for one. The two hash families therefore arrive under the
same ceiling despite reaching different axioms, and ruling HP-2's parity
question becomes a matter of record rather than a gate: the count of
choice-reaching declarations per family is stated in
`docs/EXTRACTION-RECORD.md`.

`sorryAx`, `Lean.ofReduceBool`, `Lean.ofReduceNat`, and `Lean.trustCompiler`
are forbidden everywhere, as are the `_native` auxiliary axioms that
`native_decide` and `bv_decide` mint. That is what the ceiling actually
buys: no compiler and no `sorry` in the trust path. The gate is exhaustive
over the compiled environment rather than a hand-written theorem list;
per-packet axiom reports remain the human-readable receipts.

This gate is ported from lean4-WHATWG-streams'
`WhatwgStreamsTest/Audit/AxiomGate.lean` at commit `a1383bc`, with the tree
names and messages changed for this repository and the two-ceiling machinery
removed under R-11.
-/

open Lean

namespace HashTest.Audit

/-- The one ceiling, under ruling R-11. Every audited tree is bound by it. -/
private def allowedAxioms : List Name :=
  [``propext, ``Quot.sound, ``Classical.choice]

/-- The `HashGates/` tree is tooling: it is audited for totality and forbidden
axioms exactly as the library is. It contains no semantic declaration;
`HashGates/AGENTS.md` owns that rule. The prefix survives R-11 only so the gate
can report how much of what it checked was tooling. -/
private def toolingTreePrefix : Name := `HashGates

private def forbiddenAxioms : List Name :=
  [``sorryAx, ``Lean.ofReduceBool, ``Lean.ofReduceNat, ``Lean.trustCompiler]

/-- `native_decide` and `bv_decide` mint a per-declaration auxiliary axiom
whose name carries a `_native` component. Such an axiom is forbidden by
shape, whatever declaration it hangs off. -/
private def isNativeAuxiliaryAxiom (axiomName : Name) : Bool :=
  axiomName.anyS fun component => component == "_native"

private def moduleOf? (environment : Environment) (declaration : Name) : Option Name := do
  let index ← environment.getModuleIdxFor? declaration
  environment.header.moduleNames[index.toNat]?

/-- The two semantic trees. `Hash/` is the library and `HashTest/` its
witnesses. -/
private def semanticTreePrefixes : List Name :=
  [`Hash, `HashTest]

private def belongsToAuditedTree (moduleName : Name) : Bool :=
  semanticTreePrefixes.any (·.isPrefixOf moduleName) ||
    toolingTreePrefix.isPrefixOf moduleName

private def isGeneratedSafeRecursor (environment : Environment) (name : Name) : Bool :=
  match Lean.Compiler.isUnsafeRecName? name with
  | none => false
  | some sourceName =>
      match environment.find? sourceName with
      | some (.defnInfo sourceInfo) => sourceInfo.safety == .safe
      | none => false
      | _ => false

/-
`Parser.testParseFile` cannot replay an already-compiled source against the
final project environment: syntax introduced by a later-imported test module
can turn an earlier ordinary identifier into a keyword. Tokenization is the
right level for this source check. Lean's own tokenizer skips comments and
handles ordinary, character, interpolated, and raw string literals, while the
compiled-environment pass below independently confirms declaration safety.
-/
private def forbiddenTrustToken?
    (environment : Environment)
    (source : System.FilePath) : IO (Option String) := do
  let input ← IO.FS.readFile source
  let inputContext := Parser.mkInputContext input source.toString
  let parserContext : Parser.ParserModuleContext :=
    { env := environment, options := {} }
  let tokenTable := Parser.Module.updateTokens (Parser.getTokenTable environment)
  let mut state := Parser.mkParserState input
  let mut projectionEnd : Option String.Pos.Raw := none
  while !inputContext.atEnd state.pos do
    let skipped := Parser.whitespace.run inputContext parserContext tokenTable state
    if let some error := skipped.errorMsg then
      throw <| IO.userError
        s!"Hash source trust gate: tokenization failed in {source}: {error}"
    state := skipped
    if inputContext.atEnd state.pos then
      return none
    -- Documentation comments are syntax nodes rather than whitespace. Consume
    -- them with Lean's own parsers so their prose never becomes audit tokens.
    let docComment := Parser.Command.docComment.fn.run
      inputContext parserContext tokenTable state
    if docComment.errorMsg.isNone then
      state := docComment.popSyntax
      projectionEnd := none
      continue
    let moduleDoc := Parser.Command.moduleDoc.fn.run
      inputContext parserContext tokenTable state
    if moduleDoc.errorMsg.isNone then
      state := moduleDoc.popSyntax
      projectionEnd := none
      continue
    -- Lean parses the index in `h.2.trans` and `h |>.2.trans` with
    -- `fieldIdxFn`: the ordinary number tokenizer mistakes `2.trans` for a
    -- decimal. Use the same parser only immediately after a projection dot;
    -- ordinary numerals and every tokenization error retain their usual path.
    let tokenParser :=
      if projectionEnd == some state.pos && (inputContext.get state.pos).isDigit then
        Parser.fieldIdxFn
      else
        Parser.tokenFn []
    let next := tokenParser.run inputContext parserContext tokenTable state
    if let some error := next.errorMsg then
      let position := inputContext.fileMap.toPosition state.pos
      throw <| IO.userError
        s!"Hash source trust gate: tokenization failed in {source}:{position.line}:{position.column + 1}: {error}"
    let token := next.stxStack.back
    if token.isToken "unsafe" then
      return some "unsafe"
    if token.isToken "partial" then
      return some "partial"
    projectionEnd :=
      if token.isToken "." || token.isToken "|>." then token.getTailPos? else none
    state := next.popSyntax
  return none

private def auditSourceTrustModifiers
    (environment : Environment)
    (sources : Array System.FilePath) : IO Unit := do
  for source in sources do
    if let some modifier ← forbiddenTrustToken? environment source then
      throw <| IO.userError
        s!"Hash source trust gate: {source} contains an authored `{modifier}` declaration modifier"

private def findProjectRoot (directory : System.FilePath) : IO System.FilePath := do
  let mut current := directory
  for _ in [0:64] do
    if ← (current / "Hash.lean").pathExists then
      return current
    match current.parent with
    | some parent => current := parent
    | none => throw <| IO.userError "Hash axiom gate: could not locate the project root"
  throw <| IO.userError "Hash axiom gate: project-root search exceeded 64 parents"

private def leanFilesBelow (directory : System.FilePath) : IO (Array System.FilePath) := do
  let entries ← directory.walkDir
  return entries.filter fun path => path.extension == some "lean"

private def auditedSources (projectRoot : System.FilePath) : IO (Array System.FilePath) := do
  let library ← leanFilesBelow (projectRoot / "Hash")
  let tests ← leanFilesBelow (projectRoot / "HashTest")
  let tooling ← leanFilesBelow (projectRoot / "HashGates")
  return library ++ tests ++ tooling
    |>.push (projectRoot / "Hash.lean")
    |>.push (projectRoot / "HashGates.lean")
    |>.push (projectRoot / "HashTest.lean")

open Lean Elab Command in
elab "#hash_axiom_gate" : command => do
  let environment ← getEnv
  let sourceFile := System.FilePath.mk (← getFileName)
  let some sourceDirectory := sourceFile.parent
    | throwError "Hash axiom gate: source file has no parent directory"
  let projectRoot ← liftIO <| findProjectRoot sourceDirectory
  let sources ← liftIO <| auditedSources projectRoot
  let importedPaths := environment.header.moduleNames.map fun moduleName =>
    (Lean.modToFilePath projectRoot moduleName "lean").normalize
  for source in sources do
    if source.normalize != sourceFile.normalize && !importedPaths.contains source.normalize then
      throwError
        "Hash module-closure gate: {source} is not reachable from the HashTest audit root"

  liftIO <| auditSourceTrustModifiers environment sources

  let mut declarations : Array Name := #[]
  for (name, info) in environment.constants.toList do
    if let some moduleName := moduleOf? environment name then
      if belongsToAuditedTree moduleName then
        if !isGeneratedSafeRecursor environment name then
          if info.isUnsafe then
            throwError "Hash trust gate: declaration {name} is unsafe"
          if info.isPartial then
            throwError "Hash trust gate: declaration {name} is partial"
        declarations := declarations.push name

  let mut toolingCount : Nat := 0
  let mut choiceCount : Nat := 0
  for declaration in declarations do
    let axioms ← collectAxioms declaration
    if (moduleOf? environment declaration).any toolingTreePrefix.isPrefixOf then
      toolingCount := toolingCount + 1
    if axioms.contains ``Classical.choice then
      choiceCount := choiceCount + 1
    for axiomName in axioms do
      if isNativeAuxiliaryAxiom axiomName then
        throwError
          "Hash axiom gate: declaration {declaration} reaches forbidden axiom {axiomName} (native_decide auxiliary)"
      if forbiddenAxioms.contains axiomName then
        throwError
          "Hash axiom gate: declaration {declaration} reaches forbidden axiom {axiomName}"
      if !allowedAxioms.contains axiomName then
        throwError
          "Hash axiom gate: declaration {declaration} reaches unexpected axiom {axiomName}; allowed axioms are {allowedAxioms}"

  logInfo
    m!"Hash module and axiom gate: checked {sources.size} modules and {declarations.size} declarations ({toolingCount} in the HashGates tooling tree); ceiling is {allowedAxioms} for every tree; {choiceCount} declaration(s) reach Classical.choice; 0 offenders"

end HashTest.Audit
