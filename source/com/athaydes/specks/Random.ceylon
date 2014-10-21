
"Random contains functions that return pseudo-random values on consecutive calls."
shared class Random(
    "Seed to be used for this instance of Random. Using the same seed will produce predictable results."
    Integer seed = system.nanoseconds) {
    
    value s = Array { seed, seed/2 };
    value positiveInvert7Bits = $1000000000001111111111111111111111111111111111111111111111111111;
    value negativeInvert7Bits = $1111111111110000000000000000000000000000000000000000000000000000;
    
    "Returns a pseudo-random Integer value. The value could be any possible Integer within -2^52 and 2^52.
     To scale the value between min/max bounds (so that you only get Integers within the bounds),
     use the [[scale]] function.
     
     The algorithm used is **xorshit+**, as described on
     [this website](http://xorshift.di.unimi.it/)"
    shared Integer nextInteger() {
        variable Integer s1 = s[0] else 0;
        Integer s0 = s[1] else 0;
        s.set(0, s0);
        s1 = s1.xor(s1.leftLogicalShift(23));
        value newS1 = s1.xor(s0).xor(s1.rightLogicalShift(17)).xor(s0.rightLogicalShift(26));
        s.set(1, newS1);
        value result = (newS1 + s0);
        return !result.negative then result.and(positiveInvert7Bits) else result.or(negativeInvert7Bits);
    }
    
}

Integer maxInt = 2^52;
Integer minInt = -maxInt;
Integer maximumIntSpan = maxInt - minInt;

"Scales the given Integer from the bounds -2^52 and 2^52 to the provided bounds.
 
 Examples:
   * scale(0) == 0
   * scale(2^52, -10, 10) == 10
   * scale(-(2^52), -10, 10) == -10"
see(`function Random.nextInteger`)
shared Integer scale(Integer integer, Integer minimum = -1M, Integer maximum = 1M) {
    assert(minimum < maximum);
    return (max {min {integer, maxInt}, minInt} - minInt) *
               (maximum - minimum) / (maximumIntSpan) + minimum;
}

