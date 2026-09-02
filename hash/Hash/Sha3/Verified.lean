import Hash.Sha3
import Hash.Sha3.Kats
import Hash.Sha3.KeccakProbe
import Hash.Sha3.BridgeEvidence
import Hash.Sha3.Audit

/-!
# `Hash.Sha3.Verified` — the SHA3 family's audited root

Reached from `Hash.Verified`, the root of the `HashVerified` Lake library.
Moved from foldlab's `formal/fips202/Sha3/Verified.lean` at commit
`64be4b2c`; the closure it pulls in is unchanged — the kernel known-answer
tests, the Keccak-f[1600] probe, the domain-separation evidence, and the
audit.

The pinned line's ceiling and its choice count are the two things ruling R-11
changed. The declaration and module counts are the ones fips202 pinned: 571
declarations across 14 modules.
-/

/-- info: sha3 axiom audit: 571 declarations across 14 modules; ceiling [propext, Quot.sound, Classical.choice]; 45 reach Classical.choice; 0 offenders -/
#guard_msgs in #sha3_axiom_audit
