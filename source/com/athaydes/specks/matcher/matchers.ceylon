import com.athaydes.specks {
    success
}
import com.athaydes.specks.assertion {
    AssertionResult
}

"Base class of all **specks** matchers.
 
 A matcher can be used to verify that a value matches some expected result."
shared interface Matcher<Element> {
    
    "Checks if the actual value matches an expected value or condition."
    shared formal AssertionResult matches(Element actual);
    
}

"A utility matcher that may be combined with other matchers to make a combined matcher
 or just make expectations more readable, as in:
 
 <code>
     expect(actual, to(exist));
     expect([1,2,3], to(contain(3)));
 </code>"
shared Matcher<Element> to<Element>(Matcher<Element>+ wrappedMatchers)
        => AndMatcher<Element>(*wrappedMatchers);

"An alias for [[to]].
 
 Example usage:
 
 <code>
     expect(actual, toBe(equalTo(a), largerThan(b));
 </code>"
shared Matcher<Element> toBe<Element>(Matcher<Element>+ wrappedMatchers)
        => to(*wrappedMatchers);

"A utility matcher that reverses the result of another matcher, as in:
 
 <code>
     expect(actual, not(to(exist)));
     expect([1,2,3], not(to(contain(10))));
 </code>"
shared Matcher<Element> not<Element>(Matcher<Element> wrappedMatcher)
        => WrapperMatcher { wrappedMatcher; reverseResult = true; };

"A matcher that succeeds only if the actual value is larger than the expected value"
shared Matcher<Element> largerThan<Element>(Element expected)
        given Element satisfies Comparable<Element>
        => ComparisonMatcher(expected, larger);

"A matcher that succeeds only if the actual value is smaller than the expected value"
shared Matcher<Element> smallerThan<Element>(Element expected)
        given Element satisfies Comparable<Element>
        => ComparisonMatcher(expected, smaller);

"A matcher that succeeds only if the actual value is, at most, the expected value
 (in other words, the actual value must not be larger than the expected value)"
shared Matcher<Element> atMost<Element>(Element expected)
        given Element satisfies Comparable<Element>
        => not(largerThan(expected));

"A matcher that succeeds only if the actual value is, at least, the expected value
 (in other words, the actual value must not be smaller than the expected value)"
shared Matcher<Element> atLeast<Element>(Element expected)
        given Element satisfies Comparable<Element>
        => not(smallerThan(expected));

"A matcher that succeeds only if the actual value exists, ie. the expected value is not null."
shared Matcher<Anything> exist = ExistenceMatcher { mustExist = true; };

"A matcher that succeeds only if the actual value is equal to the expected value,
 when compared with the [[Comparable.compare]] method."
see(`function identicalTo`)
shared Matcher<Element> equalTo<Element>(Element expected)
        given Element satisfies Comparable<Element>&Object
        => ComparisonMatcher(expected, equal);

"A matcher that succeeds only if the actual value is the same as the expected value,
 where 'the same' means:
 * expected and actual are both null.
 * expected == actual."
see(`function identicalTo`)
shared Matcher<Anything> sameAs(Anything expected)
        => SamenessMatcher(expected);

"A matcher that succeeds only if the actual value **is** the expected value when compared
 by identity (see [[Identifiable]]).
 
 Example:
 
 <code>
     expect(1, toBe(identicalTo(1)));
 </code>"
see(`function equalTo`, `interface Identifiable`)
shared Matcher<Element> identicalTo<Element>(Element expected)
        given Element satisfies Identifiable
        => IdentityMatcher(expected);

"A matcher that succeeds only if the actual Iterable is empty."
shared Matcher<{Anything*}> empty
        = EmptyMatcher<{Anything*}>();

"A matcher that succeeds only if the actual Iterable has the expected size."
shared Matcher<{Anything*}> haveSize(Integer expectedSize)
        => HasSizeMatcher<{Anything*}>(expectedSize);

"A matcher that succeeds only if the given element is part of a [[Category]].
 
 Example:
 
 <code>
     expect([1,2,3], to(contain(3)));
 </code>"
shared Matcher<{Element*}> contain<Element>(Element element)
        given Element satisfies Object
        => ContainsMatcher<Element>(element);

"A matcher that succeeds only if every one of the given elements are part of a [[Category]].
 
 Example:
 
 <code>
     expect('a'..'z', to(containEvery('x'..'z')));
 </code>"
see(`function Category.containsEvery`)
shared Matcher<{Element*}> containEvery<Element>({Element*} elements)
        given Element satisfies Object
        => ContainsEveryMatcher<Element>(elements);

"A matcher that succeeds only if at least one of the given elements are part of a [[Category]].
 
 Example:
 
 <code>
     expect('a'..'z', to(containAny('x'..'z')));
 </code>"
see(`function Category.containsAny`)
shared Matcher<{Element*}> containAny<Element>({Element*} elements)
        given Element satisfies Object
        => ContainsAnyMatcher<Element>(elements);

"A matcher that succeeds only if the actual collection contains exactly the same elements
 as the given Sequence.
 
 Examples:
 
 <code>
     // this succeeds
     expect('1'..'4', to(containSameAs([1, 2, 3, 4])));
 
     // this will fail
     expect('4'..'1', to(containSameAs([1, 2, 3, 4])));
 </code>"
shared Matcher<{Element*}> containSameAs<Element>({Element*} elements)
        given Element satisfies Object
        => ContainsSameElementsMatcher<Element>(elements);

"A matcher that succeeds only if the actual collection contains only elements
 also present in the given iterable.
 
 Examples:
 
 <code>
     expect(('1'..'100').map((i) => i % 2), to(containOnly(0, 1)));
 </code>"
shared Matcher<{Element*}> containOnly<Element>(Element* elements)
        given Element satisfies Object
        => ContainsOnlyMatcher<Element>(elements);

/**************** Matcher implementation classes ********************/

class AndMatcher<Element>(Matcher<Element>+ matchers)
        satisfies Matcher<Element> {
    
    shared actual AssertionResult matches(Element actual) {
        for (matcher in matchers) {
            value result = matcher.matches(actual);
            if (exists result) {
                return result;
            }
        }
        return success;
    }
    
}

class WrapperMatcher<Element>(Matcher<Element> wrappedMatcher, Boolean reverseResult)
        satisfies Matcher<Element> {
    
    shared actual AssertionResult matches(Element actual) {
        value result = wrappedMatcher.matches(actual);
        if (reverseResult) {
            if (is Null result) {
                return "should have failed";
            } else {
                return success;
            }
        } else {
            return result;
        }
    }
    
}

class ExistenceMatcher(Boolean mustExist)
        satisfies Matcher<Anything> {
    
    shared actual AssertionResult matches(Anything actual) {
        if (exists actual, !mustExist) {
            return "expected to be null, but exists: ``actual``";
        } else if (is Null actual, mustExist) {
            return "expected to exist but was null";
        }
        return success;
    }
    
}

class SamenessMatcher(Anything expected)
        satisfies Matcher<Anything> {

    shared actual AssertionResult matches(Anything actual) {
        if (exists expected, exists actual) {
            if (actual == expected) {
                return success;
            } else {
                return "``actual`` is not as expected: ``expected``";
            }
        } else if (exists actual) {
            return "Expected <null> but was ``actual``";
        } else if (exists expected) {
            return "Expected ``expected`` but was <null>";
        } else {
            return success;
        }
    }
    
}

class ComparisonMatcher<Element>(Element expected, Comparison expectedResult)
        satisfies Matcher<Element>
        given Element satisfies Comparable<Element> {
    
    shared actual AssertionResult matches(Element actual) {
        if (actual <=> expected != expectedResult) {
            return "``actual`` is not ``strFor(expectedResult)`` ``expected``";
        }
        return success;
    }
    
}

class IdentityMatcher<Element>(Element expected)
        satisfies Matcher<Element>
        given Element satisfies Identifiable {
    
    shared actual AssertionResult matches(Element actual) {
        if (! actual === expected) {
            return "expected ``expected`` but was ``actual``";
        }    
        return success;
    }
    
}

class BooleanMatcher(Boolean expected)
        satisfies Matcher<Boolean> {
    
    shared actual AssertionResult matches(Boolean actual) {
        if (actual != expected) {
            return "expected ``expected`` but got ``actual``";
        }
        return success;
    }
    
}

class EmptyMatcher<Seq>()
        satisfies Matcher<Seq>
        given Seq satisfies Iterable<Anything> {
    
    shared actual AssertionResult matches(Seq actuals) {
        if (actuals.empty) {
            return success;
        } else {
            return "iterable is not empty";
        }
    }
    
}

class HasSizeMatcher<Seq>(Integer expectedSize)
        satisfies Matcher<Seq>
        given Seq satisfies Iterable<Anything> {
    
    shared actual AssertionResult matches(Seq actuals) {
        value actualSize = actuals.size;
        if (actualSize == expectedSize) {
            return success;
        } else {
            return "expected iterable of size ``expectedSize`` but was ``actualSize``";
        }
    }
    
}


class ContainsMatcher<Element>(Element expected)
        satisfies Matcher<{Element*}>
        given Element satisfies Object {
    
    shared actual AssertionResult matches({Element*} actuals) {
        if (! expected in actuals) {
            return "element ``expected`` not in ``actuals``";
        }
        return success;
    }
    
}

class ContainsEveryMatcher<Element>({Element*} expected)
        satisfies Matcher<{Element*}>
        given Element satisfies Object {
    
    shared actual AssertionResult matches({Element*} actuals) {
        if (!actuals.containsEvery(expected)) {
            return "not all ``actuals`` are part of ``expected``";
        }
        return success;
    }
    
}

class ContainsAnyMatcher<Element>({Element*} expected)
        satisfies Matcher<{Element*}>
        given Element satisfies Object {
    
    shared actual AssertionResult matches({Element*} actuals) {
        if (!actuals.containsAny(expected)) {
            return "none of ``actuals`` is part of ``expected``";
        }
        return success;
    }
    
}

class ContainsSameElementsMatcher<Element>({Element*} expected)
        satisfies Matcher<{Element*}>
        given Element satisfies Object {
    
    shared actual AssertionResult matches({Element*} actuals) {
        if (actuals.size != expected.size) {
            return "expected Iterable of size ``expected.size``
                                      but was ``actuals.size``
                                     Actual: ``actuals``";
        }
        variable Integer index = 0;
        for (actual -> expectedItem in zipEntries(actuals, expected)) {
            if (actual != expectedItem) {
                return "element at index ``index`` should be
                                          ``expectedItem`` but was ``actual``
                                         Actual: ``actuals``";
            }
            index++;
        }
        return success;
    }
    
}

class ContainsOnlyMatcher<Element>({Element*} expected)
        satisfies Matcher<{Element*}>
        given Element satisfies Object {
    
    shared actual AssertionResult matches({Element*} actuals) {
        for (Element actual in actuals) {
            if (! actual in expected) {
                return "unexpected item '``actual``'";    
            }
        }
        return success;
    }
    
}

String strFor(Comparison key) {
    switch (key)
    case (equal) { return "equal to"; }
    case (larger) { return "larger than"; }
    case (smaller) { return "smaller than"; }
}
