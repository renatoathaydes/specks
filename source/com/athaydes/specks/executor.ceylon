import ceylon.language.meta.declaration {
    FunctionDeclaration,
    ClassDeclaration,
    OpenClassOrInterfaceType
}
import ceylon.test {
    testExecutor,
    TestResult,
    TestState,
    TestListener
}
import ceylon.test.engine {
    DefaultTestExecutor,
    TestSkippedException
}
import ceylon.test.engine.spi {
    TestExecutor,
    TestExecutionContext,
    TestVariantProvider
}
import ceylon.test.event {
    TestStartedEvent,
    TestErrorEvent,
    TestFinishedEvent,
    TestSkippedEvent,
    TestAbortedEvent
}

"""**specks** test executor. To run your [[Specification]]s using Ceylon's test framework, annotate your
   top-level functions, classes, packages or your whole module with the [[testExecutor]] annotation.

   For example, to annotate a single test:

       testExecutor(`class SpecksTestExecutor`)
       test shared Specification mySpeck() => Specification {
           ...
       };"""
see(`interface TestExecutor`, `function testExecutor`)
shared class SpecksTestExecutor(FunctionDeclaration functionDeclaration, ClassDeclaration? classDeclaration)
        extends DefaultTestExecutor(functionDeclaration, classDeclaration) {

    value unroll = functionDeclaration.annotated<UnrollAnnotation>();

    shared actual void verifyFunctionReturnType() {
        if(is OpenClassOrInterfaceType openType = functionDeclaration.openType, openType.declaration != `class Specification`) {
            throw Exception("function ``functionDeclaration.qualifiedName`` should return Specification");
        }
    }

    Specification getSpec(Object? instance, TestExecutionContext context) {
        function invokeMemberFunction() {
            assert(exists i = instance, is Specification res = functionDeclaration.memberInvoke(i));
            return res;
        }
        function invokeTopFunction() {
            assert(is Specification res = functionDeclaration.invoke());
            return res;
        }

        value spec = functionDeclaration.toplevel
            then invokeTopFunction()
            else invokeMemberFunction();

        return spec;
    }

    void runUnrolledSpec(TestExecutionContext context, Object? instance, Specification spec) {
        value runnableTests = spec.collectRunnables();

        value groupTestListener = GroupTestListener();
        context.registerExtension(groupTestListener);
        context.fire().testStarted(TestStartedEvent(description));

        for (index -> testRunnable in runnableTests.indexed) {
            value variant = context.extension<TestVariantProvider>().variant(description, index, [index]);
            value variantDescription = description.forVariant(variant, index);
            print("Variant description: ``variantDescription``");
            value contextForVariant = context.childContext(variantDescription);
            executeTest(contextForVariant, instance, () => handleResults(testRunnable()));
        }

        context.fire().testFinished(TestFinishedEvent(
            TestResult(description, groupTestListener.worstState, true, null, groupTestListener.elapsedTime)));
    }

    void handleResults({SpecCaseResult*} results) {
        value r = results.sequence();
        value failures = [ for (specResult in r) if (is SpecCaseFailure specResult) specResult];
        print("Handling results: ``r``");

        if (!failures.empty) {
            value errors = [ for (failure in failures) if (is Exception failure) failure ];
            if (!errors.empty) {
                for (e in errors) {
                    e.printStackTrace();
                }
                throw Exception(failures.string);
            }
            throw AssertionError(failures.string);
        }
    }

    void executeTest(TestExecutionContext context, Object? instance, void execute()) {
        print("Test: ``context.description``");
        print("Before");
        handleBeforeCallbacks(context, instance, () {})();
        print("Test run");
        handleTestExecution(context, instance, execute)();
        print("After");
        handleAfterCallbacks(context, instance, () {})();
        print("Done");
    }

    shared actual void execute(TestExecutionContext parent) {
        value context = parent.childContext(description);
        try {
            verify(context);
            evaluateTestConditions(context);

            value instance = getInstance(context);

            value spec = getSpec(instance, context);

            if (unroll) {
                print("Running unrolled specification");
                runUnrolledSpec(context, instance, spec);
            } else {
                print("Running simple specification");
                executeTest(context, instance, () => handleResults(spec.run().flatMap(identity).sequence()));
            }
        }
        catch (TestSkippedException e) {
            context.fire().testSkipped(TestSkippedEvent(TestResult(description, TestState.skipped, false, e)));
        }
        catch (Throwable e) {
            context.fire().testError(TestErrorEvent(TestResult(description, TestState.error, false, e)));
        }
    }

}

class GroupTestListener() satisfies TestListener {

    Integer startTime = system.milliseconds;

    variable TestState worstStateVar = TestState.skipped;

    shared Integer elapsedTime => system.milliseconds - startTime;

    shared TestState worstState => worstStateVar;

    void updateWorstState(TestState state) {
        if( worstStateVar < state ) {
            worstStateVar = state;
        }
    }

    testFinished(TestFinishedEvent event) => updateWorstState(event.result.state);

    testError(TestErrorEvent event) => updateWorstState(event.result.state);

    testSkipped(TestSkippedEvent event) => updateWorstState(TestState.skipped);

    testAborted(TestAbortedEvent event) => updateWorstState(TestState.aborted);

}
