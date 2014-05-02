import ceylon.test {
    test,
    testExecutor
}

import com.athaydes.specks {
    Specification,
    generateIntegers,
    ExpectAll,
    SpecksTestExecutor
}

void run() {
    generatorOfIntegers();
}


Integer[] countEachUnique({Integer*} examples) => examples.collect((Integer e1) => examples.count((Integer e2) => e2 == e1));

Integer average({Integer+} examples) => sum(examples) / examples.size;

testExecutor(`class SpecksTestExecutor`)
test shared Specification generatorOfIntegers() =>
    Specification {
        ExpectAll {
            examples = { [1], [2], [3], [10], [1_000] };
            (Integer max) => generateIntegers{ count = max; }.size == max,
            (Integer max) => countEachUnique(generateIntegers{ count = max; }).filter((Integer count) => count > 1).empty,
            (Integer max) => -10 < average(generateIntegers(max)) < 10
        },
        ExpectAll {
            examples = { generateIntegers().sequence };
            (Integer* ints) => sort(ints) == ints
        }
    };
