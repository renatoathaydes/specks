import ceylon.collection {
    HashSet
}
import ceylon.language.meta.model {
    MutationException
}
import ceylon.logging {
    addLogWriter,
    Category,
    Priority,
    logger,
    trace
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
    errorCheck,
    forAll,
    propertyCheck,
    SpecResult
}
import com.athaydes.specks.assertion {
    expect,
    expectCondition,
    expectToThrow,
    platformIndependentName,
    AssertionFailure
}
import com.athaydes.specks.matcher {
    ...
}


Boolean throwThis(Exception e) {
    throw e;
}

<Anything[]-><SpecCaseResult>[]>[] specResultAt(SpecResult specResult)(Integer index) =>
        if (exists results = specResult[index]?.sequence()) then
            results.collect((entry) => entry.key[0] -> entry.item().sequence())
        else [];


variable Boolean addedLog = false;
beforeTest
shared void setupLogging() {
    if (addedLog) {
        return;
    }
    addedLog = true;
    value start = system.milliseconds;
    addLogWriter {
        void log(Priority prio, Category category, String message, Throwable? error) {
            if (process.propertyValue("ceylon.logging") exists) {
                // only log things if the system property is specified...
                // TODO accept log levels?
                print("``system.milliseconds - start``: [``prio``] ``message``" +
                    (if (exists error) then " - ``error``" else ""));
            }
        }
    };
    logger(`module com.athaydes.specks`).priority =
    //         warn;
     trace;
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
        },
        errorCheck {
            description = "Exception subtypes are acceptable";
            when() => 1 / 0;
            expectToThrow(`Exception`)
        }
    }.run();

    value specResultAtIndex = specResultAt(specResult);

    assertEquals(specResult.size, 5); // number of blocks

    assertEquals(specResultAtIndex(0), [
        [2, 4, 6] -> [success, success],
        [0, 0, 0] -> [success, success],
        [-1, 0, -1] -> [success, success]]);

    assertEquals(specResultAtIndex(1), [[] -> [success, success, success, success]]);

    assertEquals(specResultAtIndex(2), [
        [true, false] -> [success, success],
        [false, true] -> [success, success]]);

    assertEquals(specResultAtIndex(3), [
        [1] -> [success],
        [2] -> [success]]);

    assertEquals(specResultAtIndex(4), [
        [] -> [success]]);
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
        },
        errorCheck {
            description = "No throws when an error is expected";
            when() => [];
            expectToThrow(`Exception`)
        },
        errorCheck {
            description = "Non-subtypes are NOT acceptable";
            when() => throwThis(Exception("Bad"));
            expectToThrow(`MutationException`)
        }
    }.run();

    value specResultAtIndex = specResultAt(specResult);

    assertEquals(specResult.size, 3);

    value firstResults = specResultAtIndex(0);

    assertEquals(firstResults.size, 1);
    assertEquals(firstResults[0]?.key, []);

    assert(exists results = firstResults[0]?.item);

    assertEquals(results[0], "\nFeature 'should fail with explanation message' failed: 3 is not larger than 4");
    assertEquals(results[1], "\nFeature 'should fail with explanation message' failed: 1 is not equal to 2");
    assertEquals(results[2], "\nFeature 'should fail with explanation message' failed: 10 is not smaller than 9");
    assert(exists r3 = results[3], r3 is Exception);
    assertEquals(results[4], "\nFeature 'should fail with explanation message' failed: expected to exist but was null");
    assertEquals(results[5], "\nFeature 'should fail with explanation message' failed: expected true but was false");

    assertEquals(results.size, 6);

    value errorCheckResults = specResultAtIndex(1);

    assertEquals(errorCheckResults.size, 1);
    assertEquals(errorCheckResults[0]?.key, []);

    assert(exists results2 = errorCheckResults[0]?.item);
    assertEquals(results2[0], "\nErrorCheck 'No throws when an error is expected' failed: no Exception thrown");
    assertEquals(results2.size, 1);

    value errorCheckResults2 = specResultAtIndex(2);

    assertEquals(errorCheckResults2.size, 1);
    assertEquals(errorCheckResults2[0]?.key, []);

    assert(exists results3 = errorCheckResults2[0]?.item);
    assertEquals(results3[0], "\nErrorCheck 'Non-subtypes are NOT acceptable' failed: \
                               expected ceylon.language.meta.model.MutationException \
                               but threw ceylon.language.Exception \"Bad\"");

    assertEquals(results3.size, 1);
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

    assert(exists results = specResult[0]?.sequence());
    assertEquals(results.size, 2);
    assert(exists [[example1, description1], resultsGetter1] = results[0]?.pair);

    value results1 = resultsGetter1().sequence();
    assertEquals(results1.size, 3);

    assertEquals(results1[0], "\nFeature 'desc' failed: a is not larger than b [a, b]");
    assertEquals(results1[1], "\nFeature 'desc' failed: a is not equal to b [a, b]");
    assertEquals(results1[2], success);

    assertEquals(example1, ["a", "b"]);

    assert(exists [[example2, description2], resultsGetter2] = results[1]?.pair);

    value results2 = resultsGetter2().sequence();

    assertEquals(results2.size, 3);

    assertEquals(results2[0], "\nFeature 'desc' failed: c is not larger than d [c, d]");
    assertEquals(results2[1], "\nFeature 'desc' failed: c is not equal to d [c, d]");
    assert(exists sr2 = results2[2], sr2 is Exception);

    assertEquals(example2, ["c", "d"]);

    assertEquals(description1, "Feature 'desc'");
    assertEquals(description2, "Feature 'desc'");
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

    value firstResults = specResultAt(specResult)(0);

    value examples = firstResults*.key;
    value results = firstResults*.item;

    assertEquals(examples, (1..100).collect((i) => [i]));
    assertEquals(results[0..9], [[success]].cycled.take(10).sequence());
    assertEquals(results[10..13], [
        ["\nFeature failed: FAIL [11]"],
        ["\nFeature failed: FAIL [12]"],
        ["\nFeature failed: FAIL [13]"],
        ["\nFeature failed: FAIL [14]"]
    ]);
    assertEquals(results[14..99], [[]].cycled.take(100 - 14).sequence());
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

    value firstResults = specResultAt(specResult)(0);
    value secondResults = specResultAt(specResult)(1);

    assertEquals(firstResults.size, 2);
    assertEquals(firstResults[0], [1, 2] -> [
        "\nErrorCheck '``desc``' failed: expected ``platformIndependentName(`MutationException`)`` but threw ``Exception("Bad")`` [1, 2]"
    ]);
    assertEquals(firstResults[1], [3, 4] -> [
        "\nErrorCheck '``desc``' failed: expected ``platformIndependentName(`MutationException`)`` but threw ``Exception("Bad")`` [3, 4]"
    ]);

    assertEquals(secondResults.size, 1);
    assertEquals(secondResults[0], [] -> ["\nErrorCheck failed: no Exception thrown"]);
}

