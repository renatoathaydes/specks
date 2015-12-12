import ceylon.language.meta {
    type
}
import ceylon.language.meta.model {
    Type,
    Generic
}

import com.athaydes.specks.assertion {
    AssertionResult,
    AssertionFailure
}
import com.vasileff.ceylon.random.api {
    randomize
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
shared sealed
interface Block {
    shared formal String description;
    shared formal {SpecResult*} runTests();
}

"Top-level representation of a Specification in **specks**."
shared class Specification(
    "block which describe this [[Specification]]."
    {Block+} blocks) {
    
    {SpecResult*} results(Block block) {
        print("Running block ``block.description``");
        return block.runTests();
    }
    
    "Run this [[Specification]]. This method is called by **specks** to run this Specification
     and usually users do not need to call it directly."
    shared {SpecResult*}[] run() => blocks.collect(results);
}

{SpecResult*} assertSpecResultsExist(SpecResult[] result) {
    if (result.empty) {
        throw Exception("Did not find any tests to run.");
    }
    return result;
}

SpecResult specResult(
    AssertionResult() applyAssertion,
    String description,
    Anything[] where) {
    try {
        AssertionResult result = applyAssertion();
        switch (result)
        case (is AssertionFailure) {
            String whereString = where.empty then "" else " ``where``";
            return "``description`` failed: ``result````whereString``";
        }
        case (is Null) {
            return success;
        }
    } catch (Throwable t) {
        return Exception(t.message, t);
    }
}

String blockDescription(String blockName, String simpleDescription)
        => blockName + (simpleDescription.empty then "" else " '``simpleDescription``'");

Block assertionsWithoutExamplesBlock<Result>(
    String internalDescription,
    AssertionResult()(Callable<AssertionResult,Result>) apply,
    "Assertions to verify the result of running the 'when' function."
    {Callable<AssertionResult,Result>+} assertions)
        given Result satisfies Anything[] {
    
    return object satisfies Block {
        description = internalDescription;
        
        runTests() => assertSpecResultsExist(
            assertions.collect((assertion)
                => specResult(apply(assertion), description, [])));
    };
}

Block assertionsWithExamplesBlock<Where>(
    String internalDescription,
    AssertionResult(Where)[] assertions,
    {Where*} examples,
    Integer maxFailuresAllowed)
        given Where satisfies Anything[] {
    
    
    SpecResult[] applyExamples(AssertionResult(Where) when) {
        variable Integer failures = 0;
        
        SpecResult apply(Where example) {
            value result = specResult(() => when(example), internalDescription, example);
            if (result is SpecFailure) {
                failures++;
            }
            return result;
        }

        return [ for (example in examples)
            if (failures < maxFailuresAllowed) apply(example)
        ];
    }
    
    return object satisfies Block {
        description = internalDescription;
        
        runTests() => assertSpecResultsExist(
            assertions.flatMap(applyExamples).sequence());
        
        string = "[``description`` - ``assertions.size``\
                   assertions, ``examples.size`` examples]";
    };
}

"A block that consists of a series of one or more `expect` statements which
 verify the behaviour of a system."
shared Block expectations(
    "Assertions that verify the behaviour of a system."
    {AssertionResult+} assertions,
    "Description of this group of expectations."
    String description = "")
        => feature(() => [], assertions.map((a) => () => a), description);

"A feature block allows the description of how a software functionality is expected to work."
shared Block feature<out Where = [], in Result = Where>(
    "The action being tested in this feature."
    Callable<Result,Where> when,
    "Assertions to verify the result of running the 'when' function."
    {Callable<AssertionResult,Result>+} assertions,
    "Description of this feature."
    String description = "",
    "Input examples.<p/>
     Each example will be passed to each assertion function in the order it is declared."
    {Where*} examples = [],
    "Maximum number of failures to allow before stopping running more tests."
    Integer maxFailuresAllowed = 10)
        given Where satisfies Anything[]
        given Result satisfies Anything[] {
    
    String internalDescription = blockDescription("Feature", description);
    
    if (examples.empty) {
        "If you do not provide any examples, your 'when' function must not take any parameters."
        assert (is Callable<Result,[]> when);
        return assertionsWithoutExamplesBlock(internalDescription,
            (Callable<AssertionResult,Result> assertion)
                    => () => assertion(*when()), assertions);
    } else {
        return assertionsWithExamplesBlock(
            internalDescription,
            assertions.collect((assertion)
                => (Where example) => assertion(*when(*example))),
            examples,
            maxFailuresAllowed);
    }
}

shared Block errorCheck<Where = []>(
    "The action being tested in this feature."
    Callable<Anything,Where> when,
    {AssertionResult(Throwable?)+} assertions,
    String description = "",
    "Input examples.<p/>
     Each example will be passed to each assertion function in the order it is declared."
    {Where*} examples = [],
    "Maximum number of failures to allow before stopping running more tests."
    Integer maxFailuresAllowed = 10)
        given Where satisfies Anything[] {
    
    AssertionResult() applyAssertion
    (Anything() when)
    (AssertionResult(Throwable?) assertion) {
        try {
            when();
            return () => assertion(success);
        } catch (Throwable t) {
            return () => assertion(t);
        }
    }
    
    AssertionResult applyAssertionToExample
    (AssertionResult(Throwable?) assertion)
    (Where example)
            => applyAssertion(() => when(*example))(assertion)();
    
    String internalDescription = blockDescription("ErrorCheck", description);
    
    if (examples.empty) {
        "If you do not provide any examples, your 'when' function must not take any parameters."
        assert (is Callable<Anything,[]> when);
        return assertionsWithoutExamplesBlock(
            internalDescription,
            applyAssertion(when),
            assertions);
    } else {
        return assertionsWithExamplesBlock(
            internalDescription, 
            assertions.collect((assertion)
                => applyAssertionToExample(assertion)),
            examples,
            maxFailuresAllowed);
    }
    
}

shared Block forAll<Where>(
    "Single assertion which should hold for all possible inputs of a given function"
    Callable<AssertionResult, Where> assertion,
    "Description of this feature."
    String description = "",
    "Number of sample inputs to run tests with"
    Integer sampleCount = 100,
    "Input data generator functions"
    [Anything()+] generators = [randomStrings, randomIntegers],
    "Maximum number of failures to allow before stopping running more tests."
    Integer maxFailuresAllowed = 10)
        given Where satisfies Anything[]
        => propertyCheck(flatten((Where where) => [assertion(*where)]),
                { identity<AssertionResult> }, 
                    description, sampleCount, generators, maxFailuresAllowed);

shared Block propertyCheck<Result, Where>(
    "The action being tested in this feature."
    Callable<Result, Where> when,
    "Assertions to verify the result of running the 'when' function."
    {Callable<AssertionResult,Result>+} assertions,
    "Description of this feature."
    String description = "",
    "Number of sample inputs to run tests with"
    Integer sampleCount = 100,
    "Input data generator functions"
    [Anything()+] generators = [randomStrings, randomIntegers],
    "Maximum number of failures to allow before stopping running more tests."
    Integer maxFailuresAllowed = 10)
        given Where satisfies Anything[]
        given Result satisfies Anything[]
        => let (desc = description) object satisfies Block {
    
    description = desc;
    
    Anything()? iterableToInstanceGeneratorFor(
        Type<Anything> requiredType, 
        Type<Anything> genReturnType,
        Anything() generator) {
        if (genReturnType.subtypeOf(`Iterable<>`)) {
            "Specks currently only supports generators that produce Iterables whose
             elements type argument is the first one, such as [[List<Element>]]."
            assert(is Generic genReturnType);
            Type<Anything>? elementsType = genReturnType.typeArgumentList[0];
            
            if (exists elementsType, elementsType.subtypeOf(requiredType)) {
                assert(is {Anything*}() generator);
                {{Anything*}+} infiniteGenerator = { generator() }.cycled;
                return infiniteGenerator.flatMap(identity).iterator().next;
            }
        }
        return null;
    }
    
    Where exampleOf([Type<Anything>+] types) {
        {Anything()+} typeGenerators = types.map((requiredType) {
            [Anything()*] acceptableGenerators = generators.map((gen) {
                Type<Anything>? genReturnType = type(gen).typeArgumentList.first;
                if (exists genReturnType) {
                    return if (genReturnType.subtypeOf(requiredType))
                    then gen
                    else iterableToInstanceGeneratorFor(requiredType, genReturnType, gen);
                }
                return null;
            }).coalesced.sequence();
            
            if (acceptableGenerators.empty) {
                throw Exception("No generator exists for type: ``requiredType``.
                                 Add a generator function for the required type.");
            }
            Anything()? result = randomize(acceptableGenerators).first;
            assert(exists result);
            return result;
        });
        
        Tuple<Anything, Anything, Anything> typedTuple({Anything+} array) {
            if (exists second = array.rest.first) {
                return Tuple(array.first,
                    typedTuple({ second }.chain(array.rest.rest)));
            }
            else {
                return Tuple(array.first, []);
            }
        }
        
        [Anything+] instance = [ for (Anything() generate in typeGenerators) generate() ];
        
        Tuple<Anything,Anything,Anything> tuple = typedTuple(instance);
        
        "Tuple must be an instance of Where because Where was introspected to create it.
         If you ever see this error, please report a bug on GitHub!"
        assert(is Where tuple);
        return tuple;
    }
    
    [Type<Anything>+] argTypes = TypeArgumentsChecker().argumentTypes(when);
    
    {Where*} examples = (0:sampleCount).map((it)
        => exampleOf(argTypes));
    
    shared actual {SpecResult*} runTests()
            => feature(when, assertions, description,
                examples, maxFailuresAllowed).runTests();
    
};
