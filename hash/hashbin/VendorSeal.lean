import HashGates.VendorSeal

/-- Entry point only; the audited logic is HashGates.VendorSeal.cli. -/
def main (args : List String) : IO UInt32 := HashGates.VendorSeal.cli args
