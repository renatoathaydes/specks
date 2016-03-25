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
    TestSkippedException,
    TestAbortedException
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
        print("Requesting runnables");
        value runnableTests = spec.collectRunnables();
        print("Got runnables");
        value groupTestListener = GroupTestListener();
        context.registerExtension(groupTestListener);
        context.fire().testStarted(TestStartedEvent(description));

        function contextFor(Integer index) {
            value variant = context.extension<TestVariantProvider>().variant(description, index, [index]);
            value variantDescription = description.forVariant(variant, index);
            return context.childContext(variantDescription);
        }

        variable Integer index = 1;

        for (block in runnableTests) {
            print("Looking at block ``block``");

            value exampleResultsIterator = block.iterator();
            print("Got iterator, executing assertions");

            // execute the next example until no more examples are left
            while (!executeTest(contextFor(index), instance, exampleResultsIterator)) {
                index++;
            }
        }

        context.fire().testFinished(TestFinishedEvent(
            TestResult(description, groupTestListener.worstState, true, null, groupTestListener.elapsedTime)));
    }

    Boolean handleExecution(TestExecutionContext context, Object? instance, Iterator<SpecCaseResult[]> exampleGetter) {
        value startTime = system.milliseconds;
        function elapsedTime() => system.milliseconds - startTime;

        try {
            value assertionResults = exampleGetter.next();

            if (is Finished assertionResults) {
                return true; // done
            }

            context.fire().testStarted(TestStartedEvent(context.description, instance));

            value errors = [for (res in assertionResults) if (is Exception res) res];
            value failures = [for (res in assertionResults) if (is String res) res];

            if (nonempty errors) {
                for (error in errors) {
                    error.printStackTrace();
                }
                context.fire().testFinished(TestFinishedEvent(
                    TestResult(context.description, TestState.error, false, errors.first, elapsedTime()), instance));
            } else if (nonempty failures) {
                context.fire().testFinished(TestFinishedEvent(
                    TestResult(context.description, TestState.failure, false, AssertionError(failures.string), elapsedTime()), instance));
            } else {
                context.fire().testFinished(TestFinishedEvent(
                    TestResult(context.description, TestState.success, false, null, elapsedTime()), instance));
            }

            return false;
        }
        catch (TestSkippedException e) {
            context.fire().testSkipped(TestSkippedEvent(TestResult(context.description, TestState.skipped, false, e)));
        }
        catch (TestAbortedException e) {
            context.fire().testAborted(TestAbortedEvent(TestResult(context.description, TestState.aborted, false, e)));
        }

        return true;
    }

    Boolean executeTest(TestExecutionContext context, Object? instance, Iterator<SpecCaseResult[]> exampleGetter) {
        print("Test: ``context.description``");
        print("Before");
        handleBeforeCallbacks(context, instance, () {})();
        print("Test run");
        value done = handleExecution(context, instance, exampleGetter);
        print("After");
        handleAfterCallbacks(context, instance, () {})();
        print("Done");
        return done;
    }

    shared actual void execute(TestExecutionContext parent) {
        value context = parent.childContext(description);
        try {
            verify(context);
            evaluateTestConditions(context);

            value instance = getInstance(context);

            value spec = getSpec(instance, context);

            if (unroll) {
                log.debug("Running unrolled specification");
                runUnrolledSpec(context, instance, spec);
            } else {
                log.debug("Running simple specification");
                value examplesIterator = spec.collectRunnables().flatMap(identity).iterator();
                executeTest(context, instance, examplesIterator);
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
