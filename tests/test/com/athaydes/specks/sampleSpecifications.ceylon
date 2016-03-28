import ceylon.test {
    test,
    testExecutor,
    ignore
}

import com.athaydes.specks {
    SpecksTestExecutor,
    Specification,
    expectations,
    feature,
    forAll,
    randomStrings,
    propertyCheck,
    unroll,
    randomIntegers
}
import com.athaydes.specks.assertion {
    expect
}
import com.athaydes.specks.matcher {
    equalTo,
    atMost,
    toBe,
    atLeast,
    largerThan
}


testExecutor (`class SpecksTestExecutor`)
shared class Samples() {

    test
    shared Specification simpleSpec() => Specification {
        expectations {
            expect(max { 1, 2, 3 }, equalTo(3))
        }
    };

    test
    shared Specification aGoodSpec() => Specification {
        feature {
            description = "The String.take() method returns at most n characters, for any given n >= 0";

            when(String sample, Integer n) => [sample.take(n), n];

            // just a few examples for brevity
            examples = {
                ["", 0],
                ["", 1],
                ["abc", 0],
                ["abc", 1],
                ["abc", 5],
                ["abc", 1k]
            };

            ({Character*} result, Integer n) => expect(result.size, toBe(atMost(n)))
        }
    };

    test
    shared Specification quickCheckStyleForAllSpec() => Specification {
        forAll((String sample, Integer n)
            => expect(sample.take(n).size, toBe(atMost(n < 0 then 0 else n))))
    };

    test
    shared Specification verySimpleForAllSpec() => Specification {
        forAll((String sample) => expect(sample.reversed.reversed, equalTo(sample)))
    };

    test
    shared Specification verboseForAllSpec() => Specification {
        forAll {
            description = "The reverse of a reversed String is the String itself";
            sampleCount = 1k;
            maxFailuresAllowed = 50;
            generators = [ randomStrings ];
            assertion(String sample) => expect(sample.reversed.reversed, equalTo(sample));
        }
    };

    test unroll
    shared Specification dividingANumberByASmallerNumberAlwaysGivesMoreThanOne()
            => Specification {
        forAll {
            description = "Any number divided by a smaller number always results in a number larger than one";
            sampleCount = 5;
            generators = [ () => randomIntegers { lowerBound = 1; higherBound = 1000M; } ];
            assertion(Integer a, Integer b) => expect((a + b).float / b, toBe(largerThan(1.0)));
        }
    };

    test
    shared Specification propertyCheckSpec() => Specification {
        propertyCheck {
            description = "The addition operation is commutative";
            sampleCount = 1k;
            when(Integer a, Integer b, Integer c) => [(a + b) + c, a + (b + c)];
            (Integer left, Integer right) => expect(left, equalTo(right))
        }
    };

    ignore test
    shared Specification failedSpec() => Specification {
        forAll((String s) => expect(s.size, atLeast(10)))
    };

    test unroll
    shared Specification customTypeGenerators() {
        class MyCustomType(shared String arg) {
            string = arg;
        }

        value infiniteStrings = { randomStrings() }.cycled.flatMap(identity).iterator();

        function generateRandomString() {
            value next = infiniteStrings.next();
            assert(is String next);
            return next;
        }

        function generateCustomType() => MyCustomType(generateRandomString());

        return Specification {
            forAll {
                sampleCount = 25;
                description = "Custom type arg size should be at least 0";
                generators = [ generateCustomType ];
                assertion(MyCustomType customType) => expect(customType.arg.size, atLeast(0));
            }
        };
    }

}
