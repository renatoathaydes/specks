import ceylon.language.meta.model {
    MutationException
}
import ceylon.test {
    test,
    assertEquals,
    equalsCompare,
    assertTrue
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
    assert(flatten(specResult).every((result) => equalsCompare(result, success)));
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
        "Feature 'should fail with explanation message' failed: 3 is not larger than 4",
        "Feature 'should fail with explanation message' failed: 1 is not equal to 2",
        "Feature 'should fail with explanation message' failed: 10 is not smaller than 9",
        Exception().string,
        "Feature 'should fail with explanation message' failed: expected to exist but was null",
        "Feature 'should fail with explanation message' failed: expected true but was false"
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
        "Feature 'desc' failed: a is not larger than b [a, b]",
        "Feature 'desc' failed: c is not larger than d [c, d]",
        "Feature 'desc' failed: a is not equal to b [a, b]",
        "Feature 'desc' failed: c is not equal to d [c, d]",
        "success",
        Exception().string
    ]);
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
    assertEquals(errors[0], "ErrorCheck '``desc``' failed: expected ``platformIndependentName(`MutationException`)`` but threw ``Exception("Bad")`` [1, 2]");
    assertEquals(errors[1], "ErrorCheck '``desc``' failed: expected ``platformIndependentName(`MutationException`)`` but threw ``Exception("Bad")`` [3, 4]");
    assertEquals(errors[2], "ErrorCheck failed: no Exception thrown");
}

test shared void trivialForAllTestShouldSucceed() {
    {SpecResult*}[] specResult = Specification {
        forAll((String s) => expect(s.size, largerThan(-1)))
    }.run();
    
    assertEquals(specResult.size, 1);
    assert(exists firstResults = specResult.first);
    assertEquals(firstResults.sequence(), [success].cycled.take(100).sequence());
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

test shared void limitedCountPropertyChecksShouldSucceed() {
    value testSamples = 5;
    {SpecResult*}[] specResult = Specification {
        propertyCheck {
            description = "test1";
            testCount = testSamples;
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
            testCount = testSamples;
            when(String string) => [string.size];
            assertions = { (Integer len) => expect(len, largerThan(100M)) };
        }
    }.run();
    
    assertEquals(specResult.size, 1);
    assert(exists firstResults = specResult.first);
    assertTrue(firstResults.every((result) {
        assert(is String result);
        value pass = result.startsWith("Feature 'test1' failed: ") &&
                result.contains(" is not larger than ");
        if (!pass) {
            print("FAILED: ``result``");
        }
        return pass;
    }));
}
