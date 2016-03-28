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

    "Ensures that the test function returns a [[Specification]]."
    throws(`class Exception`, "if the test function has a bad return type")
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

    void runSimpleSpec(TestExecutionContext context, Object? instance, Specification spec) {
        value blocksResults = spec.run().flatMap(identity).map((it) => it.item);
        {SpecCaseResult*} assertionResults() {
            return blocksResults.map((it) => it()).flatMap(identity);
        }
        executeTest(context, instance, assertionResults);
    }

    void runUnrolledSpec(TestExecutionContext context, Object? instance, Specification spec) {
        value specResult = spec.run();
        value groupTestListener = GroupTestListener();
        context.registerExtension(groupTestListener);
        context.fire().testStarted(TestStartedEvent(description));

        function contextFor(Integer index, Anything[] example) {
            value variant = context.extension<TestVariantProvider>().variant(description, index, example);
            value variantDescription = description.forVariant(variant, index);
            return context.childContext(variantDescription);
        }

        variable Integer index = 1;
        for (blockResult in specResult) {
            for (exampleAssertions in blockResult) {
                value example -> assertionResults = exampleAssertions;
                executeTest(contextFor(index++, example), instance, assertionResults);
            }
        }

        context.fire().testFinished(TestFinishedEvent(
            TestResult(description, groupTestListener.worstState, true, null, groupTestListener.elapsedTime)));
    }

    void handleExecution(TestExecutionContext context, Object? instance, {SpecCaseResult*}() resultsGetter) {
        value startTime = system.milliseconds;
        function elapsedTime() => system.milliseconds - startTime;

        try {
            context.fire().testStarted(TestStartedEvent(context.description, instance));

            log.trace("Evaluating Specification case");
            value results = resultsGetter().sequence();
            value errors = [for (res in results) if (is Exception res) res];
            value failures = [for (res in results) if (is String res) res];

            log.info("Results: ``results``");

            if (nonempty errors) {
                log.warn(() => "Specification had ``errors.size`` error(s)");
                for (error in errors) {
                    error.printStackTrace();
                }
                context.fire().testFinished(TestFinishedEvent(
                    TestResult(context.description, TestState.error, false, errors.first, elapsedTime()), instance));
            } else if (nonempty failures) {
                log.info(() => "Specification had ``failures.size`` failure(s)");
                context.fire().testFinished(TestFinishedEvent(
                    TestResult(context.description, TestState.failure, false, AssertionError(failures.string), elapsedTime()), instance));
            } else {
                log.trace("Specification case ran without problems");
                context.fire().testFinished(TestFinishedEvent(
                    TestResult(context.description, TestState.success, false, null, elapsedTime()), instance));
            }
        }
        catch (TestSkippedException e) {
            log.info("Specification was skipped");
            context.fire().testSkipped(TestSkippedEvent(
                TestResult(context.description, TestState.skipped, false, e)));
        }
        catch (TestAbortedException e) {
            log.info("Aborted Specification");
            context.fire().testAborted(TestAbortedEvent(
                TestResult(context.description, TestState.aborted, false, e)));
        }
    }

    void executeTest(TestExecutionContext context, Object? instance,
                        {SpecCaseResult*}() resultsGetter) {
        log.trace("Running beforeTest functions");
        handleBeforeCallbacks(context, instance, () {})();
        handleExecution(context, instance, resultsGetter);
        log.trace("Running afterTest functions");
        handleAfterCallbacks(context, instance, () {})();
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
                runSimpleSpec(context, instance, spec);
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
