# Contract packets

Every semantic slice in this package begins with a breaker-authored packet in
this directory. A packet states its claim boundary, categories, requirements,
frozen public declarations, algebraic laws, preconditions, postconditions,
decrease arguments, frame, executable falsifiers, the standard's sections it
transcribes, and the counterexample rows it exercises. The breaker commits
the packet and the red battery and declares the red modules in
`test/fixtures/trust-gate/known-red.txt` before the builder changes the
implementation.

The Lean battery is the authority on names and propositions; the packet's
Lean is a reading aid. Every theorem statement in a battery is frozen by
`#check (@name : proposition)` ascription.

Both families arrived with their packets already frozen and their batteries
already green: `sha256.contract.md` from `lean4-WHATWG-streams`, and the Pass
A / Pass B chain under `sha3/` from foldlab's `formal/fips202`.
