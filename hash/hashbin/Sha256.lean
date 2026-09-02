import HashGates.Sha256

/-- Entry point only; the audited logic is HashGates.Sha256.cli. -/
def main (args : List String) : IO UInt32 := HashGates.Sha256.cli args
