import HashGates.TrustSelfTest

/-- Entry point only; the audited logic is HashGates.TrustSelfTest.cli. -/
def main (args : List String) : IO UInt32 := HashGates.TrustSelfTest.cli args
