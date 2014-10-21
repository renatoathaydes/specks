"An arbitrary precision integer."
shared interface Whole 
        of WholeImpl
        satisfies Integral<Whole> &
        Exponentiable<Whole, Whole> {
    
    "The platform-specific implementation object, if any. 
     This is provided for interoperation with the runtime 
     platform."
//    see(`function fromImplementation`)
    shared formal Object? implementation;
    
    "The result of raising this number to the given power.
     
     Special cases:
     
     * Returns one if `this` is one (or all powers)
     * Returns one if `this` is minus one and the power 
       is even
     * Returns minus one if `this` is minus one and the 
       power is odd
     * Returns one if the power is zero.
     * Otherwise negative powers result in an `Exception` 
       being thrown
     "
    throws(`class Exception`, "If passed a negative or large 
                               positive exponent")
    shared formal actual Whole power(Whole exponent);
    
    "The result of `(this**exponent) % modulus`."
    throws(`class Exception`, "If passed a negative modulus")
    shared formal Whole powerRemainder(Whole exponent, 
        Whole modulus);
    
    "The number, represented as an [[Integer]]. If the number is too 
     big to fit in an Integer then an Integer corresponding to the
     lower order bits is returned."
    shared formal Integer integer;
    
    "The number, represented as a [[Float]]. If the magnitude of this number 
     is too large the result will be `infinity` or `-infinity`. If the result
     is finite, precision may still be lost."
    shared formal Float float;
    
    "The distance between this whole and the other whole"
    throws(`class OverflowException`, 
        "The numbers differ by an amount larger than can be represented as an `Integer`")
    shared actual formal Integer offset(Whole other);
}

shared final class WholeImpl(Integer|String number) satisfies Whole {
    
    value bytes = Byte(0);
    

    shared actual Comparison compare(Whole other) => nothing;
    
    shared actual Whole divided(Whole other) => nothing;
    
    shared actual Float float => nothing;
    
    shared actual Whole fractionalPart => nothing;
    
    shared actual Object? implementation => nothing;
    
    shared actual Integer integer => nothing;
    
    shared actual Whole negated => nothing;
    
    shared actual Boolean negative => nothing;
    
    shared actual Whole neighbour(Integer offset) => nothing;
    
    shared actual Integer offset(Whole other) => nothing;
    
    shared actual Whole plus(Whole other) => nothing;
    
    shared actual Whole plusInteger(Integer integer) => nothing;
    
    shared actual Boolean positive => nothing;
    
    shared actual Whole power(Whole exponent) => nothing;
    
    shared actual Whole powerOfInteger(Integer integer) => nothing;
    
    shared actual Whole powerRemainder(Whole exponent, Whole modulus) => nothing;
    
    shared actual Whole remainder(Whole other) => nothing;
    
    shared actual Whole times(Whole other) => nothing;
    
    shared actual Whole timesInteger(Integer integer) => nothing;
    
    shared actual Boolean unit => nothing;
    
    shared actual Whole wholePart => nothing;
    
    shared actual Boolean zero => nothing;
    
    
}

shared Integer binaryToInteger(Byte[] bytes) {
    
    if (nonempty bytes) {
        variable Integer result = 0;
        for (byte in bytes) {
             
        }
    } else {
        return 0;
    }
    return 0;
}

shared [Byte+] toBinary(Integer number) {
    value intDiv = number / #FF;
    if (intDiv == 0) {
        return [Byte(number)];
    }
    if (intDiv == 1) {
        return [Byte((number - #FF) % #FF), Byte(number % #FF)];
    }
    return [Byte(0)];
}

shared Byte binaryAdd(Byte a, Byte b) {
    return a + b;
}
