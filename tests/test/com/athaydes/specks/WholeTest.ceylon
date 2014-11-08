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
                    => [toIntArray(toBinary(input)), expected];
            
            examples = {
                [-1, toIntArray([Byte(#FF)])],
                [0, toIntArray([Byte(0)])],
                [1, toIntArray([Byte(1)])],
                [126, toIntArray([Byte(126)])]
            };
            
            ([Integer+] result, [Integer+] expected)
                    => expect(result, to(containSameAs(expected)))
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