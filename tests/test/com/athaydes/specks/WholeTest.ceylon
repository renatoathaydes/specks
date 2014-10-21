import ceylon.test {
    test,
    testExecutor
}

import com.athaydes.specks {
    SpecksTestExecutor,
    Specification,
    ExpectAll,
    binaryAdd
}

testExecutor(`class SpecksTestExecutor`)
class WholeTest() {
    
    test shared Specification binaryAddSpecification() => Specification {
        ExpectAll {
            "binary addition to be implemented correctly";
            [[0, 0], [1, 0], [0, 1], [100, 27]];
            (Integer a, Integer b) => equal -> { binaryAdd(Byte(a), Byte(b)).signed, a + b }
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