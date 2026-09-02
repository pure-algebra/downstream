import HashGates.Sha3

/-- Entry point only; the audited logic is HashGates.Sha3.cli. -/
def main (args : List String) : IO UInt32 := HashGates.Sha3.cli args
