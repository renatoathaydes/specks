import ceylon.language.meta {
    type
}
import ceylon.language.meta.model {
    Type,
    Class
}
class TypeArgumentsChecker() {
    
    alias AnyTuple => Tuple<Anything, Anything, Anything>;
    alias AnySequential => Sequential<Anything>;
    
    shared [Type<Anything>+] argumentTypes(Callable<Anything, Nothing> when) {
        value functionType = type(when);
        Type<Anything>? args = functionType.typeArgumentList[1];
        
        "Callables always have 2 arguments"
        assert(exists args);
        
        value result = allTypesOf(args);
        if (exists first = result.first) {
            return [first].append(result.rest);
        } else {
            throw Exception("The `when` function does not take any arguments");
        }
    }
    
    "Handles 'terminal' argument types which cannot have any other arguments after them."
    [Type<AnySequential>*]? terminalArgumentTypes(Type<Anything> argument) {
        if (is Type<AnyTuple> argument) {
            return null;
        }
        if (is Type<[]> argument) {
            return [];
        }
        if (is Type<AnySequential> argument) {
            return [argument];
        }
        return null;
    }
    
    [Type<Anything>*] allTypesOf(Type<Anything> argumentType) {
        // args may be a Tuple type or one of the terminal types
        value terminalArgTypes = terminalArgumentTypes(argumentType);
        if (exists terminalArgTypes) {
            return terminalArgTypes;
        }
        
        // not a terminal type, so it must be a Tuple type
        if (is Class<AnyTuple> argumentType) {
            return tupleTypes(argumentType);
        } else {
            throw Exception("Function has an unknown argument type: ``argumentType``");
        }
    }
    
    [Type<Anything>*] tupleTypes(Class<AnyTuple> tupleClass) {
        Type<Anything>? typeArgs = tupleClass.typeArgumentList[1];
        Type<Anything>? nextTypeArgs = tupleClass.typeArgumentList[2];
        
        "All Tuples have 3 type arguments"
        assert(exists typeArgs, exists nextTypeArgs);
        
        return [typeArgs].append(allTypesOf(nextTypeArgs));
    }
    
}
