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
    beforeTest
}

import com.athaydes.specks {
    Specification,
    SpecCaseResult,
    success,
    feature,
    BlockResult,
    errorCheck,
    SpecCaseSuccess
}
import com.athaydes.specks.assertion {
    expect,
    expectCondition,
    expectToThrow,
    platformIndependentName
}
import com.athaydes.specks.matcher {
    ...
}


[SpecCaseResult*] flatten({SpecCaseResult*}[] specResult) =>
        [ for ({SpecCaseResult*} res in specResult) for (SpecCaseResult row in res) row ];

Boolean throwThis(Exception e) {
    throw e;
}

beforeTest
shared void setupLogging() {
    addLogWriter {
        void log(Priority prio, Category category, String message, Throwable? error) {
            print("[``prio``] ``message``" + (if (exists error) then " - ``error``" else ""));
        }
    };
}

test shared void happySpecificationThatPassesAllTests() {
    value specResult = Specification {
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

    assertEquals(specResult.size, 4); // number of blocks

    assert(exists firstBlockResult = specResult[0]?.sequence());
    assertEquals(firstBlockResult, [
        [success, success], // first example
        [success, success], // second example
        [success, success]  // third example
    ]);

    assert(exists secondBlockResult = specResult[1]?.sequence());
    assertEquals(secondBlockResult, [
        [success, success, success, success]
    ]);

    assert(exists thirdBlockResult = specResult[2]?.sequence());
    assertEquals(thirdBlockResult, [
        [success, success], // first example
        [success, success]  // second example
    ]);

    assert(exists fourthBlockResult = specResult[3]?.sequence());
    assertEquals(fourthBlockResult, [
        [success], // first example
        [success]  // second example
    ]);
}

test shared void featuresShouldFailWithExplanationMessage() {
    Nothing error() {
        throw;
    }

    value specResult = Specification {
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

    assertEquals(specResult.size, 1);

    assert(exists firstResult = specResult[0]?.sequence());
    assertEquals(firstResult.size, 1);
    assert(exists results = firstResult[0]);
    assertEquals(results.size, 6);

    assertEquals(results[0], "\nFeature 'should fail with explanation message' failed: 3 is not larger than 4");
    assertEquals(results[1], "\nFeature 'should fail with explanation message' failed: 1 is not equal to 2");
    assertEquals(results[2], "\nFeature 'should fail with explanation message' failed: 10 is not smaller than 9");
    assert(exists r3 =results[3], r3 is Exception);
    assertEquals(results[4], "\nFeature 'should fail with explanation message' failed: expected to exist but was null");
    assertEquals(results[5], "\nFeature 'should fail with explanation message' failed: expected true but was false");
}

test shared void featuresShouldFailWithExplanationMessageForFailedExamples() {
    value specResult = Specification {
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

    assertEquals(specResult.size, 1);

    assert(exists firstResult = specResult[0]?.sequence());
    assertEquals(firstResult.size, 2);

    assert(exists firstResults = firstResult[0]);
    assertEquals(firstResults.size, 3);

    assertEquals(firstResults[0], "\nFeature 'desc' failed: a is not larger than b [a, b]");
    assertEquals(firstResults[1], "\nFeature 'desc' failed: a is not equal to b [a, b]");
    assertEquals(firstResults[2], success);

    assert(exists secondResults = firstResult[1]);
    assertEquals(secondResults.size, 3);

    assertEquals(secondResults[0], "\nFeature 'desc' failed: c is not larger than d [c, d]");
    assertEquals(secondResults[1], "\nFeature 'desc' failed: c is not equal to d [c, d]");
    assert(exists sr2 = secondResults[2], sr2 is Exception);
}

test shared void featuresShouldStopAfterFailingTooManyTimes() {
    value specResult = Specification {
        feature {
            maxFailuresAllowed = 4;
            examples = (1..100).collect((i) => [i]);
            when(Integer i) => if (i > 10) then ["FAIL"] else [success];
            (String? result) => result
        }
    }.run();

    assertEquals(specResult.size, 1);

    assert(exists firstResult = specResult[0]?.sequence());

    function successCases(SpecCaseResult[] results)
            => results.every((result) => result is SpecCaseSuccess);

    assert(firstResult.take(10).every(successCases));

    function singleFailure(Integer -> SpecCaseResult[] entry) {
        value index = entry.key;
        value results = entry.item;
        assertEquals(results.size, 1);
        assertEquals(results.first, "\nFeature failed: FAIL [``index + 11``]");
        return true;
    }

    assert(firstResult.skip(10).take(4).indexed.every(singleFailure));

    assertEquals(firstResult.size, 14);
}

test shared void errorCheckShouldFailWithExplanationMessageForEachExample() {
    String desc = "throw this bad";
    value specResult = Specification {
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

    assertEquals(specResult.size, 2);

    assert(exists firstResult = specResult[0]?.sequence());
    assertEquals(firstResult.size, 2);
    assertEquals(firstResult[0], ["\nErrorCheck '``desc``' failed: expected ``platformIndependentName(`MutationException`)`` but threw ``Exception("Bad")`` [1, 2]"]);
    assertEquals(firstResult[1], ["\nErrorCheck '``desc``' failed: expected ``platformIndependentName(`MutationException`)`` but threw ``Exception("Bad")`` [3, 4]"]);

    assert(exists secondResult = specResult[1]?.sequence());
    assertEquals(secondResult.size, 1);
    assertEquals(secondResult[0], ["\nErrorCheck failed: no Exception thrown"]);
}
/*
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
    value specResult = Specification {
        feature {
            examples = [ [1], [2] ];
            when = function(Integer n) => [n];
            (Integer n) => expect(n, equalTo(n + 1)),
            (Integer n) => expect(n, largerThan(n + 1))
        }
    }.collectRunnables();

    specResult.each(void ({SpecResult*}() element) {
        print("Result: ``element()``");
    });

    //assertEquals(flatten(specResult).map(asString).sequence(),
    //    ["\nFeature failed: 1 is not equal to 2 [1]",
    //     "\nFeature failed: 1 is not larger than 2 [1]",
    //     "\nFeature failed: 2 is not equal to 3 [2]",
    //     "\nFeature failed: 2 is not larger than 3 [2]"]);
}
*/
test shared void whenFunctionMustRunOnceForEachExampleForAllAssertions() {
    value seenNumbers = HashSet<Integer>();

    BlockResult[] specResults = Specification {
        feature {
            examples = [ [1], [2] ];
            when = function(Integer n) {
                value newExample = seenNumbers.add(n);
                value newN = newExample then n + 1 else n;
                return [n, newN]; // if n was already seen, this would return [n, n]
            };
            (Integer n, Integer newN) => expect(newN, equalTo(n + 1)),
            (Integer n, Integer newN) => expect(newN, equalTo(n + 1)),
            (Integer n, Integer newN) => expect(newN, equalTo(n + 1))
        }
    }.run();

    assertEquals(1, specResults.size);

    assert(exists featureResult = specResults[0]?.sequence());

    assertEquals(featureResult, [
        [success, success, success], // first example
        [success, success, success]  // second example
    ]);
}

