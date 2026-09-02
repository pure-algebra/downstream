import HashGates.SelfTest

/-- Entry point only; the audited logic is HashGates.SelfTest.cli. -/
def main (args : List String) : IO UInt32 := HashGates.SelfTest.cli args
