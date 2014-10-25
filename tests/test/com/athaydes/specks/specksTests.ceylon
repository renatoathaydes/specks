import ceylon.language.meta.model {
    MutationException
}
import ceylon.test {
    test,
    assertEquals,
    equalsCompare
}

import com.athaydes.specks {
    ExpectToThrow,
    ExpectAll,
    Specification,
    SpecResult,
    ExpectAllToThrow,
    success
}
import com.athaydes.specks.assertion {
    expect,
    AssertionResult
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
        ExpectAll {
            examples = { [2, 4, 6], [0, 0, 0], [-1, 0, -1] };
            (Integer a, Integer b, Integer c) => expect(a + b, equalTo(c)),
            (Integer a, Integer b, Integer c) => expect(b + a, equalTo(c))
        },
        ExpectAll {
            assertions = {
                () => expect(2 + 2, equalTo(4)),
                () => expect(3 + 2, equalTo(5)),
                () => expect(4 + 2, equalTo(6)),
                () => expect(null, not(to(exist)))
            };
        },
        ExpectToThrow {
            `Exception`;
            "when throwing this exception";
            () => throwThis(Exception())
        },
        ExpectAllToThrow {
            `Exception`;
            "happy path";
            {[1], [2]};
            (Integer i) => throwThis(Exception("Bad"))
        }
    }.run();
    assertEquals(specResult.size, 4);
    assertEquals(specResult.collect(({{SpecResult*}*} element) => element.size), [2, 4, 1, 1]);

    assert(flatten(specResult).every((SpecResult result) => equalsCompare(result, success)));
}

String asString(SpecResult result) => result?.string else "success";

test shared void expectShouldFailWithExplanationMessage() {
    AssertionResult error() {
        throw;
    }
    value specResult = Specification {
        ExpectAll {
            "desc";
            [];
            
            () => expect(2 + 1, largerThan(4)),
            () => expect(3 - 2, equalTo(2)),
            () => expect(5 + 5, smallerThan(9)),
            error,
            () => expect(null, exist),
            () => expect([1,2,3].contains(5), to(be(true)))
        }
    }.run();

    assertEquals(flatten(specResult).map(asString).sequence(), [
        "Expect 'desc' failed: 3 is not larger than 4",
        "Expect 'desc' failed: 1 is not equal to 2",
        "Expect 'desc' failed: 10 is not smaller than 9",
        Exception().string,
        "Expect 'desc' failed: expected to exist but was null",
        "Expect 'desc' failed: expected true but was false"
    ]);
}

test shared void expectAllShouldFailWithExplanationMessageForFailedExamples() {
    value specResult = Specification {
        ExpectAll {
            "desc";
            examples = { ["a", "b"], ["c", "d"] };
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
        "Expect 'desc' failed: a is not larger than b [a, b]",
        "Expect 'desc' failed: c is not larger than d [c, d]",
        "Expect 'desc' failed: a is not equal to b [a, b]",
        "Expect 'desc' failed: c is not equal to d [c, d]",
        "success",
        Exception().string
    ]);
}

test shared void expectToThrowShouldFailWithExplanationMessage() {
    value specResult = Specification {
        ExpectToThrow {
            `MutationException`;
            "when throwing this";
            () => throwThis(Exception("Bad")),
            () => true
        }
    }.run();
    
    value errors = flatten(specResult);
    assertEquals(errors[0], "ExpectToThrow `` `MutationException` `` 'when throwing this' Failed: threw ``className(Exception())`` instead");
    assertEquals(errors[1], "ExpectToThrow `` `MutationException` `` 'when throwing this' Failed: did not throw any Exception");
}

test shared void expectAllToThrowShouldFailWithExplanationMessageForEachExample() {
    value specResult = Specification {
        ExpectAllToThrow {
            `MutationException`;
            "when throwing this";
            { [1, 2], [3, 4] };
            (Integer i, Integer j) => throwThis(Exception("Bad")),
            (Integer i, Integer j) => true
        }
    }.run();
    
    value errors = flatten(specResult);
    assertEquals(errors[0], "ExpectAllToThrow `` `MutationException` `` 'when throwing this' Failed on [1, 2]: threw ``className(Exception())`` instead");
    assertEquals(errors[1], "ExpectAllToThrow `` `MutationException` `` 'when throwing this' Failed on [3, 4]: threw ``className(Exception())`` instead");
    assertEquals(errors[2], "ExpectAllToThrow `` `MutationException` `` 'when throwing this' Failed on [1, 2]: did not throw any Exception");
    assertEquals(errors[3], "ExpectAllToThrow `` `MutationException` `` 'when throwing this' Failed on [3, 4]: did not throw any Exception");
}
