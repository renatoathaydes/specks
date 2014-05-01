import ceylon.test {
    test
}

import com.athaydes.specks {
    Specification,
    generateIntegers,
    ExpectAll,
    Success
}

void run() {
    generatorOfIntegers();
}


Integer[] countEachUnique({Integer*} examples) => examples.collect((Integer e1) => examples.count((Integer e2) => e2 == e1));

Integer average({Integer+} examples) => sum(examples) / examples.size;

test shared void generatorOfIntegers() {
    value result = Specification {
        "Should generate integers spanning nearly the whole range of Integers in Ceylon (limited by JS)";
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

    }.run();
    print(result);
    assert(flatten(result).every((Anything result) => result is Success));
}
