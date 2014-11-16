import ceylon.test {
    test,
    testExecutor
}

import com.athaydes.specks {
    SpecksTestExecutor,
    Specification,
    toBinary,
    feature,
    Whole,
    WholeImpl
}
import com.athaydes.specks.assertion {
    expect
}
import com.athaydes.specks.matcher {
    toBe,
    equalTo,
    to,
    containSameAs,
    identicalTo
}

[Integer+] toIntArray([Byte+] bytes)
        => bytes.collect((byte) => byte.signed);

{[Integer, [Integer+]]+} tableOfIntegersWithByteArrays = {
    // one-byte numbers
    [-128, toIntArray([Byte($1000_0000)])],
    [-127, toIntArray([Byte($1000_0001)])],
    [-126, toIntArray([Byte($1000_0010)])],
    [-5, toIntArray([Byte($1111_1011)])],
    [-4, toIntArray([Byte($1111_1100)])],
    [-3, toIntArray([Byte($1111_1101)])],
    [-2, toIntArray([Byte($1111_1110)])],
    [-1, toIntArray([Byte($1111_1111)])],
    [0, toIntArray([Byte(0)])],
    [1, toIntArray([Byte(1)])],
    [2, toIntArray([Byte(2)])],
    [126, toIntArray([Byte($0111_1110)])],
    [127, toIntArray([Byte($0111_1111)])],
    
    // two-byte numbers
    [-32768, toIntArray([Byte($1000_0000), Byte($0000_0000)])],
    [-32767, toIntArray([Byte($1000_0000), Byte($0000_0001)])],
    [-32766, toIntArray([Byte($1000_0000), Byte($0000_0010)])],
    [-513, toIntArray([Byte($1111_1101), Byte($1111_1111)])],
    [-512, toIntArray([Byte($1111_1110), Byte($0000_0000)])],
    [-259, toIntArray([Byte($1111_1110), Byte($1111_1101)])],
    [-258, toIntArray([Byte($1111_1110), Byte($1111_1110)])],
    [-257, toIntArray([Byte($1111_1110), Byte($1111_1111)])],
    [-256, toIntArray([Byte($1111_1111), Byte($0000_0000)])],
    [-255, toIntArray([Byte($1111_1111), Byte($0000_0001)])],
    [-130, toIntArray([Byte($1111_1111), Byte($0111_1110)])],
    [-129, toIntArray([Byte($1111_1111), Byte($0111_1111)])],
    [128, toIntArray([Byte($0000_0000), Byte($1000_0000)])],
    [129, toIntArray([Byte($0000_0000), Byte($1000_0001)])],
    [130, toIntArray([Byte($0000_0000), Byte($1000_0010)])],
    [32766, toIntArray([Byte($0111_1111), Byte($1111_1110)])],
    [32767, toIntArray([Byte($0111_1111), Byte($1111_1111)])],
    
    // three-byte numbers
    [-8388608, toIntArray([Byte($1000_0000), Byte($0000_0000), Byte($0000_0000)])],
    [-8388607, toIntArray([Byte($1000_0000), Byte($0000_0000), Byte($0000_0001)])],
    [-32770, toIntArray([Byte($1111_1111), Byte($0111_1111), Byte($1111_1110)])],
    [-32769, toIntArray([Byte($1111_1111), Byte($0111_1111), Byte($1111_1111)])],
    [32768, toIntArray([Byte($0000_0000), Byte($1000_0000), Byte($0000_0000)])],
    [32769, toIntArray([Byte($0000_0000), Byte($1000_0000), Byte($0000_0001)])],
    [65535, toIntArray([Byte($0000_0000), Byte($1111_1111), Byte($1111_1111)])],
    [65536, toIntArray([Byte($0000_0001), Byte($0000_0000), Byte($0000_0000)])],
    [65537, toIntArray([Byte($0000_0001), Byte($0000_0000), Byte($0000_0001)])],
    [8388606, toIntArray([Byte($0111_1111), Byte($1111_1111), Byte($1111_1110)])],
    [8388607, toIntArray([Byte($0111_1111), Byte($1111_1111), Byte($1111_1111)])],
    
    // some random numbers
    [-7654321, toIntArray([Byte($1000_1011), Byte($0011_0100), Byte($0100_1111)])],
    [-49395967, toIntArray([Byte($1111_1101), Byte($0000_1110), Byte($0100_0111), Byte($0000_0001)])],
    [5_555_555_555, toIntArray([Byte($0000_0001), Byte($0100_1011), Byte($0010_0011), Byte($0000_1100), Byte($1110_0011)])],
    [1234567890, toIntArray([Byte($0100_1001), Byte($1001_0110), Byte($0000_0010), Byte($1101_0010)])],
    
    // JavaScript limits
    [9007199254740991, toIntArray([Byte($0001_1111), Byte($1111_1111), Byte($1111_1111), Byte($1111_1111), Byte($1111_1111), Byte($1111_1111), Byte($1111_1111)])],
    [-9007199254740992, toIntArray([Byte($1110_0000), Byte($0000_0000), Byte($0000_0000), Byte($0000_0000), Byte($0000_0000), Byte($0000_0000), Byte($0000_0000)])]
    
};

