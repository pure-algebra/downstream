import HashGates.Common
import HashGates.Cavp
import HashGates.Sha256
import HashGates.Sha3
import HashGates.SelfTest
import HashGates.VendorSeal
import HashGates.Citations
import HashGates.TrustSelfTest

/-!
# HashGates

Root of the Lean-implemented gate tooling. Entry points live under `hashbin/`.

`HashGates.Sha256`, `HashGates.Sha3` and `HashGates.VendorSeal` each compute
every digest through the proved library, so none of them can exist before the
library it calls. `HashGates.Cavp` is the one NIST response-file parser both
self-tests read their pinned vectors with.
-/
