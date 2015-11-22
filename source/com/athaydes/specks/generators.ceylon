import com.vasileff.ceylon.random.api {
	Random,
	LCGRandom
}

"Generates a range of integers within the given bounds.

 The integers are not random and depend only on the values of count and the bounds.
 The generated values are appropriate for tests - an attempt is made
 to include boundary values and uniformly distribute the values."
throws(`class Exception`, "if count is smaller than 1 or lowerBound > higherBound")
shared {Integer+} generateIntegers(
    "the number of integers to generate - must be positive"
    Integer count = 100,
    "the lower bound, or lowest value that should be generated"
    Integer lowerBound = -1M,
    "the higher bound, or maximum value that should be generated"
    Integer higherBound = 1M) {
    if (count < 1) {
        throw Exception("Count must be positive");
    }
    if (lowerBound > higherBound) {
        throw Exception("Lower bound must not be larger than higher bound");
    }
    if (count == 1) { return { lowerBound < 0 < higherBound then 0 else lowerBound }; }
    
    value step = (higherBound - lowerBound) / (count - 1);
    
    class IntsIterator(Integer count) satisfies {Integer+} {
        
        variable Integer itemsLeft = count;
        variable Integer current = lowerBound;
        
        Integer|Finished increase() {
            if (itemsLeft == 0) {
                return finished;
            }
            if (itemsLeft-- == 1) {
                return higherBound;
            }
            value result = current;
            current += step;
            return result;
        }
        
        size = count;
        
        shared actual Iterator<Integer> iterator() => iter;
        
        object iter satisfies Iterator<Integer> {
            shared actual Integer|Finished next() => increase();
        }
    }
    
    return IntsIterator(count);
}

"Generates random Strings."
throws(`class Exception`, "if count is smaller than 1 or longest < shortest")
shared {String+} generateStrings(
    "the number of Strings to generate - must be positive"
    Integer count = 100,
    "the lower bound for the String size"
    Integer shortest = 0,
    "the higher bound for the String size"
    Integer longest = 100,
    "Allowed characters for the returned Strings"
    [Character+] allowedChars = '\{#20}'..'\{#7E}',
    "Random instance to use for generating Strings"
    Random random = LCGRandom()) {
    
    if (count < 1) {
        throw Exception("Count must be positive");
    }
    if (longest < shortest) {
        throw Exception("longest must not be smaller than shortest");
    }
    
    function randomString() {
        value checkedShortest = max{ 0, shortest };
        value maxBound = longest - checkedShortest;
        value size = checkedShortest + random.nextInteger(maxBound + 1);
        if (size == 0) { return ""; }
        return String(random.elements(allowedChars).take(size));
    }
    
    if (count == 1) { return { randomString() }; }
    
    class StringsIterator(Integer count) satisfies {String+} {
        
        variable Integer itemsLeft = count;
        
        String|Finished increase() {
            if (itemsLeft == 0) {
                return finished;
            }
            
            itemsLeft--;
            return randomString();
        }
        
        size = count;
        
        shared actual Iterator<String> iterator() => iter;
        
        object iter satisfies Iterator<String> {
            shared actual String|Finished next() => increase();
        }
    }
    
    return StringsIterator(count);
}

