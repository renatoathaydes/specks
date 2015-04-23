class Random(
    Integer seed = system.nanoseconds) {
    
    Integer lower32(Integer int) => int % 2^32;
    
    value s = Array { lower32(seed), lower32(seed / 2) };
    
    shared Integer nextInteger() {
        value high = next32bits() * 2^32; // shifts 32 bits to the left
        value low = next32bits(); // take only 32 bits as JS bitwise ops use only 32 bits
        
        // "concatenate" low bits to high bits, take only 52 bits so it works the same in Java and JS
        return (high + low) % 2^52;
    }
    
    "Returns a Integer between 0 (incl) and maxLimit (excl), where maxLimit must be > 0"
    shared Integer nextPositive(Integer maxLimit) {
        if (maxLimit <= 0) {
            throw Exception("Illegal argument [maxLimit]: ``maxLimit`` <= 0");
        }
        return (nextInteger() % maxLimit).magnitude;
    }
    
    shared Integer nextInRange(Integer min, Integer max)
        => min + (max == min
            then 0 else nextPositive(max - min));
    
    Integer next32bits() {
        variable value s1 = s[0] else 0;
        value s0 = s[1] else 0;
        s.set(0, s0);
        s1 = lower32(s1.xor(s1.leftLogicalShift(11)));
        s1 = s1.xor(s1.rightLogicalShift(9));
        s1 = lower32(s1.xor(s0.xor(s0.rightLogicalShift(13))));
        s.set(1, s1);
        return lower32(s1 + s0);
    }
    
}