{[String, [Integer+]]+} tableOfStringsWithByteArrays = {
    ["0", toIntArray([Byte(0)])],
    // 2^64
    ["18446744073709551616", toIntArray([Byte(0), Byte($1000_0000), Byte(0), Byte(0), Byte(0), Byte(0), Byte(0), Byte(0), Byte(0)])],
    // 2^65
    ["36893488147419103232", toIntArray([Byte(1), Byte(0), Byte(0), Byte(0), Byte(0), Byte(0), Byte(0), Byte(0), Byte(0)])]
};


shared void run1() {
    variable Integer prev = 0;
    (3..30).collect((i) { value b = 10^i; print(prev > b then "OVERFLOW at ``i``" else toBinary(b)); return prev = b; } );    
}

testExecutor(`class SpecksTestExecutor`)
class WholeTest() {
    
    
    test shared Specification toBinarySpeck() => Specification {
        feature {
            description = "toBinary must convert Integer to an array of Bytes in two's complement notation";
            
            when(Integer input, [Integer+] expected)
                    => [toBinary(input), expected];
            
            examples = tableOfIntegersWithByteArrays;
               
            ([Byte+] result, [Integer+] expected)
                    => expect(toIntArray(result), to(containSameAs(expected)))
        }
    };
    
    //test shared Specification stringToBinarySpeck() => Specification {
    //    feature {
    //        description = "stringToBinary must convert String to an array of Bytes in two's complement notation";
    //        
    //        when(String|Integer input, [Integer+] expected)
    //                => [stringToBinary(input.string), expected];
    //        
    //        examples = tableOfIntegersWithByteArrays.chain(tableOfStringsWithByteArrays);
    //        
    //        ([Byte+] result, [Integer+] expected)
    //                => expect(toIntArray(result), to(containSameAs(expected)))
    //    }
    //};
    
    test shared Specification compareSpeck() => Specification {
        feature {
            description = "Comparison should work as in numbers";
            
            when(Whole w1, Whole w2, Comparison expected)
                    => [w1.compare(w2), expected];
            
            examples = [
                [WholeImpl(1), WholeImpl(1), equal],
                [WholeImpl(1k), WholeImpl(1k), equal],
                [WholeImpl(1k), WholeImpl(1k), equal],
                [WholeImpl(0), WholeImpl(1), smaller],
                [WholeImpl(1), WholeImpl(2), smaller],
                [WholeImpl(10M), WholeImpl(100M), smaller],
                [WholeImpl(1), WholeImpl(0), larger],
                [WholeImpl(2), WholeImpl(1), larger],
                [WholeImpl(20M), WholeImpl(10M), larger],
                [WholeImpl(987654321), WholeImpl(8765432100), smaller],
                [WholeImpl(7^9), WholeImpl(7^8), larger],
                
                [WholeImpl(-1), WholeImpl(-1), equal],
                [WholeImpl(-1k), WholeImpl(-1k), equal],
                [WholeImpl(-1k), WholeImpl(-1k), equal],
                [WholeImpl(0), WholeImpl(-1), larger],
                [WholeImpl(-1), WholeImpl(-2), larger],
                [WholeImpl(-10M), WholeImpl(-100M), larger],
                [WholeImpl(-1), WholeImpl(0), smaller],
                [WholeImpl(-2), WholeImpl(-1), smaller],
                [WholeImpl(-20M), WholeImpl(-10M), smaller],
                [WholeImpl(-987654321), WholeImpl(-8765432100), larger],
                [WholeImpl(-(7^9)), WholeImpl(-(7^8)), smaller]
            ];
            
            (Comparison result, Comparison expected)
                    => expect(result, toBe(identicalTo(expected)))
        }
    };
    
