import ceylon.test {
    test,
    testExecutor
}

import com.athaydes.specks {
    Specification,
    rangeOfIntegers,
    randomStrings,
    SpecksTestExecutor,
    feature,
    errorCheck,
    Block,
    randomIntegers
}
import com.athaydes.specks.assertion {
    expect,
    expectToThrow,
    expectCondition
}
import com.athaydes.specks.matcher {
    equalTo,
    toBe,
    to,
    smallerThan,
    largerThan,
    containSameAs,
    containOnly
}

void run() {
    print(rangeOfIntegersSpecification().run());
}

Integer[] countItemsAppearances({Object*} examples)
        => examples.collect((e1) => examples.count((e2) => e2 == e1));

Integer average({Integer+} examples) {
    value examplesSeq = examples.sequence();
    assert(is [Integer+] examplesSeq);
    value result = sum(examplesSeq) / examplesSeq.size;
    return result;
}

Block generatesUniqueElementsFeature(String desc, {Object*}(Integer) generator)
        => feature {
        description = desc;
        examples = { [10], [13], [33], [100] };
        when(Integer max) => generator(max).sequence();
        (Object* items) => expect(countItemsAppearances(items), to(containOnly(1)))
    };

Block throwsExceptionWhenAskedToGenerateNegativeNumberOfExamples({Object*}(Integer) generator)
        => errorCheck {
        description = "error when the generator is asked to create a non-positive number of examples";
        examples = { [0], [-1], [-2], [-50] };
        when(Integer max) => generator(max).sequence();
        expectToThrow(`Exception`)
    };

testExecutor (`class SpecksTestExecutor`)
test
shared Specification rangeOfIntegersSpecification() => Specification {
    feature {
        description = "generated integer arrays are of expected size";
        examples = { [1], [3], [4], [5], [10], [100] };
        when(Integer max) => [max, rangeOfIntegers { count = max; }.size];
        (Integer max, Integer size) => expect(size, toBe(equalTo(max)))
    },
    generatesUniqueElementsFeature (
        "each array of integers should be unique",
        rangeOfIntegers
    ),
    feature {
        description = "the average of the generated integers should be close to 0";
        examples = { [1], [2], [3], [5], [10], [100] };
        (Integer max) => [average(rangeOfIntegers(max))];
        (Integer average) => expect(average, toBe(
            smallerThan(10), 
            largerThan(-10)))
    },
    feature {
        description = "generated integers must be sorted";
        examples = { rangeOfIntegers(10).sequence(), rangeOfIntegers(1k, -1k, 1k).sequence() };
        when(Integer* ints) => [ints, sort(ints)];
        ({Integer*} ints, {Integer*} sortedInts) => expect(ints, 
            to(containSameAs(sortedInts)))
    },
    feature {
        description = "generated integers to be within bounds";
        examples = { [0, 10], [-10, 10], [-105, 543] };
        when(Integer low, Integer high)
                => [rangeOfIntegers { count = 4; lowerBound = low; higherBound = high; }, low, high];
        // expectations
        ({Integer+} ints, Integer low, Integer high)
                => expect(ints.first, toBe(equalTo(low))),
        ({Integer+} ints, Integer low, Integer high)
                => expect(ints.last, toBe(equalTo(high))),
        ({Integer+} ints, Integer low, Integer high)
                => expect(ints.count((it) => it > high), toBe(equalTo(0))),
        ({Integer+} ints, Integer low, Integer high)
                => expect(ints.count((it) => it < low), toBe(equalTo(0)))
    },
    throwsExceptionWhenAskedToGenerateNegativeNumberOfExamples(rangeOfIntegers)
};

testExecutor (`class SpecksTestExecutor`)
test
shared Specification randomIntegersSpecification() => Specification {
    feature {
        description = "generated integer arrays are of expected size";
        examples = { [1], [3], [4], [5], [10], [100] };
        when(Integer max) => [max, randomIntegers { count = max; }.size];
        (Integer max, Integer size) => expect(size, toBe(equalTo(max)))
    },
    generatesUniqueElementsFeature (
        "each array of integers should be unique",
        randomIntegers
    ),
    feature {
        description = "the average of the generated integers should be close to 0";
        examples = { [100k] };
        (Integer max) => [average(randomIntegers { count = max; lowerBound = -100; higherBound = 100; })];
        (Integer average) => expect(average, toBe(
            smallerThan(10),
            largerThan(-10)))
    },
    feature {
        description = "generated integers to be within bounds";
        examples = { [0, 10], [-10, 10], [-105, 543] };
        when(Integer low, Integer high)
                => [randomIntegers { lowerBound = low; higherBound = high; }, low, high];
        // expectations
        ({Integer+} ints, Integer low, Integer high)
                => expect(ints.count((it) => it > high), toBe(equalTo(0))),
        ({Integer+} ints, Integer low, Integer high)
                => expect(ints.count((it) => it < low), toBe(equalTo(0)))
    },
    throwsExceptionWhenAskedToGenerateNegativeNumberOfExamples(randomIntegers)
};


testExecutor (`class SpecksTestExecutor`)
test
shared Specification randomStringsSpecification() => Specification {
    feature {
        description = "Generated Strings to be within size bounds";
        examples = { [0, 10], [1, 10], [105, 543], [21, 21] };
        when(Integer low, Integer high)
                => [randomStrings { shortest = low; longest = high; }.sequence(), low, high];
        
        ({String*} strings, Integer low, Integer high)
                => expectCondition(strings.every((element) => low <= element.size <= high))
    },
    generatesUniqueElementsFeature (
        "each element in the array of Strings generated should be unique",
        (Integer max) => randomStrings { count = max; shortest = 5; }
    ),
    throwsExceptionWhenAskedToGenerateNegativeNumberOfExamples(randomStrings)
};
