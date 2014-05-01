import ceylon.language.meta {
    type
}
import ceylon.language.meta.model {
    Type
}

shared alias TestError => String;
shared alias Success => Null;
shared alias TestResult => TestError|Success;
shared alias ExpectCase<Type> => Boolean()|<Comparison->{Type+}>;

shared abstract class NoArgs() of noArgs {}
object noArgs extends NoArgs() {}

shared Null success = null;

shared interface Block {
    shared formal {{TestResult*}*} runTests();
}

shared class Specification(
    String description,
    {Block+} blocks) {

    function results(Block block) => block.runTests();

    shared {{TestResult*}*}[] run() => blocks collect results;

}

TestResult safeApply<Where>(Callable<Boolean|TestError, Where> test, Where where)
        given Where satisfies [Anything*] {
    try {
        if (is Callable<TestError, Where> test) {
            return test(*where);
        }
        if (is Callable<Boolean, Where> test, test(*where)) {
            return success;
        }
        return (where.empty) then "Failed: condition not met"
        else "Failed: ``where``";
    } catch(e) {
        return "Error: ``e``";
    }
}

shared class ExpectAll<out Where = [Anything*]>({Where+} examples, {Callable<Boolean, Where>+} expectations)
        satisfies Block
        given Where satisfies [Anything*] {

    TestResult[] check(Callable<Boolean, Where> test) =>
            examples collect (Where where) => safeApply(test, where);

    runTests() => expectations collect check;

}

shared class Expect<Type>({ExpectCase<Type>+} expectations)
        satisfies Block
        given Type satisfies Comparable<Type> {

    String strFor(Comparison key) {
        switch (key)
        case (equal) { return "equal to"; }
        case (larger) { return "larger than"; }
        case (smaller) { return "smaller than"; }
    }

    [TestResult+] check(ExpectCase<Type> test) {
        switch (test)
        case (is Boolean()) {
            return [safeApply(test, [])];
        }
        case (is <Comparison->{Type+}>) {
            value testItems = test.item;
            if (testItems.size < 2) {
                return ["Error: Must provide at least 2 elements for test comparison"];
            }
            variable Type prev = testItems.first;
            for (elem in testItems.rest) {
                if (prev <=> elem != test.key) {
                    return ["Failed: ``prev`` is not ``strFor(test.key)`` ``elem``"];
                }
                prev = elem;
            }
            return [success];
        }
    }

    [TestResult+](ExpectCase<Type>) safely([TestResult+](ExpectCase<Type>) test) {
        function safe(ExpectCase<Type> f) {
            try {
                return check(f);
            } catch(e) {
                return ["Error: ``e``"];
            }
        }
        return safe;
    }

    runTests() => expectations collect safely(check);

}

shared class ExpectToThrow(Type<Exception> expectedException, {Anything()+} actions)
        satisfies Block {

    {TestResult+} shouldThrow(Anything() action) {
        try {
            action();
            return { "Failed: did not throw any Exception" };
        } catch(e) {
            if (type(e) == expectedException) {
                return {success};
            } else {
                return { "Failed: expected ``expectedException`` but threw ``type(e)``" };
            }
        }
    }

    runTests() => actions collect shouldThrow;

}
