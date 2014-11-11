import ceylon.test {
    test,
    testExecutor
}

import com.athaydes.specks {
    SpecksTestExecutor,
    Specification,
    binaryAdd,
    toBinary,
    feature
}
import com.athaydes.specks.assertion {
    expect
}
import com.athaydes.specks.matcher {
    toBe,
    equalTo,
    to,
    containSameAs
}

testExecutor(`class SpecksTestExecutor`)
class WholeTest() {
    
    [Integer+] toIntArray([Byte+] bytes)
            => bytes.collect((byte) => byte.signed);
    
    test shared Specification toBinarySpeck() => Specification {
        feature {
            description = "toBinary must convert Integer to an array of Bytes in two's complement notation";
            
            when(Integer input, [Integer+] expected)
                    => [toBinary(input), expected];
            
            examples = {
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
            
            ([Byte+] result, [Integer+] expected)
                    => expect(toIntArray(result), to(containSameAs(expected)))
        }
    };
    
    test shared Specification binaryAddSpecification() => Specification {
        feature {
            description = "binary addition to be implemented correctly";
            examples = [[0, 0], [1, 0], [0, 1], [100, 27]];
            
            when(Integer a, Integer b)
                    => [a, b, binaryAdd(Byte(a), Byte(b)).signed];
            
            (Integer a, Integer b, Integer result)
                    => expect(result, toBe(equalTo(a + b)))
        }
    };
    
}