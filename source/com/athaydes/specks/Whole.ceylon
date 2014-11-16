
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

Byte zero = 0.byte;
Byte one = 1.byte;
Byte ff = #FF.byte;

shared final class WholeImpl(Integer|String|[Byte+] number) satisfies Whole {
    
    [Byte+] bytes;
    
    switch(number)
    case (is Integer) {
        bytes = toBinary(number);
    } case (is String) {
        bytes = stringToBinary(number);
    } case (is [Byte+]) {
        bytes = number;
    }
    
    Result traverseBits<Result>([Byte+] thisBytes, [Byte+] otherBytes,
        Result? processBit(Boolean thisBit,Boolean otherBit),
        Result defaultResult)
            given Result satisfies Object {
        for (thisByte -> otherByte in zipEntries(thisBytes, otherBytes)) {
            for (bitIndex in 7..0) {
                value result = processBit(thisByte.get(bitIndex), otherByte.get(bitIndex));
                if (exists result) {
                    return result;
                }
            }
        }
        return defaultResult;
    }
    
    Result traverseBitsReversed<Result>([Byte+] thisBytes, [Byte+] otherBytes,
        Result? processBit(Boolean thisBit,Boolean otherBit),
        Result defaultResult)
            given Result satisfies Object {
        for (thisByte -> otherByte in zipEntries(thisBytes.reversed, otherBytes.reversed)) {
            for (bitIndex in 0..7) {
                value result = processBit(thisByte.get(bitIndex), otherByte.get(bitIndex));
                if (exists result) {
                    return result;
                }
            }
        }
        return defaultResult;
    }
    
    Result? nullIf<Result>(Result nullValue)(Result result)
            given Result satisfies Object {
        if (result == nullValue) {
            return null;
        }
        return result;
    }

    "Assumes bytes have the same length and both numbers are positive"
    Comparison compareBytes([Byte+] thisBytes, [Byte+] otherBytes) {
        assert(thisBytes.size == otherBytes.size);
        return traverseBits(thisBytes, otherBytes, compose(nullIf(equal), compareBits), equal);
    }

    shared actual Comparison compare(Whole other) {
        assert(is WholeImpl other);
        value thisNegative = this.bytes.first.get(7);
        value otherNegative = other.bytes.first.get(7);
        if (thisNegative != otherNegative) {
            return thisNegative then smaller else larger;
        }
        
        // here we know both numbers have the same sign
        value lengthDifference = this.bytes.size - other.bytes.size;
        
        switch(lengthDifference)
        case (0) {
            return compareBytes(this.bytes, other.bytes);
        } case (1) {
            value zeroByte = thisNegative then ff else package.zero;
            if (this.bytes.first.signed == zeroByte.signed) {
                return compareBytes(this.bytes, [zeroByte].append(other.bytes));
            }
        } case (-1) {
            value zeroByte = thisNegative then ff else package.zero;
            if (other.bytes.first.signed == zeroByte.signed) {
                return compareBytes([zeroByte].append(this.bytes), other.bytes);
            }
        } else {} // no special case
        
        return lengthDifference > 0 then 
            (thisNegative then smaller else larger) else
            (thisNegative then larger else smaller);
    }
    
    shared actual Whole plus(Whole other) {
        assert(is WholeImpl other);
        print("``this.bytes`` Plus ``other.bytes``");
        variable Boolean carry = false;
        variable Boolean previousCarry = false;
        variable [Byte+] result = [Byte(0)];
        variable Integer index = 0;
        value length = max { bytes.size, other.bytes.size };
        traverseBitsReversed(pad(this.bytes, length), pad(other.bytes, length), (thisBit, otherBit) {
            if (index == 8) {
                index = 0;
                print("Result = ``result``");
                result = [package.zero].append(result);
            }
            value bit = (thisBit != otherBit) != carry;
            previousCarry = carry;
            carry = thisBit then (otherBit || carry) else (otherBit && carry);
            result = [result.first.set(index, bit)].append(result.rest);
            print("(``thisBit``, ``otherBit``) - carry = ``carry``, bit = ``bit``, result = ``result``");
            index++;
            return null; // continue traversal
        }, WholeImpl(0));
        if (previousCarry != carry) { // overflow, must add another byte
            return WholeImpl([carry then ff else package.zero].append(result));
        } else {
            return WholeImpl(result);
        }
    }
    
    shared actual Whole plusInteger(Integer integer)
            => plus(WholeImpl(integer));
    
    shared actual Whole divided(Whole other) => nothing;
    
    shared actual Whole fractionalPart => WholeImpl([package.zero]);
    
    shared actual Object? implementation => null;
    
    shared actual Boolean positive = !bytes.first.get(7);
    
    shared actual Integer integer => nothing;
    
    shared actual Float float {
        try {
            return integer.float;
        } catch (OverflowException e) {
            return positive then infinity else -infinity;
        }
    }
    
    shared actual Whole negated => nothing;
    
    shared actual Boolean negative = bytes.first.get(7);
    
    shared actual Whole neighbour(Integer offset) => nothing;
    
    shared actual Integer offset(Whole other) => nothing;
    
    shared actual Whole power(Whole exponent) => nothing;
    
    shared actual Whole powerOfInteger(Integer integer)
            => power(WholeImpl(integer));
    
    shared actual Whole powerRemainder(Whole exponent, Whole modulus) => nothing;
    
    shared actual Whole remainder(Whole other) => nothing;
    
    shared actual Whole times(Whole other) => nothing;
    
    shared actual Whole timesInteger(Integer integer)
            => times(WholeImpl(integer));
    
    shared actual Boolean unit = bytes.size == 1 && bytes.first == package.one;
    
    shared actual Whole wholePart => WholeImpl(bytes);
    
    shared actual Boolean zero = bytes.size == 1 && bytes.first == package.zero;
    
    string = bytes.string;
    
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

[Byte+] addMSBIfNeeded(Comparison comparisonToZero, [Byte+] bytes) {
    if (comparisonToZero == larger && bytes.first.rightLogicalShift(7) == one) {
        return [zero].append(bytes);
    }
    if (comparisonToZero == smaller && bytes.first.rightLogicalShift(7) == zero) {
        return [ff].append(bytes);
    }
    return bytes;
}

shared [Byte+] stringToBinary(String number) {
    value asInt = parseInteger(number);
    if (exists asInt) {
        return toBinary(asInt);
    }
    
    value negative = number.startsWith("-");
    value unsignedNumber = (negative then number[1..number.size] else number);
    // String of at least size 4 that may start with 0's to always have an even size
    value rawNumber = unsignedNumber.padLeading(max { 4, unsignedNumber.size + (unsignedNumber.size.even then 0 else 1) }, '0');
    
    variable [Byte+] result = [zero];
    
    void parsePart("2-digit part" String part, Integer index) {
        assert(is String p1 = part[0]?.string, is String p2 = part[1]?.string);
        value digit1 = parseInteger(p1);
        value digit2 = parseInteger(p2);
        
    }
    
    for (index in ((rawNumber.size - 2)..2).filter(Integer.even)) {
        value part = rawNumber[index:2];
        parsePart(part, index);
    }
    return result;
}

shared [Byte+] toBinary(Integer number) {
    value byteMax = 256;
    value bytes = bytesIn(number) - 1;
    variable Integer remaining = number;
    variable Integer part = 0;
    variable Integer previousPart = 0;
    return addMSBIfNeeded(number <=> 0, (0..bytes).collect((index) {
        part = remaining % byteMax;
        
        // Correction for negative numbers.
        // There is a 1-off error when transferring bits to a higher byte,
        // except when transferring the first bit (ie. previousPart == 0)
        if (number.negative && previousPart != 0) {
            part--;
        }
        previousPart = part;
        remaining /= byteMax;
        return part.byte;
    }).reversed);
}

Integer bytesIn(Integer number) {
    Integer magnitude = number.magnitude;
    if (magnitude <= #FF) {
        return 1;
    }
    if (magnitude <= #FF_FF) {
        return 2;
    }
    if (magnitude <= #FF_FF_FF) {
        return 3;
    }
    if (magnitude <= #FF_FF_FF_FF) {
        return 4;
    }
    if (magnitude <= #FF_FF_FF_FF_FF) {
        return 5;
    }
    if (magnitude <= #FF_FF_FF_FF_FF_FF) {
        return 6;
    }
    if (magnitude <= #FF_FF_FF_FF_FF_FF_FF) {
        return 7;
    }
    return 8;
}

Comparison compareBits(Boolean bit1, Boolean bit2) {
    if (bit1 == bit2) {
        return equal;
    } else {
        return bit1 then larger else smaller;
    }
}

"Pads the byte to the given length, using the value of the first bit of bytes."
[Byte+] pad([Byte+] bytes, Integer length) {
    value diff = length - bytes.size;
    if (diff > 0) {
        value result = [bytes.first.get(7) then ff else zero].repeat(diff).append(bytes);
        assert(is [Byte+] result); // repeat causes type-loss
        return result;
    } else {
        return bytes;
    }
}

shared Byte binaryAdd(Byte a, Byte b) {
    return a + b;
}
