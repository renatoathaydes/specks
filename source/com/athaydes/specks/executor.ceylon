import ceylon.language.meta.declaration {
    FunctionDeclaration,
    ClassDeclaration,
    OpenClassOrInterfaceType
}
import ceylon.test {
    testExecutor
}
import ceylon.test.engine {
    DefaultTestExecutor
}
import ceylon.test.engine.spi {
    TestExecutor,
    TestExecutionContext
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

    shared actual void verifyFunctionReturnType() {
        if(is OpenClassOrInterfaceType openType = functionDeclaration.openType, openType.declaration != `class Specification`) {
            throw Exception("function ``functionDeclaration.qualifiedName`` should return Specification");
        }
    }

    void invokeFunction(FunctionDeclaration f, Object? instance)() {
        function invokeMemberFunction() {
            assert(exists i = instance, is Specification res = f.memberInvoke(i));
            return res;
        }
        function invokeTopFunction() {
            assert(is Specification res = f.invoke());
            return res;
        }

        value spec = f.toplevel then invokeTopFunction() else invokeMemberFunction();
        value result = spec.run();
        value allResults = [ for (specRun in result) for (specResult in specRun) specResult ];
        value failures = [ for (specResult in allResults) if (is SpecFailure specResult) specResult];

        if (!failures.empty) {
            value errors = [ for (failure in failures) if (is Exception failure) failure ];
            if (!errors.empty) {
                for (e in errors) { e.printStackTrace(); }
                throw Exception(failures.string);
            }
            throw AssertionError(failures.string);
        }
    }

    shared actual void handleTestInvocation(TestExecutionContext context, Object? instance, Anything[] args)() {
        invokeFunction(functionDeclaration, instance)();
    }

}
