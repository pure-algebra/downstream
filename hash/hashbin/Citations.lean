import HashGates.Citations

/-- Entry point only; the audited logic is HashGates.Citations.cli. -/
def main (args : List String) : IO UInt32 := HashGates.Citations.cli args
