import ceylon.collection {
    HashSet
}
import ceylon.language.meta.model {
    MutationException
}
import ceylon.logging {
    addLogWriter,
    Category,
    Priority
}
import ceylon.test {
    test,
    assertEquals,
    assertTrue,
    beforeTest
}

import com.athaydes.specks {
    Specification,
    SpecResult,
    success,
    feature,
    errorCheck,
    propertyCheck,
    forAll
}
import com.athaydes.specks.assertion {
    expect,
    expectToThrow,
    platformIndependentName,
    expectCondition
}
import com.athaydes.specks.matcher {
    ...
}


[SpecResult*] flatten({SpecResult*}[] specResult) =>
        [ for ({SpecResult*} res in specResult) for (SpecResult row in res) row ];

Boolean throwThis(Exception e) {
    throw e;
}

beforeTest
shared void setupLogging() {
    addLogWriter {
        void log(Priority prio, Category category, String message, Throwable? error) {
            //print("[``prio``] ``message``" + (if (exists error) then " - ``error``" else ""));
        }
    };
}

test shared void happySpecificationThatPassesAllTests() {
    {SpecResult*}[] specResult = Specification {
        feature {
            when(Integer a, Integer b, Integer expected)
                    => [a + b, b + a, expected];

            examples = { [2, 4, 6], [0, 0, 0], [-1, 0, -1] };

            (Integer r1, Integer r2, Integer expected)
                    => expect(r1, equalTo(expected)),
            (Integer r1, Integer r2, Integer expected)
                    => expect(r2, equalTo(expected))
        },
        feature {
            when() => [];
            () => expect(2 + 2, equalTo(4)),
            () => expect(3 + 2, equalTo(5)),
            () => expect(4 + 2, equalTo(6)),
            () => expect(null, not(to(exist)))
        },
        feature {
            examples = { [true, false], [false, true] };
            when(Boolean a, Boolean b) => [a || b];
            (Boolean orIsTrue) => expectCondition(orIsTrue),
            (Boolean orIsTrue) => expectCondition(orIsTrue != false)
        },
        errorCheck {
            description = "happy path";
            examples = {[1], [2]};
            when(Integer i) => throwThis(Exception("Bad"));
            expectToThrow(`Exception`)
        }
    }.run();

    print(specResult);
    assertEquals(specResult.size, 4);
    assertEquals(specResult.collect((results) => results.size), [6, 4, 4, 2]);
    flatten(specResult).each((result) => assertEquals(result, success));
}

String asString(SpecResult result) => result?.string else "success";

test shared void featuresShouldFailWithExplanationMessage() {
    Nothing error() {
        throw;
    }
    {SpecResult*}[] specResult = Specification {
        feature {
            description = "should fail with explanation message";
            when() => [];
            () => expect(2 + 1, largerThan(4)),
            () => expect(3 - 2, equalTo(2)),
            () => expect(5 + 5, smallerThan(9)),
            error,
            () => expect(null, exist),
            () => expect([1,2,3].contains(5), identicalTo(true))
        }
    }.run();

    assertEquals(flatten(specResult).map(asString).sequence(), [
        "\nFeature 'should fail with explanation message' failed: 3 is not larger than 4",
        "\nFeature 'should fail with explanation message' failed: 1 is not equal to 2",
        "\nFeature 'should fail with explanation message' failed: 10 is not smaller than 9",
        Exception().string,
        "\nFeature 'should fail with explanation message' failed: expected to exist but was null",
        "\nFeature 'should fail with explanation message' failed: expected true but was false"
    ]);
}

test shared void featuresShouldFailWithExplanationMessageForFailedExamples() {
    {SpecResult*}[] specResult = Specification {
        feature {
            description = "desc";
            examples = { ["a", "b"], ["c", "d"] };
            when(String s1, String s2) => [s1, s2];
            (String s1, String s2) => expect(s1, largerThan(s2)),
            (String s1, String s2) => expect(s1, equalTo(s2)),
            function(String s1, String s2) {
                if (s1 == "c") {
                    throw;
                }
                return expect(true, to(exist));
            }
        }
    }.run();

    assertEquals(flatten(specResult).map(asString).sequence(), [
        "\nFeature 'desc' failed: a is not larger than b [a, b]",
        "\nFeature 'desc' failed: a is not equal to b [a, b]",
        "success",
        "\nFeature 'desc' failed: c is not larger than d [c, d]",
        "\nFeature 'desc' failed: c is not equal to d [c, d]",
        Exception().string
    ]);
}

test shared void featuresShouldStopAfterFailingTooManyTimes() {
    {SpecResult*}[] specResult = Specification {
        feature {
            maxFailuresAllowed = 4;
            examples = (1..100).collect((i) => [i]);
            when(Integer i) => if (i > 10) then ["FAIL"] else [success];
            (String? result) => result
        }
    }.run();

    assertEquals(flatten(specResult).sequence(),
        (1..10).collect((i) => success).append([
            "\nFeature failed: FAIL [11]",
            "\nFeature failed: FAIL [12]",
            "\nFeature failed: FAIL [13]",
            "\nFeature failed: FAIL [14]"
        ]));
}

test shared void errorCheckShouldFailWithExplanationMessageForEachExample() {
    String desc = "throw this bad";
    {SpecResult*}[] specResult = Specification {
        errorCheck {
            description = desc;
            examples = { [1, 2], [3, 4] };
            when(Integer i, Integer j) => throwThis(Exception("Bad"));
            expectToThrow(`MutationException`)
        },
        errorCheck {
            void when() {}
            expectToThrow(`Exception`)
        }
    }.run();

    SpecResult[] errors = flatten(specResult);
    assertEquals(errors[0], "\nErrorCheck '``desc``' failed: expected ``platformIndependentName(`MutationException`)`` but threw ``Exception("Bad")`` [1, 2]");
    assertEquals(errors[1], "\nErrorCheck '``desc``' failed: expected ``platformIndependentName(`MutationException`)`` but threw ``Exception("Bad")`` [3, 4]");
    assertEquals(errors[2], "\nErrorCheck failed: no Exception thrown");
}

