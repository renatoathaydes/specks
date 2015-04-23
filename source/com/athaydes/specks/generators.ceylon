
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

"Generates random Integers."
throws(`class Exception`, "if count is smaller than 1 or longest < shortest")
shared {Integer+} randomIntegers(
    "the number of Integers to generate - must be positive"
    Integer count = 100,
    "the lower bound for the Integers generated"
    Integer lower = 0,
    "the higher bound for the Integers generated"
    Integer higher = 100) {
    
    value random = Random();
    
    if (count < 1) {
        throw Exception("Count must be positive");
    }
    if (higher < lower) {
        throw Exception("longest must not be smaller than shortest");
    }
    
    function randomInteger() => random.nextInRange(lower, higher + 1);
    
    if (count == 1) { return { randomInteger() }; }
    
    return GeneratorIterator(count, randomInteger);
}



"Generates random Strings."
throws(`class Exception`, "if count is smaller than 1 or longest < shortest")
shared {String+} randomStrings(
    "the number of Strings to generate - must be positive"
    Integer count = 100,
    "the lower bound for the String size"
    Integer shortest = 0,
    "the higher bound for the String size"
    Integer longest = 100,
    "Allowed characters for the returned Strings"
    [Character+] allowedChars = '\{#20}'..'\{#7E}') {
    
    value random = Random();
    
    if (count < 1) {
        throw Exception("Count must be positive");
    }
    if (longest < shortest) {
        throw Exception("longest must not be smaller than shortest");
    }
    
    function randomString() {
        value length = random.nextInRange(shortest, longest);
        return String((1..length).collect((_)
            => allowedChars[random.nextPositive(allowedChars.size)]).coalesced);
    }
    
    if (count == 1) { return { randomString() }; }
    
    return GeneratorIterator(count, randomString);
}

class GeneratorIterator<Item>(Integer count, Item() generate)
        satisfies {Item+} {
    
    variable Integer itemsLeft = count;
    
    Item|Finished increase() {
        if (itemsLeft == 0) {
            return finished;
        }
        
        itemsLeft--;
        return generate();
    }
    
    size = count;
    
    shared actual Iterator<Item> iterator() => iter;
    
    object iter satisfies Iterator<Item> {
        shared actual Item|Finished next() => increase();
    }
    
}
