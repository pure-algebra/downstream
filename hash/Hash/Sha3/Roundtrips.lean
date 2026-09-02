import Hash.Sha3.Spec

/-!
# T6a, T6b, R2: conversion round-trip theorems (REV2 frozen statements)

The precise length-scoped round trips (no unrestricted bijections are claimed anywhere).
Expected axiom profile: `[propext, Quot.sound]` (or smaller).
-/

set_option maxRecDepth 4096

namespace Hash.Sha3.Roundtrips

open Hash.Sha3.Spec

theorem length_bitsOfByte (b : UInt8) : (bitsOfByte b).length = 8 := by
  simp [bitsOfByte]

private def lowBits (n k : Nat) : Nat :=
  (List.range k).foldl (fun acc j => acc + if n.testBit j then 2 ^ j else 0) 0

private theorem lowBits_spec (n k : Nat) :
    lowBits n k < 2 ^ k ∧
      ∀ i, (lowBits n k).testBit i = if i < k then n.testBit i else false := by
  induction k with
  | zero =>
      constructor
      · simp [lowBits]
      · intro i
        simp [lowBits]
  | succ k ih =>
      have hstep : lowBits n k.succ = lowBits n k + if n.testBit k then 2 ^ k else 0 := by
        simp [lowBits, List.range_succ, List.foldl_append]
      rw [hstep]
      constructor
      · by_cases hk : n.testBit k
        · rw [if_pos hk, Nat.pow_succ, Nat.mul_two]
          exact (Nat.add_lt_add_iff_right).2 ih.1
        · rw [if_neg hk, Nat.add_zero, Nat.pow_succ, Nat.mul_two]
          exact Nat.lt_trans ih.1 (Nat.lt_add_of_pos_right (Nat.two_pow_pos k))
      · intro i
        by_cases hk : n.testBit k
        · rw [if_pos hk, ← Nat.or_two_pow_eq_add_of_lt ih.1, Nat.testBit_or, ih.2 i,
              Nat.testBit_two_pow]
          by_cases hik : i < k
          · have his : i < k.succ := Nat.lt_succ_of_lt hik
            have hki : ¬ k = i := Nat.ne_of_gt hik
            simp [hik, his, hki]
          · by_cases hieq : i = k
            · subst i
              simp [hk]
            · have his : ¬ i < k.succ := by
                rw [Nat.lt_succ_iff_lt_or_eq]
                simp [hik, hieq]
              have hki : ¬ k = i := by
                intro h
                exact hieq h.symm
              simp [hik, his, hki]
        · rw [if_neg hk, Nat.add_zero, ih.2 i]
          by_cases hik : i < k
          · have his : i < k.succ := Nat.lt_succ_of_lt hik
            simp [hik, his]
          · by_cases hieq : i = k
            · subst i
              simp [hk]
            · have his : ¬ i < k.succ := by
                rw [Nat.lt_succ_iff_lt_or_eq]
                simp [hik, hieq]
              simp [hik, his]

private theorem lowBits_eq_mod (n k : Nat) : lowBits n k = n % 2 ^ k := by
  apply Nat.eq_of_testBit_eq
  intro i
  rw [(lowBits_spec n k).2 i, Nat.testBit_mod_two_pow]
  by_cases hik : i < k <;> simp [hik]

private theorem byte_roundtrip_fin :
    ∀ n : Fin 256, byteOfBits (bitsOfByte (UInt8.ofNat n.val)) = UInt8.ofNat n.val := by
  intro n
  have hvalue : lowBits n.val 8 = n.val := by
    rw [lowBits_eq_mod, Nat.mod_eq_of_lt n.isLt]
  apply UInt8.toNat_inj.mp
  have hmod := congrArg (fun x : Nat => x % 256) hvalue
  simpa [byteOfBits, bitsOfByte, lowBits, Nat.testBit,
    show List.range 8 = [0, 1, 2, 3, 4, 5, 6, 7] from rfl,
    Nat.mod_eq_of_lt n.isLt] using hmod

