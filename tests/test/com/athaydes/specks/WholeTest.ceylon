import ceylon.test {
    test,
    testExecutor
}

import com.athaydes.specks {
    SpecksTestExecutor,
    Specification,
    ExpectAll,
    binaryAdd,
    toBinary
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
        ExpectAll {
            "toBinary must convert Integer to an array of Bytes in two's complement notation";
            examples = {
                [-1, toIntArray([Byte(#FF)])],
                [0, toIntArray([Byte(0)])],
                [1, toIntArray([Byte(1)])],
                [126, toIntArray([Byte(126)])]
            };
            
            (Integer input, [Integer+] expected)
                    => expect(toIntArray(toBinary(input)), to(containSameAs(expected)))
        }
    };
    
    test shared Specification binaryAddSpecification() => Specification {
        ExpectAll {
            "binary addition to be implemented correctly";
            [[0, 0], [1, 0], [0, 1], [100, 27]];
            (Integer a, Integer b)
                    => expect(binaryAdd(Byte(a), Byte(b)).signed, toBe(equalTo(a + b)))
        }
    };
    /*
    test shared Specification binaryCreationSpeck() => Specification {
        ExpectAll {
            "binary numbers can be created from Integers";
            [[0], [1], [100]];
            (Integer a) => equal -> { binaryToInteger(toBinary(a)), a }
        }
    };
    
    
    test shared Specification createBytesFromUnsignedInteger() => Specification {
        ExpectAll {
            "toBinary to return the appropriate Byte array";
            [[0, [Byte(0)]],
             [1, [Byte(1)]],
             [12, [Byte(12)]],
             [#FF, [Byte(#FF)]],
             [#FF1, [Byte(#FF), Byte(1)]],
             [#FA02E3F4, [Byte(#FA), Byte(#02), Byte(#E3), Byte(#F4)]]];
            
            (Integer int, [Byte+] bytes) => equal ->
                { toBinary(int).collect((b) => b.unsigned), bytes.collect((b) => b.unsigned) }
        }
        
    };
     */
}