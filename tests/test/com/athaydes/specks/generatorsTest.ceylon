import ceylon.test {
    test,
    testExecutor
}

import com.athaydes.specks {
    Specification,
    generateIntegers,
    ExpectAll,
    SpecksTestExecutor,
    ExpectAllToThrow
}

void run() {
    print(generatorOfIntegers().run());
}


Integer[] countEachUnique({Integer*} examples) => examples.collect((Integer e1) => examples.count((Integer e2) => e2 == e1));

Integer average({Integer+} examples) => sum(examples) / examples.size;

testExecutor(`class SpecksTestExecutor`)
test shared Specification generatorOfIntegers() =>
    Specification {
        ExpectAll {
            "Should generate integers array of expected size, each array should be unique,
             and the average of the generated integers should be close to 0";
            examples = { [1], [3], [4], [10], [100] };
            (Integer max) => generateIntegers{ count = max; }.size == max,
            (Integer max) => countEachUnique(generateIntegers{ count = max; }).select((Integer count) => count > 1).empty,
            (Integer max) => -10 < average(generateIntegers(max)) < 10
        },
        ExpectAll {
            "Generated integers to be sorted";
            examples = { generateIntegers().sequence() };
            (Integer* ints) => sort(ints) == ints
        },
        ExpectAllToThrow {
            `Exception`;
            "When generator is asked to create a non-positive number of examples";
            examples = { [0], [-1], [-2], [-50] };
            (Integer max) => generateIntegers { count = max; }.sequence
        }
    };
