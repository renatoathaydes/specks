import ceylon.language.meta {
    type
}
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
    success
}


[SpecResult*] flatten({{SpecResult*}*}[] specResult) =>
        [ for (res in specResult) for (row in res) for (col in row) col ];

Boolean throwThis(Exception e) {
    throw e;
}

test shared void happySpecificationThatPassesAllTests() {
    value specResult = Specification {
        "Ceylon + operator works for integers";
        ExpectAll {
            examples = { [2, 4, 6], [0, 0, 0], [-1, 0, -1] };
            (Integer a, Integer b, Integer c) => a + b == c,
            (Integer a, Integer b, Integer c) => b + a == c
        },
        Expect {
            () => 2 + 2 == 4,
            equal -> [2 + 2, 4],
            equal -> [5 + 1, 1 + 5, 6],
            larger -> [2 + 1, 2]
        },
        ExpectToThrow {
            `Exception`;
            () => throwThis(Exception("Bad"))
        }
    }.run();

    assertEquals(specResult.size, 3);
    assertEquals(specResult.collect(({{SpecResult*}*} element) => element.size), [2, 4, 1]);

    assert(flatten(specResult).every((SpecResult result) => equalsCompare(result, success)));
}

String asString(SpecResult result) => result?.string else "success";

test shared void expectShouldFailWithExplanationMessage() {
    Integer error() {
        throw;
    }
    value specResult = Specification {
        "All failures";
        Expect {
            larger -> [2 + 1, 4],
            equal -> [1, 2, 3],
            smaller -> [10, 9],
            equal -> [0],
            equal -> {error(), 1},
            () => 2 + 2 == 10
        }
    }.run();

    assertEquals(flatten(specResult).map(asString).sequence, [
        "Failed: 3 is not larger than 4",
        "Failed: 1 is not equal to 2",
        "Failed: 10 is not smaller than 9",
        Exception("Must provide at least 2 elements for test comparison").string,
        Exception().string,
        "Failed: condition not met"
    ]);
}

test shared void expectAllShouldFailWithExplanationMessageForFailedExamples() {
    value specResult = Specification {
        "All errors";
        ExpectAll {
            examples = { ["a", "b"], ["c", "d"] };
            (String s1, String s2) => s1 > s2,
            (String s1, String s2) => s1 == s2,
            (String s1, String s2) => s1 == "c" then throwThis(Exception()) else true
        }
    }.run();

    assertEquals(flatten(specResult).map(asString).sequence, [
        "Failed: [a, b]",
        "Failed: [c, d]",
        "Failed: [a, b]",
        "Failed: [c, d]",
        "success",
        Exception().string
    ]);
}

test shared void expectToThrowShouldFailWithExplanationMessage() {
    value specResult = Specification {
        "";
        ExpectToThrow {
            `MutationException`;
            () => throwThis(Exception("Bad")),
            () => true
        }
    }.run();

    assertEquals(flatten(specResult), [
        "Failed: expected ``type(MutationException(""))`` but threw ``type(Exception())``",
        "Failed: did not throw any Exception"
    ]);
}
