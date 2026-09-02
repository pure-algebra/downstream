import Hash.Sha3.Impl
import Hash.Sha3.Bridge
import Init.Data.ByteArray.Lemmas
import Init.Data.UInt.Bitwise
import Init.Data.BitVec.Lemmas
import Init.Data.Vector.OfFn
import Init.Data.Nat.Fold

/-!
# Native SHA3-512

The native lane permutation uses the same flat state layout as `Hash.Sha3.Impl`.
The abstraction lemmas below relate each native operation to that reference.
-/

namespace Hash.Sha3.Fast

abbrev Lane := UInt64
abbrev State := Vector Lane 25

@[inline] def rotl (x : Lane) (n : Nat) : Lane :=
  (x <<< n.toUInt64) ||| (x >>> (64 - n).toUInt64)

def rcv : Vector Lane 24 := #v[
  0x0000000000000001, 0x0000000000008082, 0x800000000000808A, 0x8000000080008000,
  0x000000000000808B, 0x0000000080000001, 0x8000000080008081, 0x8000000000008009,
  0x000000000000008A, 0x0000000000000088, 0x0000000080008009, 0x000000008000000A,
  0x000000008000808B, 0x800000000000008B, 0x8000000000008089, 0x8000000000008003,
  0x8000000000008002, 0x8000000000000080, 0x000000000000800A, 0x800000008000000A,
  0x8000000080008081, 0x8000000000008080, 0x0000000080000001, 0x8000000080008008]

def rhov : Vector Nat 25 := #v[
   0,  1, 62, 28, 27, 36, 44,  6, 55, 20,  3, 10, 43,
  25, 39, 41, 45, 15, 21,  8, 18,  2, 61, 56, 14]

@[inline] private def at5 (a : State) (x y : Nat) : Lane :=
  a[(x % 5) + 5 * (y % 5)]'(by
    have := Nat.mod_lt x (by decide : 0 < 5)
    have := Nat.mod_lt y (by decide : 0 < 5)
    omega)

def theta (a : State) : State :=
  let col : Nat → Lane := fun x ↦
    at5 a x 0 ^^^ at5 a x 1 ^^^ at5 a x 2 ^^^ at5 a x 3 ^^^ at5 a x 4
  let d : Nat → Lane := fun x ↦ col ((x + 4) % 5) ^^^ rotl (col ((x + 1) % 5)) 1
  Vector.ofFn (fun i : Fin 25 ↦ a[i] ^^^ d (i.val % 5))

def rhoPi (a : State) : State :=
  Vector.ofFn (fun i : Fin 25 ↦
    let X := i.val % 5
    let Y := i.val / 5
    let y := X
    let x := (3 * (Y + 5 - (3 * X) % 5)) % 5
    rotl (at5 a x y) (rhov[x + 5 * y]'(by
      have := Nat.mod_lt (3 * (Y + 5 - (3 * X) % 5)) (by decide : 0 < 5)
      have := Nat.mod_lt i.val (by decide : 0 < 5)
      omega)))

def chi (a : State) : State :=
  Vector.ofFn (fun i : Fin 25 ↦
    let x := i.val % 5
    let y := i.val / 5
    at5 a x y ^^^ ((~~~at5 a (x + 1) y) &&& at5 a (x + 2) y))

def rnd (a : State) (i : Fin 24) : State :=
  let b := chi (rhoPi (theta a))
  b.set 0 (b[0] ^^^ rcv[i])

def keccakF (a : State) : State :=
  Nat.fold 24 (fun i h s ↦ rnd s ⟨i, h⟩) a

/-- Abstraction to the proved layer. -/
def abs (s : State) : Impl.St := s.map UInt64.toBitVec

theorem toBitVec_rotl (x : Lane) (n : Nat) (h : n < 64) :
    (rotl x n).toBitVec = x.toBitVec.rotateLeft n := by
  by_cases hn : n = 0
  · subst n
    simp [rotl, BitVec.ushiftRight_eq', BitVec.rotateLeft_def,
      BitVec.ushiftRight_eq_zero (by omega : 64 ≤ 64)]
  · have hn64 : n < 2 ^ 64 := by omega
    have hsub : 64 - n < 64 := by omega
    have hsub64 : 64 - n < 2 ^ 64 := by omega
    simp [rotl, BitVec.shiftLeft_eq', BitVec.ushiftRight_eq', BitVec.toNat_umod,
      Nat.toUInt64, UInt64.toNat_ofNat', Nat.mod_eq_of_lt hn64,
      Nat.mod_eq_of_lt hsub64, Nat.mod_eq_of_lt h, Nat.mod_eq_of_lt hsub,
      BitVec.rotateLeft_def]