/-- Per-byte round trip over the bounded byte representation. -/
theorem byte_roundtrip (b : UInt8) : byteOfBits (bitsOfByte b) = b := by
  have h := byte_roundtrip_fin ⟨b.toNat, b.toNat_lt⟩
  simpa [UInt8.ofNat_toNat] using h

theorem length_bitsOfBytes (bs : List UInt8) : (bitsOfBytes bs).length = 8 * bs.length := by
  induction bs with
  | nil => rfl
  | cons b t ih =>
    rw [show bitsOfBytes (b :: t) = bitsOfByte b ++ bitsOfBytes t from rfl,
        List.length_append, length_bitsOfByte, ih, List.length_cons]
    omega

private theorem take8_append (l r : List Bool) (hl : l.length = 8) :
    (l ++ r).take 8 = l := by
  rw [← hl, List.take_left]

private theorem drop_shift (l r : List Bool) (hl : l.length = 8) (n : Nat) :
    (l ++ r).drop (8 * (n + 1)) = r.drop (8 * n) := by
  have h : 8 * (n + 1) = l.length + 8 * n := by omega
  rw [h, List.drop_append, List.drop_eq_nil_of_le (by omega), List.nil_append,
      Nat.add_sub_cancel_left]

/-- Peeling one byte-sized block off the front of `bytesOfBits`. -/
theorem bytesOfBits_append8 (b8 rest : List Bool) (h8 : b8.length = 8) :
    bytesOfBits (b8 ++ rest) = byteOfBits b8 :: bytesOfBits rest := by
  apply List.ext_getElem
  · simp only [bytesOfBits, List.length_map, List.length_range, List.length_append,
      List.length_cons, h8]
    omega
  · intro i h1 h2
    cases i with
    | zero =>
      simp only [bytesOfBits, List.getElem_map, List.getElem_range, List.getElem_cons_zero]
      rw [Nat.mul_zero, List.drop_zero, take8_append _ _ h8]
    | succ n =>
      simp only [bytesOfBits, List.getElem_map, List.getElem_range, List.getElem_cons_succ]
      rw [drop_shift _ _ h8]

/-- T6a: bytes → bits → bytes is the identity. -/
theorem bytes_bits_roundtrip (bs : List UInt8) : bytesOfBits (bitsOfBytes bs) = bs := by
  induction bs with
  | nil => rfl
  | cons b t ih =>
    rw [show bitsOfBytes (b :: t) = bitsOfByte b ++ bitsOfBytes t from rfl,
        bytesOfBits_append8 _ _ (length_bitsOfByte b), byte_roundtrip, ih]

private def packedBits (l : List Bool) (k : Nat) : Nat :=
  (List.range k).foldl (fun acc j => acc + if l.getD j false then 2 ^ j else 0) 0

private theorem packedBits_spec (l : List Bool) (k : Nat) :
    packedBits l k < 2 ^ k ∧
      ∀ i, (packedBits l k).testBit i = if i < k then l.getD i false else false := by
  induction k with
  | zero =>
      constructor
      · simp [packedBits]
      · intro i
        simp [packedBits]
  | succ k ih =>
      have hstep :
          packedBits l k.succ = packedBits l k + if l.getD k false then 2 ^ k else 0 := by
        simp [packedBits, List.range_succ, List.foldl_append]
      rw [hstep]
      constructor
      · by_cases hk : l.getD k false
        · rw [if_pos hk, Nat.pow_succ, Nat.mul_two]
          exact (Nat.add_lt_add_iff_right).2 ih.1
        · rw [if_neg hk, Nat.add_zero, Nat.pow_succ, Nat.mul_two]
          exact Nat.lt_trans ih.1 (Nat.lt_add_of_pos_right (Nat.two_pow_pos k))
      · intro i
        by_cases hk : l.getD k false
        · rw [if_pos hk, ← Nat.or_two_pow_eq_add_of_lt ih.1, Nat.testBit_or, ih.2 i,
              Nat.testBit_two_pow]
          by_cases hik : i < k
          · have his : i < k.succ := Nat.lt_succ_of_lt hik
            have hki : ¬ k = i := Nat.ne_of_gt hik
            simp [hik, his, hki]
          · by_cases hieq : i = k
            · subst i
              simp only [Nat.lt_irrefl, Nat.lt_succ_self, if_false, if_true, eq_self, hk]
              rfl
            · have his : ¬ i < k.succ := by
                rw [Nat.lt_succ_iff_lt_or_eq]
                simp [hik, hieq]
              have hki : ¬ k = i := by
                intro h
                exact hieq h.symm
              simp [hik, his, hki]
        · rw [if_neg hk, Nat.add_zero, ih.2 i]
          by_cases hik : i < k
          · have his : i < k.succ := Nat.lt_succ_of_lt hik
            simp [hik, his]
          · by_cases hieq : i = k
            · subst i
              simp only [Nat.lt_irrefl, Nat.lt_succ_self, if_false, if_true, hk]
            · have his : ¬ i < k.succ := by
                rw [Nat.lt_succ_iff_lt_or_eq]
                simp [hik, hieq]
              simp [hik, his]

