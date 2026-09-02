import Hash.Sha3.Bridge
import Hash.Sha3.Kats

/-!
# Evidence-only bridge closure

This module keeps the known-answer dependency outside the `Hash.Sha3` API import closure while
preserving the frozen name and type of `Hash.Sha3.Bridge.sha3_ne_prefips_spec`.
-/

namespace Hash.Sha3.Bridge

/-- T10-SPEC: the domain-separation suffix changes the frozen spec digest. -/
theorem sha3_ne_prefips_spec :
    Hash.Sha3.Spec.keccakC 1024 (Hash.Sha3.Spec.bitsOfBytes []) 512 ≠
      Hash.Sha3.Spec.SHA3_512 (Hash.Sha3.Spec.bitsOfBytes []) := by
  intro h
  apply Hash.Sha3.Kats.sha3_ne_prefips
  rw [keccak512_prefips_bridge, sha3_512_bridge]
  unfold Hash.Sha3.Spec.sha3_512_bytes
  exact congrArg Hash.Sha3.Spec.bytesOfBits h

end Hash.Sha3.Bridge
