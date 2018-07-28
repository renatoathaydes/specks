import ceylon.language.meta {
    type
}
import ceylon.language.meta.model {
    Type
}

import com.athaydes.specks {
    success,
    Success,
    errorCheck
}
import com.athaydes.specks.matcher {
    identicalTo,
    toBe,
    Matcher,
    sameAs
}

"The result of making an assertion."
shared alias AssertionResult => AssertionFailure | Success;

"The result of a failed assertion"
shared alias AssertionFailure => String;

"Express an expectation that the actual value should match some condition
 according to the given matcher.

 For example, if you expect a value to be 5 and to exist (ie. not to be null):

     expect(actual, toBe(equalTo(5)));
     expect(actual, to(exist));
 "
shared AssertionResult expect<Element>(Element actual, Matcher<Element> matcher)
        => matcher.matches(actual);

"Expect that a condition evaluates to true.

 This is a shortcut for:

 <code>
     expect(expectedToBeTrue, toBe(identicalTo(true)));
 </code>"
shared AssertionResult expectCondition(Boolean expectedToBeTrue)
        => expect(expectedToBeTrue, toBe(identicalTo(true)));

<<<<<<< HEAD
"Platform independent name of a Throwable"
=======
"Platform independent name of an Exception"
>>>>>>> upstream/master
shared String platformIndependentName(Type<Throwable>|Throwable exception) =>
        exception.string.replace("::", ".");

"A value to signal \"no comparison should be done\" in an assertion"
shared object noCheck {}

"Creates an assertion that is successful only if a `when` function throws a [[Throwable]]
<<<<<<< HEAD
 with exactly the [[expectedType]].
 
 If the type check passes and parameter `message` is a String or `null`, the message of the `result` Throwable
 must match that value for the assertion to be successful. The message is not checked if the `message` parameter is
 set to `noCheck` (the default value).

 This assertion is commonly used with the [[errorCheck]] block."
see(`function errorCheck`)
shared AssertionResult expectToThrow(Type<Throwable> expectedType, String? | \InoCheck message = noCheck)(Throwable? result) {

    AssertionResult verifyActualException(Throwable result) {
        if (type(result).exactly(expectedType)) {
            if (is \InoCheck message) {
                return success;
            }
            return sameAs(message).matches(result.message);
=======
 with the [[expectedType]], or a subtype of it.

 This assertion is commonly used with the [[errorCheck]] block."
see(`function errorCheck`)
shared AssertionResult expectToThrow(Type<Throwable> expectedType)(Throwable? result) {

    AssertionResult verifyActualException(Throwable result) {
        if (type(result).subtypeOf(expectedType)) {
            return success;
>>>>>>> upstream/master
        } else {
            value resultType = platformIndependentName(result);
            value expectedTypeName = platformIndependentName(expectedType);
            return "expected ``expectedTypeName`` but threw ``resultType``";
        }
    }

    if (exists result) {
        return verifyActualException(result);
    } else {
        return "no Exception thrown";
    }
}


