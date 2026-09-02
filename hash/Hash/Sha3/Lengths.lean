import Hash.Sha3.Impl

/-! Byte-length and padding facts for the frozen reference implementation. -/

namespace Hash.Sha3.Impl

theorem length_sha3_512 (msg : List UInt8) : (sha3_512 msg).length = 64 := by
  simp only [sha3_512, List.length_flatten, List.map_map, bytesOfLane]
  rfl

theorem length_keccak512_prefips (msg : List UInt8) :
    (keccak512_prefips msg).length = 64 := by
  simp only [keccak512_prefips, List.length_flatten, List.map_map, bytesOfLane]
  rfl

theorem padBytes_prefix (msg : List UInt8) : (padBytes msg).take msg.length = msg := by
  unfold padBytes
  dsimp only
  split
  · exact List.take_left
  · rw [List.append_assoc]
    exact List.take_left

private theorem length_padBytes_exact (msg : List UInt8) :
    (padBytes msg).length = msg.length + (72 - msg.length % 72) := by
  have hm := Nat.mod_lt msg.length (show 0 < 72 by decide)
  unfold padBytes rateBytes
  dsimp only
  split <;> simp_all only [List.length_append, List.length_cons, List.length_nil,
    List.length_replicate] <;> omega

theorem length_padBytes (msg : List UInt8) : (padBytes msg).length % rateBytes = 0 := by
  rw [length_padBytes_exact]
  unfold rateBytes
  have hm := Nat.mod_lt msg.length (show 0 < 72 by decide)
  omega

theorem length_padBytes_pos (msg : List UInt8) : msg.length < (padBytes msg).length := by
  rw [length_padBytes_exact]
  have hm := Nat.mod_lt msg.length (show 0 < 72 by decide)
  omega

end Hash.Sha3.Impl
