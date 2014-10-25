import ceylon.test {
    test,
    testExecutor
}

import com.athaydes.specks {
    Specification,
    generateIntegers,
    ExpectAll,
    SpecksTestExecutor,
    ExpectAllToThrow,
    generateStrings
}
import com.athaydes.specks.assertion {
    expect
}
import com.athaydes.specks.matcher {
    equalTo,
    toBe,
    be,
    to,
    smallerThan,
    largerThan,
    containSameAs
}

void run() {
    print(generatorOfIntegers().run());
}

Integer[] countEachUnique({Integer*} examples) => examples.collect((e1) => examples.count((e2) => e2 == e1));

Integer difference(Integer a, Integer b) {
    if (a > b) {
        return (a - b).magnitude;
    } else {
        return (b - a).magnitude;
    }
}

Integer average({Integer+} examples) {
    value examplesSeq = examples.sequence();
    assert(is [Integer+] examplesSeq);
    value result = sum(examplesSeq) / examplesSeq.size;
    return result;
}

T log<T>(T t) { print("Log: ``t else "null"``"); return t; }


testExecutor (`class SpecksTestExecutor`)
test
shared Specification generatorOfIntegers() => Specification {
    ExpectAll {
        "to generate integers array of expected size";
        examples = { [1], [3], [4], [5], [10], [100] };
        (Integer max) => expect(generateIntegers { count = max; }.size,
            toBe(equalTo(max)))
    },
    ExpectAll {
        "each array of integers should be unique";
        examples = { [2], [3], [4], [5], [10], [100] };
        (Integer max) => expect(
            countEachUnique(generateIntegers { count = max; })
            .select((count) => count > 1).empty,
            to(be(true)))
    },
    ExpectAll {
        "the average of the generated integers should be close to 0";
        examples = { [1], [2], [3], [5], [10], [100] };
        (Integer max) => expect(average(generateIntegers(max)),
            toBe(smallerThan(10), largerThan(-10)))
    },
    ExpectAll {
        "Generated integers to be sorted";
        examples = { generateIntegers().sequence() };
        (Integer* ints) => expect(sort(ints),
            to(containSameAs(ints)))
    },
    ExpectAll {
        "Generated integers to be within bounds";
        examples = { [0, 10], [-10, 10], [-105, 543] };
        function(Integer low, Integer high) {
            value ints = generateIntegers { count = 4; lowerBound = low; higherBound = high; };
            return expect(ints.first, toBe(equalTo(low)));
        },
        function(Integer low, Integer high) {
            value ints = generateIntegers { count = 4; lowerBound = low; higherBound = high; };
            return expect(ints.last, toBe(equalTo(high)));
        },
        function(Integer low, Integer high) {
            value ints = generateIntegers { count = 4; lowerBound = low; higherBound = high; };
            return expect(ints.count((it) => it > high), toBe(equalTo(0)));
        },
        function(Integer low, Integer high) {
            value ints = generateIntegers { count = 4; lowerBound = low; higherBound = high; };
            return expect(ints.count((it) => it < low), toBe(equalTo(0)));
        }
    },
    ExpectAllToThrow {
        `Exception`;
        "When generator is asked to create a non-positive number of examples";
        examples = { [0], [-1], [-2], [-50] };
        (Integer max) => generateIntegers { count = max; }.sequence()
    }
};

testExecutor (`class SpecksTestExecutor`)
test
shared Specification generatorOfStrings() => Specification {
    ExpectAll {
        "Generated Strings to be within size bounds";
        examples = { [0, 10], [1, 10], [105, 543] };
        (Integer low, Integer high) {
            value strings = generateStrings { shortest = low; longest = high; }.sequence();
            return expect(strings.every((String element) => low <= element.size <= high), to(be(true)));
        }
    }
};