    test shared Specification plusSpeck() => Specification {
        feature {
            description = "+ should work as in numbers";
            
            when(Whole w1, Whole w2, Whole expected)
                    => [w1 + w2, expected];
            
            examples = [
                // positive numbers
                [WholeImpl(0), WholeImpl(0), WholeImpl(0)],
                [WholeImpl(1), WholeImpl(0), WholeImpl(1)],
                [WholeImpl(0), WholeImpl(1), WholeImpl(1)],
                [WholeImpl(1), WholeImpl(1), WholeImpl(2)],
                [WholeImpl(2), WholeImpl(2), WholeImpl(4)],
                [WholeImpl(100), WholeImpl(0), WholeImpl(100)],
                [WholeImpl(100), WholeImpl(1), WholeImpl(101)],
                [WholeImpl(127), WholeImpl(1), WholeImpl(128)],
                [WholeImpl(1), WholeImpl(127), WholeImpl(128)],
                [WholeImpl(127), WholeImpl(127), WholeImpl(127 * 2)],
                [WholeImpl(1M), WholeImpl(1), WholeImpl(1M + 1)],
                [WholeImpl(1), WholeImpl(1M), WholeImpl(1M + 1)],
                // negative numbers
                [WholeImpl(-1), WholeImpl(0), WholeImpl(-1)],
                [WholeImpl(0), WholeImpl(-1), WholeImpl(-1)],
                [WholeImpl(-1), WholeImpl(-1), WholeImpl(-2)],
                [WholeImpl(-2), WholeImpl(-2), WholeImpl(-4)],
                [WholeImpl(-100), WholeImpl(0), WholeImpl(-100)],
                [WholeImpl(-100), WholeImpl(-1), WholeImpl(-101)],
                [WholeImpl(-127), WholeImpl(-1), WholeImpl(-128)],
                [WholeImpl(-1), WholeImpl(-127), WholeImpl(-128)],
                [WholeImpl(-127), WholeImpl(-127), WholeImpl(-127 * 2)],
                [WholeImpl(-1M), WholeImpl(-1), WholeImpl(-1M - 1)],
                [WholeImpl(-1), WholeImpl(-1M), WholeImpl(-1M - 1)],
                // positive and negative numbers
                [WholeImpl(-1), WholeImpl(1), WholeImpl(0)],
                [WholeImpl(1), WholeImpl(-1), WholeImpl(0)],
                [WholeImpl(-2), WholeImpl(2), WholeImpl(0)],
                [WholeImpl(-100), WholeImpl(0), WholeImpl(-100)],
                [WholeImpl(100), WholeImpl(-1), WholeImpl(99)],
                [WholeImpl(-127), WholeImpl(1), WholeImpl(-126)],
                [WholeImpl(1), WholeImpl(-128), WholeImpl(-127)],
                [WholeImpl(127), WholeImpl(-128), WholeImpl(-1)],
                [WholeImpl(1M), WholeImpl(-1), WholeImpl(1M - 1)],
                [WholeImpl(1), WholeImpl(-1M), WholeImpl(1 - 1M)]
            ];
            
            (Whole result , Whole expected)
                    => expect(result, toBe(equalTo(expected)))
        }
    };
    
    test shared Specification positiveSpeck() => Specification {
        feature {
            examples = [
                [0, false], [-1, false], [-128, false], [-127, false], [-1M, false],
                [1, true], [2, true], [127, true], [128, true], [1M, true]
            ];

            when(Integer n, Boolean expected) => [WholeImpl(n).positive, expected];
            
            (Boolean result, Boolean expected)
                    => expect(result, toBe(identicalTo(expected)))
        }
    };

    test shared Specification negativeSpeck() => Specification {
        feature {
            examples = [
                [0, false], [-1, true], [-128, true], [-127, true], [-1M, true],
                [1, false], [2, false], [127, false], [128, false], [1M, false]
            ];
            
            when(Integer n, Boolean expected) => [WholeImpl(n).negative, expected];
            
            (Boolean result, Boolean expected)
                    => expect(result, toBe(identicalTo(expected)))
        }
    };
    
    test shared Specification negateSpeck() => Specification {
        feature {
            examples = [
                [0, 0], [-1, 1], [-129, 129], [-128, 128], [-255, 255], [-256, 256], [-127, 127], [-1M, 1M],
                [1, -1], [2, -2], [127, -127], [128, -128], [255, -255], [256, -256], [257, -257], [1M, -1M]
            ];
            
            when(Integer n, Integer expected)
                    => [WholeImpl(n).negated, WholeImpl(expected)];
            
            (Whole result, Whole expected)
                    => expect(result, toBe(equalTo(expected)))
        }
    };
    
}