test shared void trivialForAllTestShouldSucceed() {
    {SpecResult*}[] specResult = Specification {
        forAll((String s) => expect(s.size, largerThan(-1))),
        forAll((String s, Integer i) => expect(s.size, largerThan(-1)))
    }.run();

    assertEquals(specResult.size, 2);
    assert(exists firstResults = specResult.first);
    assertEquals(firstResults.sequence(), [success].cycled.take(100).sequence());
    assert(exists secondResults = specResult.last);
    assertEquals(secondResults.sequence(), [success].cycled.take(100).sequence());
}

test shared void trivialPropertyChecksShouldSucceed() {
	{SpecResult*}[] specResult = Specification {
		propertyCheck(
			(String string) => [string.size],
			{ (Integer len) => expect(len, largerThan(-1)) })
	}.run();

	assertEquals(specResult.size, 1);
	assert(exists firstResults = specResult.first);
	assertEquals(firstResults.sequence(), [success].cycled.take(100).sequence());
}

test shared void iterablePropertyChecksShouldSucceed() {
    {SpecResult*}[] specResult = Specification {
        propertyCheck(
            ({String*} strings) => [strings.size],
            { (Integer len) => expect(len, atLeast(0)) })
    }.run();

    assertEquals(specResult.size, 1);
    assert(exists firstResults = specResult.first);
    assertEquals(firstResults.sequence(), [success].cycled.take(100).sequence());
}

test shared void limitedCountPropertyChecksShouldSucceed() {
    value testSamples = 5;
    {SpecResult*}[] specResult = Specification {
        propertyCheck {
            description = "test1";
            sampleCount = testSamples;
            when(String string) => [string.size];
            assertions = { (Integer len) => expect(len, largerThan(-1)) };
        }
    }.run();

    assertEquals(specResult.size, 1);
    assert(exists firstResults = specResult.first);
    assertEquals(firstResults.sequence(), [success].cycled.take(testSamples).sequence());
}

test shared void manyArgumentsPropertyChecksShouldSucceed() {
    print("Many Args test");
    {SpecResult*}[] specResult = Specification {
        propertyCheck(
            (String s, Integer i, String t) => [s, i, t],
            { (String s, Integer i, String t)
                => expectCondition(true),
              (String s, Integer i, String t)
                => expectCondition(true),
              (String s, Integer i, String t)
                => expectCondition(true) })
    }.run();

    assertEquals(specResult.size, 1);
    assert(exists firstResults = specResult[0]);
    assertEquals(firstResults.sequence(), [success].cycled.take(300).sequence());
}

test shared void limitedCountBadPropertyChecksShouldFail() {
    value testSamples = 5;
    {SpecResult*}[] specResult = Specification {
        propertyCheck {
            description = "test1";
            sampleCount = testSamples;
            when(String string) => [string.size];
            assertions = { (Integer len) => expect(len, largerThan(100M)) };
        }
    }.run();

    assertEquals(specResult.size, 1);
    assert(exists firstResults = specResult.first);
    assertTrue(firstResults.every((result) {
        assert(is String result);
        value pass = result.startsWith("\nFeature 'test1' failed: ") &&
                result.contains(" is not larger than ");
        if (!pass) {
            print("FAILED: ``result``");
        }
        return pass;
    }));
}

test shared void whenFunctionMustRunOnceForAllAssertions() {
    variable Integer counter = 0;

    function increment() => [counter++];

    {SpecResult*}[] specResult = Specification {
        feature {
            when = increment;
            (Integer count) => expect(count, equalTo(0)),
            (Integer count) => expect(count, equalTo(0)),
            (Integer count) => expect(count, equalTo(0)),
            (Integer count) => expect(count, equalTo(0))
        }
    }.run();

    assertEquals(flatten(specResult).map(asString).sequence(),
        ["success", "success", "success", "success"]);
}

test shared void allAssertionsMustRunForEachExampleInTurn() {
    {SpecResult*}[] specResult = Specification {
        feature {
            examples = [ [1], [2] ];
            when = function(Integer n) => [n];
            (Integer n) => expect(n, equalTo(n + 1)),
            (Integer n) => expect(n, largerThan(n + 1))
        }
    }.run();

    assertEquals(flatten(specResult).map(asString).sequence(),
        ["\nFeature failed: 1 is not equal to 2 [1]",
         "\nFeature failed: 1 is not larger than 2 [1]",
         "\nFeature failed: 2 is not equal to 3 [2]",
         "\nFeature failed: 2 is not larger than 3 [2]"]);
}

test shared void whenFunctionMustRunOnceForEachExampleForAllAssertions() {
    value seenNumbers = HashSet<Integer>();

    {SpecResult*}[] specResult = Specification {
        feature {
            examples = [ [1], [2] ];
            when = function(Integer n) {
                value newExample = seenNumbers.add(n);
                value newN = newExample then n + 1 else n;
                return [n, newN];
            };
            (Integer n, Integer newN) => expect(newN, equalTo(n + 1)),
            (Integer n, Integer newN) => expect(newN, equalTo(n + 1)),
            (Integer n, Integer newN) => expect(newN, equalTo(n + 1))
        }
    }.run();

    assertEquals(flatten(specResult).map(asString).sequence(),
        ["success", "success", "success",
         "success", "success", "success"]);
}