theorem rcv_eq (i : Fin 24) : (rcv[i]).toBitVec = Impl.rcv[i] := by
  exact (show ∀ j : Fin 24, (rcv[j]).toBitVec = Impl.rcv[j] from by decide) i

theorem rhov_eq : rhov = Impl.rhov := rfl

private theorem rhov_all_lt : ∀ j : Fin 25, rhov[j] < 64 := by decide

private theorem rhov_lt (i : Nat) (h : i < 25) : rhov[i] < 64 := by
  simpa only [Fin.getElem_fin] using rhov_all_lt ⟨i, h⟩

private theorem at5_abs (s : State) (x y : Nat) :
    (at5 s x y).toBitVec = Impl.at5 (abs s) x y := by
  have h : x % 5 + 5 * (y % 5) < 25 := by
    have := Nat.mod_lt x (by decide : 0 < 5)
    have := Nat.mod_lt y (by decide : 0 < 5)
    omega
  unfold Impl.at5
  rw [getElem!_pos (abs s) (x % 5 + 5 * (y % 5)) h]
  simp only [at5, abs, Vector.getElem_map]

theorem theta_abs (s : State) : abs (theta s) = Impl.theta (abs s) := by
  apply Vector.ext
  intro i hi
  simp only [abs, theta, Impl.theta, Vector.getElem_map, Vector.getElem_ofFn, Fin.getElem_fin,
    UInt64.toBitVec_xor, toBitVec_rotl _ 1 (by decide), at5_abs]

theorem rhoPi_abs (s : State) : abs (rhoPi s) = Impl.rhoPi (abs s) := by
  apply Vector.ext
  intro i hi
  have hidx : (3 * (i / 5 + 5 - (3 * (i % 5)) % 5)) % 5 + 5 * (i % 5) < 25 := by
    have := Nat.mod_lt (3 * (i / 5 + 5 - (3 * (i % 5)) % 5)) (by decide : 0 < 5)
    have := Nat.mod_lt i (by decide : 0 < 5)
    omega
  simp only [abs, rhoPi, Impl.rhoPi, Vector.getElem_map, Vector.getElem_ofFn]
  rw [toBitVec_rotl _ _ (rhov_lt _ hidx), at5_abs]
  rw [getElem!_pos Impl.rhov
    ((3 * (i / 5 + 5 - (3 * (i % 5)) % 5)) % 5 + 5 * (i % 5)) hidx]
  rfl

theorem chi_abs (s : State) : abs (chi s) = Impl.chi (abs s) := by
  apply Vector.ext
  intro i hi
  simp only [abs, chi, Impl.chi, Vector.getElem_map, Vector.getElem_ofFn,
    UInt64.toBitVec_xor, UInt64.toBitVec_and, UInt64.toBitVec_not, at5_abs]

theorem rnd_abs (s : State) (i : Fin 24) : abs (rnd s i) = Impl.rnd (abs s) i.val := by
  unfold rnd Impl.rnd
  simp only [abs, Vector.map_set, UInt64.toBitVec_xor]
  change (abs (chi (rhoPi (theta s)))).set 0
    ((chi (rhoPi (theta s)))[0].toBitVec ^^^ (rcv[i]).toBitVec) = _
  rw [← Vector.getElem_map UInt64.toBitVec (by decide : 0 < 25)]
  change (abs (chi (rhoPi (theta s)))).set 0
    ((abs (chi (rhoPi (theta s))))[0] ^^^ (rcv[i]).toBitVec) = _
  rw [chi_abs, rhoPi_abs, theta_abs, rcv_eq]
  rw [getElem!_pos Impl.rcv i.val i.isLt]
  rfl

theorem keccakF_abs (s : State) : abs (keccakF s) = Impl.keccakF (abs s) := by
  have hgen : ∀ (n : Nat) (hn : n ≤ 24),
      abs (Nat.fold n (fun i h a ↦ rnd a ⟨i, Nat.lt_of_lt_of_le h hn⟩) s) =
        (List.range n).foldl Impl.rnd (abs s) := by
    intro n
    induction n with
    | zero => intro _; rfl
    | succ n ih =>
      intro hn
      simp only [Nat.fold_succ, rnd_abs, List.range_succ, List.foldl_append,
        List.foldl_cons, List.foldl_nil]
      rw [ih (by omega)]
  exact hgen 24 (by omega)

/-- A total byte read; absent bytes contribute zero. -/
def byteAt (bs : ByteArray) (i : Nat) : UInt8 :=
  if h : i < bs.size then bs[i] else 0

/-- Eight little-endian bytes, read directly from the source buffer. -/
def laneAt (bs : ByteArray) (off i : Nat) : Lane :=
  (List.range 8).foldl
    (fun acc j => acc ||| ((byteAt bs (off + 8 * i + j)).toUInt64 <<< UInt64.ofNat (8 * j))) 0