test shared void trivialForAllTestShouldSucceed() {
    value specResult = Specification {
        forAll((String s) => expect(s.size, largerThan(-1))),
        forAll((String s, Integer i) => expect(s.size, largerThan(-1)))
    }.run();

    assertEquals(specResult.size, 2);

    value firstResult = specResultAt(specResult)(0);
    value secondResult = specResultAt(specResult)(1);

    assertEquals(expect(set(firstResult*.key).size, toBe(atLeast(90))), success);
    assertEquals(firstResult*.item, [[success]].cycled.take(100).sequence());

    assertEquals(expect(set(secondResult*.key).size, toBe(atLeast(90))), success);
    assertEquals(secondResult*.item, [[success]].cycled.take(100).sequence());
}

test shared void trivialPropertyChecksShouldSucceed() {
	value specResult = Specification {
		propertyCheck(
			(String string) => [string.size],
			{ (Integer len) => expect(len, largerThan(-1)) })
	}.run();

	assertEquals(specResult.size, 1);
	value firstResult = specResultAt(specResult)(0);
	assertEquals(expect(set(firstResult*.key).size, toBe(atLeast(90))), success);
	assertEquals(firstResult*.item, [[success]].cycled.take(100).sequence());
}

test shared void iterablePropertyChecksShouldSucceed() {
    value specResult = Specification {
        propertyCheck(
            ({String*} strings) => [strings.size],
            { (Integer len) => expect(len, atLeast(0)) })
    }.run();

    assertEquals(specResult.size, 1);
    value firstResult = specResultAt(specResult)(0);
    assertEquals(firstResult*.item, [[success]].cycled.take(100).sequence());
}

test shared void limitedCountPropertyChecksShouldSucceed() {
    value testSamples = 5;
    value specResult = Specification {
        propertyCheck {
            description = "test1";
            sampleCount = testSamples;
            when(String string) => [string.size];
            assertions = {
                (Integer len) => expect(len, largerThan(-1)),
                (Integer len) => expect(len, atLeast(0)),
                (Integer len) => expect(len, atLeast(0))
            };
        }
    }.run();

    assertEquals(specResult.size, 1);
    value firstResult = specResultAt(specResult)(0);
    assertEquals(firstResult*.item, [[success, success, success]].cycled.take(testSamples).sequence());
}

test shared void manyArgumentsPropertyChecksShouldSucceed() {
    value specResult = Specification {
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
    value firstResult = specResultAt(specResult)(0);
    assertEquals(expect(set(firstResult*.key).size, toBe(atLeast(90))), success);
    assertEquals(firstResult*.item, [[success, success, success]].cycled.take(100).sequence());
}

test shared void limitedCountBadPropertyChecksShouldFail() {
    value testSamples = 5;
    value specResult = Specification {
        propertyCheck {
            description = "test1";
            sampleCount = testSamples;
            when(String string) => [string.size];
            assertions = { (Integer len) => expect(len, largerThan(100M)) };
        }
    }.run();

    assertEquals(specResult.size, 1);
    value firstResult = specResultAt(specResult)(0);

    assertEquals(firstResult.size, testSamples);

    for (exampleResults in firstResult) {
        value [example, results]= exampleResults.pair;
        assertEquals(results.size, 1);
        assert(is AssertionFailure assertionResult = results[0]);
        assertEquals(expect(assertionResult, to(containSubsection(* " is not larger than ``100M``"))), success);
    }
}

test shared void whenFunctionMustRunOnceForAllAssertions() {
    variable Integer counter = 0;

    function increment() => [counter++];

    value specResult = Specification {
        feature {
            when = increment;
            (Integer count) => expect(count, equalTo(0)),
            (Integer count) => expect(count, equalTo(0)),
            (Integer count) => expect(count, equalTo(0)),
            (Integer count) => expect(count, equalTo(0))
        }
    }.run();

    assertEquals(specResult.size, 1);
    value firstResult = specResultAt(specResult)(0);
    assertEquals(firstResult*.item, [[success, success, success, success]]);
}

test shared void whenFunctionMustRunOnceForEachExampleForAllAssertions() {
    value seenNumbers = HashSet<Integer>();

    value specResult = Specification {
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

    assertEquals(specResult.size, 1);
    value firstResult = specResultAt(specResult)(0);

    assertEquals(firstResult, [
        [1] -> [success, success, success],
        [2] -> [success, success, success]]);
}

