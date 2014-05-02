import ceylon.language.meta {
    type
}
import ceylon.language.meta.model {
    Type
}

shared alias SpecFailure => String|Exception;
shared alias SpecSuccess => Null;
shared alias SpecResult => SpecFailure|SpecSuccess;
shared alias ExpectCase<Elem> => Boolean()|<Comparison->{Elem+}>;
shared alias ExpectAllCase<Where> given Where satisfies [Anything*] => Callable<Boolean, Where>;

shared abstract class NoArgs() of noArgs {}
object noArgs extends NoArgs() {}

shared Null success = null;

shared interface Block {
    shared formal {{SpecResult*}*} runTests();
}

shared class Specification(
    String description,
    {Block+} blocks) {

    function results(Block block) => block.runTests();

    shared {{SpecResult*}*}[] run() => blocks collect results;

}

SpecResult safeApply<Where>(ExpectAllCase<Where> test, Where where)
        given Where satisfies [Anything*] {
    try {
        if (test(*where)) {
            return success;
        }
        return (where.empty) then "Failed: condition not met"
        else "Failed: ``where``";
    } catch(e) {
        return e;
    }
}

shared class ExpectAll<out Where = [Anything*]>({Where+} examples, {ExpectAllCase<Where>+} expectations)
        satisfies Block
        given Where satisfies [Anything*] {

    SpecResult[] check(ExpectAllCase<Where> test) =>
            examples collect (Where where) => safeApply(test, where);

    runTests() => expectations collect check;

}

shared class Expect<out Elem>({ExpectCase<Elem>+} expectations)
        satisfies Block
        given Elem satisfies Comparable<Elem> {

    String strFor(Comparison key) {
        switch (key)
        case (equal) { return "equal to"; }
        case (larger) { return "larger than"; }
        case (smaller) { return "smaller than"; }
    }

    [SpecResult+] check(ExpectCase<Elem> test) {
        switch (test)
        case (is Boolean()) {
            return [safeApply(test, [])];
        }
        case (is <Comparison->{Elem+}>) {
            value testItems = test.item;
            if (testItems.size < 2) {
                return [Exception("Must provide at least 2 elements for test comparison")];
            }
            variable Elem prev = testItems.first;
            for (elem in testItems.rest) {
                if (prev <=> elem != test.key) {
                    return ["Failed: ``prev`` is not ``strFor(test.key)`` ``elem``"];
                }
                prev = elem;
            }
            return [success];
        }
    }

    [SpecResult+](ExpectCase<Elem>) safely([SpecResult+](ExpectCase<Elem>) test) {
        function safe(ExpectCase<Elem> f) {
            try {
                return check(f);
            } catch(e) {
                return [e];
            }
        }
        return safe;
    }

    runTests() => expectations collect safely(check);

}

shared class ExpectToThrow(Type<Exception> expectedException, {Anything()+} actions)
        satisfies Block {

    {SpecResult+} shouldThrow(Anything() action) {
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
