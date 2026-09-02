import Hash.Sha3.Hex

/-! Fixed-width digests with canonical hexadecimal conversion. -/

namespace Hash.Sha3

/-- Bytes whose length is carried by the type. -/
structure Digest (n : Nat) where
  bytes : ByteArray
  size_eq : bytes.size = n

namespace Digest

variable {n : Nat}

def toByteArray (d : Digest n) : ByteArray := d.bytes

def toList (d : Digest n) : List UInt8 := d.bytes.data.toList

def toHex (d : Digest n) : String := Hex.encode d.bytes

def ofHex? (n : Nat) (s : String) : Option (Digest n) :=
  match Hex.decode? s with
  | none => none
  | some bytes => if h : bytes.size = n then some ⟨bytes, h⟩ else none

theorem ext {a b : Digest n} (h : a.bytes = b.bytes) : a = b := by
  cases a
  cases b
  cases h
  rfl

theorem size_toByteArray (d : Digest n) : d.toByteArray.size = n := d.size_eq

theorem length_toList (d : Digest n) : d.toList.length = n := by
  simpa only [toList, Array.length_toList, ByteArray.size_data] using d.size_eq

theorem length_toHex (d : Digest n) : d.toHex.length = 2 * n := by
  rw [toHex, Hex.length_encode, d.size_eq]

theorem ofHex?_toHex (d : Digest n) : ofHex? n d.toHex = some d := by
  simp only [ofHex?, toHex, Hex.decode?_encode, d.size_eq, dite_true]

instance : BEq (Digest n) where
  beq a b := a.bytes == b.bytes

instance : DecidableEq (Digest n) := fun a b ↦
  if h : a.bytes = b.bytes then isTrue (ext h)
  else isFalse (fun hab ↦ h (congrArg Digest.bytes hab))

end Digest
end Hash.Sha3
