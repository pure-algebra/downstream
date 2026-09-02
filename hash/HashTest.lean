import HashGates
import Hash.Verified
import HashTest.Counterexamples.Sha256.Mutants
import HashTest.Audit.AxiomGate

/-!
# `Hash` test battery

The default Lake build imports every admitted witness, attack, and audit root
through this root. A test file not reachable here is not a passing gate. The
gate command below runs last and inspects the whole compiled environment.

The counterexample witnesses join this root as the two families land at S2
and S3; `Hash.Verified` is already imported here, so the known-answer tests
and both axiom audits elaborate under the default build as soon as they
exist.
-/

#hash_axiom_gate
