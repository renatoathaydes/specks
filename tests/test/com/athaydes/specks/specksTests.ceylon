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
    Expect,
    SpecResult,
    ExpectAllToThrow,
    success
}


[SpecResult*] flatten({{SpecResult*}*}[] specResult) =>
        [ for (res in specResult) for (row in res) for (col in row) col ];

Boolean throwThis(Exception e) {
    throw e;
}

test shared void happySpecificationThatPassesAllTests() {
    value specResult = Specification {
        ExpectAll {
            "";
            examples = { [2, 4, 6], [0, 0, 0], [-1, 0, -1] };
            (Integer a, Integer b, Integer c) => a + b == c,
            (Integer a, Integer b, Integer c) => b + a == c
        },
        Expect {
            "";
            () => 2 + 2 == 4,
            equal -> [2 + 2, 4],
            equal -> [5 + 1, 1 + 5, 6],
            larger -> [2 + 1, 2]
        },
        ExpectToThrow {
            `Exception`;
            "when throwing this exception";
            () => throwThis(Exception("Bad"))
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
    Integer error() {
        throw;
    }
    value specResult = Specification {
        Expect {
            "desc";
            larger -> [2 + 1, 4],
            equal -> [1, 2, 3],
            smaller -> [10, 9],
            equal -> [0],
            equal -> {error(), 1},
            () => 2 + 2 == 10
        }
    }.run();

    assertEquals(flatten(specResult).map(asString).sequence, [
        "Expect 'desc' Failed: 3 is not larger than 4",
        "Expect 'desc' Failed: 1 is not equal to 2",
        "Expect 'desc' Failed: 10 is not smaller than 9",
        Exception("Expect 'desc': ExpectCase [0] should contain at least 2 elements").string,
        Exception().string,
        "Expect 'desc' Failed: condition not met"
    ]);
}

test shared void expectAllShouldFailWithExplanationMessageForFailedExamples() {
    value specResult = Specification {
        ExpectAll {
            "desc";
            examples = { ["a", "b"], ["c", "d"] };
            (String s1, String s2) => s1 > s2,
            (String s1, String s2) => s1 == s2,
            (String s1, String s2) => s1 == "c" then throwThis(Exception()) else true
        }
    }.run();

    assertEquals(flatten(specResult).map(asString).sequence, [
        "ExpectAll 'desc' Failed: [a, b]",
        "ExpectAll 'desc' Failed: [c, d]",
        "ExpectAll 'desc' Failed: [a, b]",
        "ExpectAll 'desc' Failed: [c, d]",
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