/-- Per-block inverse: eight bits survive the byte round trip. -/
private theorem bits_byte_roundtrip : ∀ (l : List Bool), l.length = 8 →
    bitsOfByte (byteOfBits l) = l := by
  intro l hl
  have hs := packedBits_spec l 8
  have hnat : (byteOfBits l).toNat = packedBits l 8 := by
    unfold byteOfBits
    change (UInt8.ofNat (packedBits l 8)).toNat = packedBits l 8
    exact UInt8.toNat_ofNat_of_lt' hs.1
  apply List.ext_getElem
  · simp [bitsOfByte, hl]
  · intro i h1 h2
    simp only [bitsOfByte, List.getElem_map, List.getElem_range]
    have hi8 : i < 8 := by simpa [hl] using h2
    have hb := hs.2 i
    rw [if_pos hi8] at hb
    rw [List.getElem_eq_getD false]
    simpa [Nat.testBit, hnat] using hb

/-- T6b: bits → bytes → bits is the identity on whole-byte strings. -/
theorem bits_bytes_roundtrip (bits : List Bool) (h : bits.length % 8 = 0) :
    bitsOfBytes (bytesOfBits bits) = bits := by
  rcases Nat.eq_zero_or_pos bits.length with h0 | hpos
  · rw [List.eq_nil_of_length_eq_zero h0]; rfl
  · have h8 : 8 ≤ bits.length := by omega
    calc bitsOfBytes (bytesOfBits bits)
        = bitsOfBytes (bytesOfBits (bits.take 8 ++ bits.drop 8)) := by
          rw [List.take_append_drop]
      _ = bitsOfBytes (byteOfBits (bits.take 8) :: bytesOfBits (bits.drop 8)) := by
          rw [bytesOfBits_append8 _ _ (by rw [List.length_take]; omega)]
      _ = bitsOfByte (byteOfBits (bits.take 8)) ++ bitsOfBytes (bytesOfBits (bits.drop 8)) := rfl
      _ = bits.take 8 ++ bits.drop 8 := by
          rw [bits_byte_roundtrip _ (by rw [List.length_take]; omega),
              bits_bytes_roundtrip (bits.drop 8) (by rw [List.length_drop]; omega)]
      _ = bits := List.take_append_drop 8 bits
termination_by bits.length
decreasing_by simp only [List.length_drop]; omega

/-- R2: the state round trip is the identity on 1600-bit strings. -/
theorem bits_state_roundtrip (S : List Bool) (hS : S.length = 1600) :
    bitsOfState (stateOfBits S) = S := by
  apply List.ext_getElem
  · simp [bitsOfState, hS]
  · intro i h1 h2
    have h1600 : i < 1600 := by
      simpa [bitsOfState] using h1
    simp only [bitsOfState, List.getElem_map, List.getElem_range, stateOfBits]
    have hidx : 64 * (5 * (i / 64 / 5 % 5) + i / 64 % 5) + i % 64 = i := by omega
    rw [hidx, List.getD_eq_getElem?_getD, List.getElem?_eq_getElem h2, Option.getD_some]

end Hash.Sha3.Roundtrips
