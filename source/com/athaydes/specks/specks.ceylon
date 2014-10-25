import ceylon.language.meta.model {
    Type
}

import com.athaydes.specks.assertion {
    AssertionResult,
    assertionSuccess,
    AssertionFailure
}

"The result of running a Specification which fails or causes an error.
 A String represents a failure and describes the reason for the failure.
 An Exception means an unexpected error which occurred when trying to run the Specification."
shared alias SpecFailure => String|Exception;

"Successfull Specification"
shared alias SpecSuccess => Null;

"The result of running a Specification."
shared alias SpecResult => SpecFailure|SpecSuccess;

"Cases of [[ExpectAllToThrow]] block's expectations."
shared alias ExpectAllToThrowCase<Where>
        given Where satisfies [Anything*]
        => Callable<Anything, Where>;

"The result of running a Specification which is successful."
shared SpecSuccess success = null;

"Most generic kind of block which forms a [[Specification]]."
shared sealed interface Block {
    shared formal String description;
    shared formal {{SpecResult*}*} runTests();
}

"Top-level representation of a Specification in **specks**."
shared class Specification(
    "block which describe this [[Specification]]."
    {Block+} blocks) {

    function results(Block block) {
        print("Running block ``block.description``");
        return block.runTests();
    }

    "Run this [[Specification]]. This method is called by **specks** to run this Specification
     and usually users do not need to call it directly."
    shared {{SpecResult*}*}[] run() => blocks.collect(results);

}

String errorPrefix(String description) => "Expect '``description``' failed: ";

SpecResult maybePrependFailureMsg(String prefix, AssertionResult result, Object suffix = "") {
    String suffixString(Object suffix) {
        if (is {Anything*} suffix) {
            return suffix.empty then "" else " " + suffix.string;
        }
        return " " + suffix.string;
    }
    switch(result)
    case (is AssertionFailure) {
        return prefix + result.string + suffixString(suffix);
    }
    case(assertionSuccess) {
        return success;    
    }
}

SpecResult safeApply<Where>(Callable<AssertionResult, Where> test, Where where, String description)
        given Where satisfies [Anything*] {
    print("Running test '``description``' with examples ``where``");
    value failureMsg = errorPrefix(description);
    try {
        value result = test(*where);
        return maybePrependFailureMsg(failureMsg, result, where);
    } catch(Throwable t) {
        return Exception(t.message, t);
    }
}

"A kind of Expectation block which includes examples which should be verified."
shared class ExpectAll<Where = []>(
    "Description of this expectation."
    shared actual String description = "",
    "Examples which will be used to verify expectations.
     Each example will be passed to each expectation function in the order it is declared."
    {Where*} examples = [],
    "All assertions that are expected to pass."
    {Callable<AssertionResult, Where>*} assertions = {})
        satisfies Block
        given Where satisfies Anything[] {

    SpecResult[] check(Callable<AssertionResult, Where> test) {
         if (is Callable<AssertionResult, []> test) {
             return [safeApply(test, [], description)];
         } else {
             return examples.collect((Where where)
                 => safeApply(test, where, description));
         }
    }
    
    {{SpecResult*}*} assertTestsRun({{SpecResult*}*}() runner) {
        value result = runner();
        if (result.empty || result.every((it) => it.empty)) {
            return {{Exception("Did not find any tests to run.")}};
        }
        return result;
    }
        

    runTests() => assertTestsRun(() => assertions.collect(check));
    
    string = "Number of tests: ``assertions.size``";

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

    runTests() => actions.map((Anything() action) => { action }).collect(shouldThrow(expectedException, describeError));

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
        shouldThrow(expectedException, describeError)(forEachExample).sequence();
    
    runTests() => expectations.collect(check);
    
}
