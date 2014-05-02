import ceylon.collection {
    HashSet
}
import ceylon.language.meta.declaration {
    FunctionDeclaration,
    ClassDeclaration,
    OpenClassOrInterfaceType,
    InterfaceDeclaration,
    ClassOrInterfaceDeclaration
}
import ceylon.language.meta.model {
    Class
}
import ceylon.test {
    TestExecutor,
    TestRunContext,
    TestDescription,
    TestResult,
    success,
    TestAnnotation,
    BeforeTestAnnotation,
    IgnoreAnnotation,
    error,
    AfterTestAnnotation,
    ignored,
    failure,
    testExecutor
}
import ceylon.test.event {
    TestStartEvent,
    TestFinishEvent,
    TestIgnoreEvent,
    TestErrorEvent
}

"""**specks** test executor. To run your [[Specification]]s using Ceylon's test framework, annotate your
   top-level functions, classes, packages or your whole module with the [[testExecutor]] annotation.

   For example, to annotate a single test:

       testExecutor(`class SpecksTestExecutor`)
       test shared Specification mySpeck() => Specification {
           ...
       };"""
see(`interface TestExecutor`, `function testExecutor`)
shared class SpecksTestExecutor(FunctionDeclaration funcDecl, ClassDeclaration? classDecl) satisfies TestExecutor {

    // TODO most of this class is copied from ceylon.test.DefaultTestExecutor, but as this class is not shared we can't
    // subclass it. Should change this when that becomes possible.

    variable Object? instance = null;

    Object getInstance() {
        if( exists i = instance ) {
            return i;
        }
        else {
            assert(exists classDecl);
            assert(is Class<Object, []> classModel = classDecl.apply<Object>());
            Object i = classModel();
            instance = i;
            return i;
        }
    }

    String getName() {
        if( funcDecl.toplevel ) {
            return funcDecl.qualifiedName;
        }
        else {
            assert(exists classDecl);
            return classDecl.qualifiedName + "." + funcDecl.name;
        }
    }

    shared actual default TestDescription description = TestDescription(getName(), funcDecl, classDecl);

    shared actual default void execute(TestRunContext context) {
        try {
            void fireError(String msg)
                    => context.fireTestError(TestErrorEvent(TestResult(description, error, Exception(msg))));

            Anything() handler =
                    verifyClass(fireError,
                verifyFunction(fireError,
                    verifyCallbacks(fireError,
                        handleTestIgnore(context,
                            handleTestExecution(context,
                                handleAfterCallbacks(context,
                                        handleBeforeCallbacks(
                                            invokeTest)))))));

            handler();
        }
        finally {
            instance = null;
        }
    }

    void verifyClass(Anything(String) fireError, Anything() handler)() {
        if( exists classDecl ) {
            if( !classDecl.toplevel ) {
                fireError("class ``classDecl.qualifiedName`` should be toplevel");
                return;
            }
            if( classDecl.abstract ) {
                fireError("class ``classDecl.qualifiedName`` should not be abstract");
                return;
            }
            if( classDecl.anonymous ) {
                fireError("class ``classDecl.qualifiedName`` should not be anonymous");
                return;
            }
            if( !classDecl.parameterDeclarations.empty ) {
                fireError("class ``classDecl.qualifiedName`` should have no parameters");
                return;
            }
            if( !classDecl.typeParameterDeclarations.empty ) {
                fireError("class ``classDecl.qualifiedName`` should have no type parameters");
                return;
            }
        }
        handler();
    }

    void verifyFunction(Anything(String) fireError, Anything() handler)() {
        if( funcDecl.annotations<TestAnnotation>().empty ) {
            fireError("function ``funcDecl.qualifiedName`` should be annotated with test");
            return;
        }
        if( !funcDecl.parameterDeclarations.empty ) {
            fireError("function ``funcDecl.qualifiedName`` should have no parameters");
            return;
        }
        if( !funcDecl.typeParameterDeclarations.empty ) {
            fireError("function ``funcDecl.qualifiedName`` should have no type parameters");
            return;
        }
        if(is OpenClassOrInterfaceType openType = funcDecl.openType, openType.declaration != `class Specification`) {
            fireError("function ``funcDecl.qualifiedName`` should return Specification");
            return;
        }
        handler();
    }

    void verifyCallbacks(Anything(String) fireError, Anything() handler)() {
        value callbacks = findCallbacks<BeforeTestAnnotation|AfterTestAnnotation>();
        for(callback in callbacks) {
            value callbackType = callback.annotations<BeforeTestAnnotation>().empty then "after" else "before";
            if( !callback.parameterDeclarations.empty ) {
                fireError("``callbackType`` callback ``callback.qualifiedName`` should have no parameters");
                return;
            }
            if( !callback.typeParameterDeclarations.empty ) {
                fireError("``callbackType`` callback ``callback.qualifiedName`` should have no type parameters");
                return;
            }
            if(is OpenClassOrInterfaceType openType = callback.openType, openType.declaration != `class Anything`) {
                fireError("``callbackType`` callback ``callback.qualifiedName`` should be void");
                return;
            }
        }
        handler();
    }

    void handleTestIgnore(TestRunContext context, Anything() handler)() {
        value ignoreAnnotation = findAnnotation<IgnoreAnnotation>(funcDecl, classDecl);
        if( exists ignoreAnnotation ) {
            context.fireTestIgnore(TestIgnoreEvent(TestResult(description, ignored, Exception(ignoreAnnotation.reason))));
            return;
        }
        handler();
    }

    void handleTestExecution(TestRunContext context, Anything() handler)() {
        value i = !funcDecl.toplevel then getInstance() else null;
        value startTime = system.milliseconds;
        function elapsedTime() => system.milliseconds - startTime;

        try {
            context.fireTestStart(TestStartEvent(description, i));
            handler();
            context.fireTestFinish(TestFinishEvent(TestResult(description, success, null, elapsedTime()), i));
        }
        catch(Throwable e) {
            if( e is AssertionError) {
                context.fireTestFinish(TestFinishEvent(TestResult(description, failure, e, elapsedTime()), i));
            }
            else {
                context.fireTestFinish(TestFinishEvent(TestResult(description, error, e, elapsedTime()), i));
            }
        }
    }

    Specification handleBeforeCallbacks(Specification() handler)() {
        value callbacks = findCallbacks<BeforeTestAnnotation>().reversed;
        for(callback in callbacks) {
            invokeFunction(callback);
        }
        return handler();
    }

    void handleAfterCallbacks(TestRunContext context, Specification() handler)() {
        value exceptionsBuilder = SequenceBuilder<Throwable>();
        try {
            value spec = handler();
            value result = spec.run();
            value allResults = [ for (a in result) for (b in a) for (c in b) c ];
            value failures = [ for (specResult in allResults) if (is SpecFailure specResult) specResult];
            if (!failures.empty) {
                value errors = [ for (failure in failures) if (is Exception failure) failure ];
                if (!errors is Empty) {
                    throw Exception(failures.string);
                }
                throw AssertionError(failures.string);
            }
        }
        catch(Throwable e) {
            exceptionsBuilder.append(e);
        }
        finally {
            value callbacks = findCallbacks<AfterTestAnnotation>();
            for(callback in callbacks) {
                try {
                    invokeFunction(callback);
                }
                catch(Throwable e) {
                    exceptionsBuilder.append(e);
                }
            }
        }

        value exceptions = exceptionsBuilder.sequence;
        if( exceptions.size == 0 ) {
            // noop
        }
        else if( exceptions.size == 1 ) {
            assert(exists e = exceptions.first);
            throw e;
        }
        else {
            throw Exception(exceptions.string);
        }
    }

    FunctionDeclaration[] findCallbacks<CallbackType>() given CallbackType satisfies Annotation{
        value callbacks = HashSet<FunctionDeclaration>();

        if( exists classDecl ) {

            void visit(ClassOrInterfaceDeclaration? decl, void do(ClassOrInterfaceDeclaration decl)) {
                if(exists decl) {
                    do(decl);
                    visit(decl.extendedType?.declaration, do);
                    for(satisfiedType in decl.satisfiedTypes) {
                        visit(satisfiedType.declaration, do);
                    }
                }
            }

            visit(classDecl, void (ClassOrInterfaceDeclaration decl) {
                callbacks.addAll((decl is ClassDeclaration) then decl.annotatedDeclaredMemberDeclarations<FunctionDeclaration, CallbackType>() else []);
            });
            visit(classDecl, void (ClassOrInterfaceDeclaration decl) {
                callbacks.addAll((decl is InterfaceDeclaration) then decl.annotatedDeclaredMemberDeclarations<FunctionDeclaration, CallbackType>() else []);
            });
            visit(classDecl, void (ClassOrInterfaceDeclaration decl) {
                callbacks.addAll(decl.containingPackage.annotatedMembers<FunctionDeclaration, CallbackType>());
            });

        }
        else {
            callbacks.addAll(funcDecl.containingPackage.annotatedMembers<FunctionDeclaration, CallbackType>());
        }

        return callbacks.sequence;
    }

    Specification invokeTest() {
        value spec = invokeFunction(funcDecl);
        assert(is Specification spec);
        return spec;
    }

    Anything invokeFunction(FunctionDeclaration f) {
        if( f.toplevel ) {
            return f.invoke();
        }
        else {
            return f.memberInvoke(getInstance());
        }
    }

}

A? findAnnotation<out A>(FunctionDeclaration funcDecl, ClassDeclaration? classDecl) given A satisfies Annotation {
    variable value a = funcDecl.annotations<A>()[0];
    if(!(a exists)) {
        if(exists classDecl) {
            a = findAnnotations<A>(classDecl)[0];
            if(!(a exists)) {
                a = classDecl.containingPackage.annotations<A>()[0];
                if(!(a exists)) {
                    a = classDecl.containingModule.annotations<A>()[0];
                }
            }
        }
        else {
            a = funcDecl.containingPackage.annotations<A>()[0];
            if(!(a exists)) {
                a = funcDecl.containingModule.annotations<A>()[0];
            }
        }
    }
    return a;
}

A[] findAnnotations<out A>(ClassDeclaration classDecl) given A satisfies Annotation {
    value annotationBuilder = SequenceBuilder<A>();
    variable ClassDeclaration? declVar = classDecl;
    while(exists decl = declVar) {
        annotationBuilder.appendAll(decl.annotations<A>());
        declVar = decl.extendedType?.declaration;
    }
    return annotationBuilder.sequence;
}
