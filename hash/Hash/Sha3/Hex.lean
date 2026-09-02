/-! Canonical lowercase hexadecimal encoding and checked decoding. -/

namespace Hash.Sha3.Hex

private def digit : Nat → Char
  | 0 => '0'
  | 1 => '1'
  | 2 => '2'
  | 3 => '3'
  | 4 => '4'
  | 5 => '5'
  | 6 => '6'
  | 7 => '7'
  | 8 => '8'
  | 9 => '9'
  | 10 => 'a'
  | 11 => 'b'
  | 12 => 'c'
  | 13 => 'd'
  | 14 => 'e'
  | _ => 'f'

private def decodeDigit? : Char → Option Nat
  | '0' => some 0
  | '1' => some 1
  | '2' => some 2
  | '3' => some 3
  | '4' => some 4
  | '5' => some 5
  | '6' => some 6
  | '7' => some 7
  | '8' => some 8
  | '9' => some 9
  | 'a' => some 10
  | 'b' => some 11
  | 'c' => some 12
  | 'd' => some 13
  | 'e' => some 14
  | 'f' => some 15
  | _ => none

private def encodeList : List UInt8 → List Char
  | [] => []
  | b :: bs => digit (b.toNat / 16) :: digit (b.toNat % 16) :: encodeList bs

private def decodeList? : List Char → Option (List UInt8)
  | [] => some []
  | [_] => none
  | hi :: lo :: cs =>
    match decodeDigit? hi, decodeDigit? lo, decodeList? cs with
    | some h, some l, some bs => some (UInt8.ofNat (16 * h + l) :: bs)
    | _, _, _ => none

/-- Two lowercase hexadecimal characters per byte, in byte order. -/
def encode (bs : ByteArray) : String := String.ofList (encodeList bs.data.toList)

/-- Decode lowercase hexadecimal, rejecting odd lengths and every other character. -/
def decode? (s : String) : Option ByteArray := (decodeList? s.toList).map List.toByteArray

private theorem digit_properties (n : Nat) (h : n < 16) :
    decodeDigit? (digit n) = some n ∧ (digit n).toLower = digit n := by
  have hn : n = 0 ∨ n = 1 ∨ n = 2 ∨ n = 3 ∨ n = 4 ∨ n = 5 ∨ n = 6 ∨ n = 7 ∨
      n = 8 ∨ n = 9 ∨ n = 10 ∨ n = 11 ∨ n = 12 ∨ n = 13 ∨ n = 14 ∨ n = 15 := by omega
  rcases hn with h | h | h | h | h | h | h | h | h | h | h | h | h | h | h | h <;>
    subst n <;> exact ⟨rfl, rfl⟩

private theorem length_encodeList (bs : List UInt8) : (encodeList bs).length = 2 * bs.length := by
  induction bs with
  | nil => rfl
  | cons b bs ih => simp only [encodeList, List.length_cons, ih]; omega

private theorem decodeList?_encodeList (bs : List UInt8) :
    decodeList? (encodeList bs) = some bs := by
  induction bs with
  | nil => rfl
  | cons b bs ih =>
    have hb : b.toNat < 256 := b.toBitVec.isLt
    have hhi : b.toNat / 16 < 16 := by omega
    have hlo : b.toNat % 16 < 16 := by omega
    have hsplit : 16 * (b.toNat / 16) + b.toNat % 16 = b.toNat := by omega
    simp only [encodeList, decodeList?, (digit_properties _ hhi).1,
      (digit_properties _ hlo).1, ih, hsplit, UInt8.ofNat_toNat]

private theorem encodeList_lower (bs : List UInt8) :
    ∀ c ∈ encodeList bs, c.toLower = c := by
  induction bs with
  | nil => simp only [encodeList, List.not_mem_nil, false_implies, implies_true]
  | cons b bs ih =>
    have hb : b.toNat < 256 := b.toBitVec.isLt
    intro c hc
    simp only [encodeList, List.mem_cons] at hc
    rcases hc with rfl | rfl | hc
    · exact (digit_properties _ (by omega)).2
    · exact (digit_properties _ (by omega)).2
    · exact ih c hc

theorem length_encode (bs : ByteArray) : (encode bs).length = 2 * bs.size := by
  simp only [encode, String.length_ofList, length_encodeList, Array.length_toList,
    ByteArray.size_data]

theorem decode?_encode (bs : ByteArray) : decode? (encode bs) = some bs := by
  simp only [decode?, encode, String.toList_ofList, decodeList?_encodeList, Option.map_some]
  congr 1
  apply ByteArray.ext
  simp only [List.data_toByteArray, Array.toArray_toList]

theorem encode_lower (bs : ByteArray) : ∀ c ∈ (encode bs).toList, c.toLower = c := by
  simpa only [encode, String.toList_ofList] using encodeList_lower bs.data.toList

end Hash.Sha3.Hex
