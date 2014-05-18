import ceylon.language.meta.model {
    Type
}

"The result of running a Specification which fails or causes an error.
 A String represents a failure and describes the reason for the failure.
 An Exception means an unexpected error which occurred when trying to run the Specification."
shared alias SpecFailure => String|Exception;

"Successfull Specification"
shared alias SpecSuccess => Null;

"The result of runnin a Specification."
shared alias SpecResult => SpecFailure|SpecSuccess;

"Cases of [[Expect]] block's expectations."
shared alias ExpectCase<Elem> => Boolean()|<Comparison->{Elem+}>;

"Cases of [[ExpectAll]] block's expectations."
shared alias ExpectAllCase<Where> given Where satisfies [Anything*] => Callable<Boolean, Where>;

"Cases of [[ExpectAllToThrow]] block's expectations."
shared alias ExpectAllToThrowCase<Where> given Where satisfies [Anything*] => Callable<Anything, Where>;

"The result of running a Specification which is successful."
shared SpecSuccess success = null;

"Most generic kind of block which forms a [[Specification]]."
shared interface Block {
    shared formal String description;
    shared formal {{SpecResult*}*} runTests();
}

"Top-level representation of a Specification in **specks**."
shared class Specification(
    "block which describe this [[Specification]]."
    {Block+} blocks) {

    function results(Block block) => block.runTests();

    "Run this [[Specification]]. This method is called by **specks** to run this Specification
     and usually users do not need to call it directly."
    shared {{SpecResult*}*}[] run() => blocks collect results;

}

SpecResult maybePrependFailureMsg(String prefix, SpecResult result) {
    if (is String result) {
        return prefix + result;
    }
    return result;
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

"A kind of Expectation block which includes examples which should be verified."
shared class ExpectAll<out Where = [Anything*]>(
    "Description of this expectation."
    shared actual String description,
    "Examples which will be used to verify expectations.
     Each example will be passed to each expectation function in the order it is declared."
    {Where+} examples,
    "Expectations which describe how a system should behave."
    {ExpectAllCase<Where>+} expectations)
        satisfies Block
        given Where satisfies [Anything*] {

    SpecResult[] check(ExpectAllCase<Where> test) =>
            examples collect (Where where) =>
                maybePrependFailureMsg("ExpectAll '``description``' ", safeApply(test, where));

    runTests() => expectations collect check;

}

"Simple kind of Expectation block which accepts expectations of type [[ExpectCase]]"
shared class Expect<out Elem>(
    "Description of this expectation."
    shared actual String description,
    "Expectations which describe how a system should behave."
    {ExpectCase<Elem>+} expectations)
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
            return [maybePrependFailureMsg("Expect '``description``' ", safeApply(test, []))];
        }
        case (is <Comparison->{Elem+}>) {
            value testItems = test.item;
            if (testItems.size < 2) {
                return [Exception("Expect '``description``': ExpectCase ``testItems`` should contain at least 2 elements")];
            }
            variable Elem prev = testItems.first;
            for (elem in testItems.rest) {
                if (prev <=> elem != test.key) {
                    return ["Expect '``description``' Failed: ``prev`` is not ``strFor(test.key)`` ``elem``"];
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

String platformIndependentName(Object name) =>
        name.string.replace("::", ".");


{SpecResult*} shouldThrow(Type<Exception> expectedException, String(Exception?) errorDescriber)
                         ({Anything()*} actions) {
    SpecResult runAction(Anything() action) {
        try {
            action();
            return errorDescriber(null);
        } catch(e) {
            value exceptionClass = className(e);
            if (platformIndependentName(exceptionClass) == platformIndependentName(expectedException)) {
                return success;
            } else {
                return errorDescriber(e);
            }
        }
    }
    return { for (action in actions) runAction(action) };
}

"A kind of Expectation block which can be used to verify that errors are handled correctly."
shared class ExpectToThrow(
    "the exact type of the Exception which should be thrown by the given actions."
    Type<Exception> expectedException,
    "Description of this expectation."
    shared actual String description,
    "actions which should cause errors and throw the expected exception."
    {Anything()+} actions)
        satisfies Block {
    
    String describeError(Exception? actualException) {
        switch (actualException)
        case (is Null) {
            return "ExpectToThrow ``expectedException`` '``description``' " +
                    "Failed: did not throw any Exception";
        }
        case (is Exception) {
            return "ExpectToThrow ``expectedException`` '``description``' " +
                "Failed: threw ``className(actualException)`` instead";
        }
    }

    runTests() => actions.map((Anything() action) => { action }) collect shouldThrow(expectedException, describeError);

}

"A kind of Expectation block which can be used to verify that errors are handled correctly for each example provided."
shared class ExpectAllToThrow<out Where = [Anything*]>(
    "the exact type of the Exception which should be thrown by the given actions."
    Type<Exception> expectedException,
    "Description of this expectation."
    shared actual String description,
    "Examples which will be used to verify expectations.
     Each example will be passed to each expectation function in the order it is declared."
    {Where+} examples,
    "actions which should cause errors and throw the expected exception."
    {ExpectAllToThrowCase<Where>+} expectations)
        satisfies Block
        given Where satisfies [Anything*] {
    
    variable Where? currentExample = null;
    
    function currentExampleString() {
        assert (exists ce = currentExample);
        return "on ``ce``";
    }
    
    String describeError(Exception? actualException) {
        switch (actualException)
        case (is Null) {
            return "ExpectAllToThrow ``expectedException`` '``description``' " +
                    "Failed ``currentExampleString()``: did not throw any Exception";
        }
        case (is Exception) {
            return "ExpectAllToThrow ``expectedException`` '``description``' " +
                    "Failed ``currentExampleString()``: threw ``className(actualException)`` instead";
        }
    }
    
    {Anything()*} forEachExample {
        function checkExpectation(ExpectAllToThrowCase<Where> expect, Where example)() {
            currentExample = example;
            return expect(*example);
        }
        return { for (expect in expectations) for (example in examples) checkExpectation(expect, example) };
    }
    
    SpecResult[] check(ExpectAllToThrowCase<Where> test) =>
        shouldThrow(expectedException, describeError)(forEachExample).sequence;
    
    runTests() => expectations collect check;
    
}