/-- Byte-aligned SHA3 domain separation and pad10*1 at rate 72 bytes. -/
def padBytes (msg : ByteArray) : ByteArray :=
  let padLen := 72 - msg.size % 72
  if padLen = 1 then msg ++ ⟨#[0x86]⟩
  else msg ++ ⟨#[0x06] ++ Array.replicate (padLen - 2) 0 ++ #[0x80]⟩

/-- Absorb exactly the nine rate lanes; capacity lanes never read the next block. -/
def absorbBlock (s : State) (bs : ByteArray) (off : Nat) : State :=
  keccakF (Vector.ofFn fun i : Fin 25 =>
    s[i] ^^^ if i.val < 9 then laneAt bs off i.val else 0)

/-- Absorb the complete rate blocks; any incomplete suffix is ignored. -/
def absorbAll (P : ByteArray) : State :=
  Nat.fold (P.size / 72) (fun i _ s => absorbBlock s P (i * 72)) (Vector.replicate 25 0)

/-- The first eight lanes, emitted little-endian as exactly 64 bytes. -/
def squeeze (s : State) : ByteArray :=
  ((List.finRange 8).flatMap fun i =>
    (List.range 8).map fun j =>
      (s[i.val]'(by have := i.isLt; omega) >>> UInt64.ofNat (8 * j)).toUInt8).toByteArray

/-- Native SHA3-512 on a byte array. -/
def sha3_512 (msg : ByteArray) : ByteArray := squeeze (absorbAll (padBytes msg))

theorem byteAt_eq (bs : ByteArray) (i : Nat) : byteAt bs i = bs.data.toList.getD i 0 := by
  unfold byteAt
  by_cases h : i < bs.size
  · simp only [h, dite_true, List.getD_eq_getElem?_getD]
    rw [List.getElem?_eq_getElem (by simpa only [Array.length_toList, ByteArray.size] using h)]
    rfl
  · simp only [h, dite_false, List.getD_eq_getElem?_getD]
    rw [List.getElem?_eq_none
      (by simpa only [Array.length_toList, ByteArray.size] using Nat.le_of_not_lt h)]
    rfl

private theorem byteAt_drop (bs : ByteArray) (off j : Nat) :
    byteAt bs (off + j) = (bs.data.toList.drop off).getD j 0 := by
  simp only [byteAt_eq, List.getD_eq_getElem?_getD, List.getElem?_drop]

private theorem byte_widen (b : UInt8) : b.toUInt64.toBitVec = BitVec.ofNat 64 b.toNat := by
  apply BitVec.eq_of_toNat_eq
  simp

theorem laneAt_eq (bs : ByteArray) (off i : Nat) :
    (laneAt bs off i).toBitVec = Impl.laneOfBytes (bs.data.toList.drop off) i := by
  simp only [laneAt, Impl.laneOfBytes, List.range_succ, List.range_zero,
    List.foldl_append, List.foldl_cons, List.foldl_nil, UInt64.toBitVec_or,
    UInt64.toBitVec_shiftLeft, UInt64.toBitVec_zero, UInt64.toBitVec_ofNat',
    byte_widen, Nat.add_assoc, byteAt_drop]
  rfl

theorem padBytes_eq (msg : ByteArray) :
    (padBytes msg).data.toList = Impl.padBytes msg.data.toList := by
  simp only [padBytes, Impl.padBytes, Impl.rateBytes, Array.length_toList,
    ByteArray.size_data]
  split <;> rename_i h
  · simp only [h, if_pos, ByteArray.toList_data_append]
  · simp only [h, if_false, ByteArray.toList_data_append]
    simp only [Array.toList_append, Array.toList_replicate, List.append_assoc]
    rfl

private theorem laneOfBytes_take (bs : List UInt8) (i : Nat) (hi : i < 9) :
    Impl.laneOfBytes (bs.take 72) i = Impl.laneOfBytes bs i := by
  have hb (j : Nat) (hj : j < 8) :
      (bs.take 72).getD (8 * i + j) 0 = bs.getD (8 * i + j) 0 := by
    simp only [List.getD_eq_getElem?_getD, List.getElem?_take_of_lt (by omega : 8 * i + j < 72)]
  simp only [Impl.laneOfBytes, List.range_succ, List.range_zero, List.foldl_append,
    List.foldl_cons, List.foldl_nil]
  simp only [hb 0 (by omega), hb 1 (by omega), hb 2 (by omega), hb 3 (by omega),
    hb 4 (by omega), hb 5 (by omega), hb 6 (by omega), hb 7 (by omega)]

private theorem laneOfBytes_capacity (bs : List UInt8) (i : Nat) (hi : 9 ≤ i) :
    Impl.laneOfBytes (bs.take 72) i = 0 := by
  have hb (j : Nat) : (bs.take 72).getD (8 * i + j) 0 = 0 := by
    simp only [List.getD_eq_getElem?_getD, List.getElem?_take_eq_none (by omega : 72 ≤ 8 * i + j)]
    rfl
  simp only [Impl.laneOfBytes, List.range_succ, List.range_zero, List.foldl_append,
    List.foldl_cons, List.foldl_nil, hb]
  rfl

private theorem absorbBlock_abs (s : State) (bs : ByteArray) (off : Nat) :
    abs (absorbBlock s bs off) =
      Impl.absorbBlock (abs s) ((bs.data.toList.drop off).take 72) := by
  rw [absorbBlock, keccakF_abs, Impl.absorbBlock]
  apply congrArg Impl.keccakF
  apply Vector.ext
  intro i hi
  simp only [abs, Vector.getElem_map, Vector.getElem_ofFn, Fin.getElem_fin,
    UInt64.toBitVec_xor]
  by_cases hr : i < 9
  · simp only [hr, if_true, laneAt_eq, laneOfBytes_take _ _ hr]
  · simp only [hr, if_false, UInt64.toBitVec_zero,
      laneOfBytes_capacity _ _ (Nat.le_of_not_lt hr)]
    rfl

private theorem absorb_fold_abs (P : ByteArray) (n : Nat) :
    abs (Nat.fold n (fun i _ s => absorbBlock s P (i * 72)) (Vector.replicate 25 0)) =
      (List.range n).foldl
        (fun s i => Impl.absorbBlock s ((P.data.toList.drop (i * 72)).take 72))
        (Vector.replicate 25 0) := by
  induction n with
  | zero => simp [abs]
  | succ n ih =>
      simp only [Nat.fold_succ, List.range_succ, List.foldl_append,
        List.foldl_cons, List.foldl_nil, absorbBlock_abs, ih]

theorem absorbAll_abs (P : ByteArray) : abs (absorbAll P) = Impl.absorbAll P.data.toList := by
  rw [absorbAll, absorb_fold_abs, Bridge.absorbAll_eq]
  simp only [Array.length_toList, ByteArray.size_data, Impl.rateBytes]

private theorem squeeze_byte (w : Lane) (j : Nat) (hj : j < 8) :
    (w >>> UInt64.ofNat (8 * j)).toUInt8 =
      UInt8.ofNat ((w.toBitVec >>> (8 * j)).toNat &&& 0xFF) := by
  apply UInt8.toNat.inj
  simp only [UInt64.toNat_toUInt8, UInt64.toNat_shiftRight, UInt64.toNat_ofNat',
    UInt8.toNat_ofNat', BitVec.toNat_ushiftRight, UInt64.toNat_toBitVec]
  have hj64 : 8 * j < 64 := by omega
  have hjlarge : 8 * j < 2 ^ 64 := by omega
  rw [Nat.mod_eq_of_lt hjlarge, Nat.mod_eq_of_lt hj64]
  simp only [show 0xFF = 2 ^ 8 - 1 by rfl, Nat.and_two_pow_sub_one_eq_mod]
  omega

theorem squeeze_eq (s : State) :
    (squeeze s).data.toList = ((List.range 8).map fun i => Impl.bytesOfLane (abs s)[i]!).flatten := by
  simp only [squeeze, List.toList_data_toByteArray, List.flatMap]
  apply congrArg List.flatten
  apply List.ext_getElem
  · simp
  · intro i hi hi'
    have hi8 : i < 8 := by simpa only [List.length_map, List.length_finRange] using hi
    simp only [List.getElem_map, List.getElem_finRange, List.getElem_range,
      Impl.bytesOfLane]
    apply List.map_congr_left
    intro j hj
    rw [squeeze_byte _ _ (List.mem_range.mp hj)]
    rw [getElem!_pos (abs s) i (by omega)]
    simp only [abs, Vector.getElem_map]
    rfl

theorem size_squeeze (s : State) : (squeeze s).size = 64 := by
  simp only [squeeze, List.size_toByteArray, List.length_flatMap, List.length_map,
    List.length_range, List.map_const', List.length_finRange]
  rfl

/-- The apex of the native layer. -/
theorem sha3_512_eq_impl (msg : ByteArray) :
    (sha3_512 msg).data.toList = Impl.sha3_512 msg.data.toList := by
  rw [sha3_512, squeeze_eq, absorbAll_abs, padBytes_eq]
  rfl

theorem size_sha3_512 (msg : ByteArray) : (sha3_512 msg).size = 64 :=
  size_squeeze _

end Hash.Sha3.Fast
