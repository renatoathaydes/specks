import ceylon.language.meta.model {
    MutationException
}
import ceylon.test {
    test,
    assertEquals,
    equalsCompare
}

import com.athaydes.specks {
    Specification,
    SpecResult,
    success,
    feature,
    errorCheck
}
import com.athaydes.specks.assertion {
    expect,
    AssertionResult,
    expectToThrow,
    platformIndependentName
}
import com.athaydes.specks.matcher {
    ...
}


[SpecResult*] flatten({{SpecResult*}*}[] specResult) =>
        [ for (res in specResult) for (row in res) for (col in row) col ];

Boolean throwThis(Exception e) {
    throw e;
}

test shared void happySpecificationThatPassesAllTests() {
    value specResult = Specification {
        feature {
            examples = { [2, 4, 6], [0, 0, 0], [-1, 0, -1] };

            when(Integer a, Integer b, Integer expected)
                    => [a + b, b + a, expected];

            (Integer r1, Integer r2, Integer expected)
                    => expect(r1, toBe(equalTo(r2), equalTo(expected)))
        },
        feature {
            when() => [];
            () => expect(2 + 2, equalTo(4)),
            () => expect(3 + 2, equalTo(5)),
            () => expect(4 + 2, equalTo(6)),
            () => expect(null, not(to(exist)))
        },
        errorCheck {
            description = "happy path";
            examples = {[1], [2]};
            when(Integer i) => throwThis(Exception("Bad"));
            expectToThrow(`Exception`)
        }
    }.run();
    assertEquals(specResult.size, 3);
    assertEquals(specResult.collect(({{SpecResult*}*} element) => element.size), [1, 4, 1]);

    assert(flatten(specResult).every((SpecResult result) => equalsCompare(result, success)));
}

String asString(SpecResult result) => result?.string else "success";

test shared void featuresShouldFailWithExplanationMessage() {
    AssertionResult error() {
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
            () => expect([1,2,3].contains(5), toBe(identicalTo(true)))
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
    
    value errors = flatten(specResult);
    assertEquals(errors[0], "ErrorCheck '``desc``' failed: expected ``platformIndependentName(`MutationException`)`` but threw ``Exception("Bad")`` [1, 2]");
    assertEquals(errors[1], "ErrorCheck '``desc``' failed: expected ``platformIndependentName(`MutationException`)`` but threw ``Exception("Bad")`` [3, 4]");
    assertEquals(errors[2], "ErrorCheck failed: no Exception thrown");
}
