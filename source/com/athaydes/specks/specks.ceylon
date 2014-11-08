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

{{SpecResult*}*} assertSpecResultsExist({{SpecResult*}*} result) {
    if (result.empty || result.every((it) => it.empty)) {
        throw Exception("Did not find any tests to run.");
    }
    return result;
}

SpecResult specResult(AssertionResult() applyAssertion, String description, Anything[] where) {
    try {
        value result = applyAssertion();
        switch(result)
        case (is AssertionFailure) {
            value whereString = where.empty then "" else " ``where``";
            return "``description`` failed: ``result````whereString``";
        }
        case(assertionSuccess) {
            return success;    
        }    
    } catch(Throwable t) {
        t.printStackTrace();
        return Exception(t.message, t);
    }
}

String blockDescription(String blockName, String simpleDescription)
        => blockName + (simpleDescription.empty then "" else " '``simpleDescription``'");


Block assertionsWithoutExamplesBlock<Result>(
    String internalDescription,
    AssertionResult()(Callable<AssertionResult, Result>) apply,
    "Assertions to verify the result of running the 'when' function."
    {Callable<AssertionResult, Result>+} assertions)
            given Result satisfies Anything[] {

    object block satisfies Block {
        description = internalDescription;
        
        runTests() => assertSpecResultsExist([assertions.collect((assertion)
            => specResult(apply(assertion), description, []))]);
    }

    return block;
}

Block assertionsWithExamplesBlock<Where>(
    String internalDescription,
    AssertionResult(Where)[] assertions,
    {Where*} examples)
        given Where satisfies Anything[] {
    
    SpecResult[] safeApplyAll(
        AssertionResult(Where) when,
        String description,
        {Where*} examples) {
        
        AssertionResult() applyExample(Where example)
                => () => when(example);
        
        return examples.collect((example)
            => specResult(applyExample(example), description, example));
    }
    
    object block satisfies Block {
        description = internalDescription;
        
        runTests() => assertSpecResultsExist(assertions.collect((assertion)
            => safeApplyAll(assertion, description, examples)));
        
        string = "[``description`` - ``assertions.size`` assertions, ``examples.size`` examples]";   
    }
    
    return block;
}

"A feature block allows the description of how a software functionality is expected to work."
shared Block feature<out Where = [], in Result = Where>(
    "The action being tested in this feature."
    Callable<Result, Where> when,
    "Assertions to verify the result of running the 'when' function."
    {Callable<AssertionResult, Result>+} assertions,
    "Description of this feature."
    String description = "",
    "Input examples.<p/>
     Each example will be passed to each assertion function in the order it is declared."
    {Where*} examples = [])
        given Where satisfies Anything[]
        given Result satisfies Anything[] {
    
    value internalDescription = blockDescription("Feature", description);
    
    if (examples.empty) {
        print("No examples!");
        "If you do not provide any examples, your 'when' function must not take any parameters."
        assert(is Callable<Result, []> when);
        print("when takes no params");
        return assertionsWithoutExamplesBlock(internalDescription,
            (Callable<AssertionResult, Result> assertion) => ()
                    => assertion(*when()), assertions);
    } else {
        return assertionsWithExamplesBlock(internalDescription, assertions.collect((assertion)
            => (Where example) => assertion(*when(*example))), examples);    
    }
}

shared Block errorCheck<Where = []>(
    "The action being tested in this feature."
    Callable<Anything, Where> when,
    {AssertionResult(Throwable?)+} assertions,
    String description = "",
    "Input examples.<p/>
     Each example will be passed to each assertion function in the order it is declared."
    {Where*} examples = [])
        given Where satisfies Anything[] {
    
    AssertionResult applyAssertionToExample(AssertionResult(Throwable?) assertion)(Where example) {
        try {
            when(*example);
            return assertion(null);
        } catch (Throwable t) {
            return assertion(t);
        }
    }
    
    AssertionResult() applyAssertion(Anything() when)(AssertionResult(Throwable?) assertion) {
        try {
            when();
            return () => assertion(null);
        } catch (Throwable t) {
            return () => assertion(t);
        }
    }
    
    value internalDescription = blockDescription("ErrorCheck", description);
    
    if (examples.empty) {
        "If you do not provide any examples, your 'when' function must not take any parameters."
        assert(is Callable<Anything, []> when);
        return assertionsWithoutExamplesBlock(internalDescription, applyAssertion(when), assertions);
    } else {
        return assertionsWithExamplesBlock(internalDescription, assertions.collect((assertion)
            => applyAssertionToExample(assertion)), examples);    
    }
}

