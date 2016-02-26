import ceylon.random {
    Random,
    DefaultRandom
}

Random defaultRandom = DefaultRandom();

"Generates a range of integers within the given bounds.

 The integers are not random and depend only on the values of count and the bounds.
 The generated values are appropriate for tests - an attempt is made
 to include boundary values and uniformly distribute the values."
throws(`class Exception`, "if count is smaller than 1 or lowerBound > higherBound")
shared {Integer+} rangeOfIntegers(
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

    Integer step = (higherBound - lowerBound) / (count - 1);

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
            Integer result = current;
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


"Generates pseudo-random integers within the given bounds."
throws(`class Exception`, "if count is smaller than 1 or lowerBound > higherBound")
shared {Integer+} randomIntegers(
	"the number of integers to generate - must be positive"
	Integer count = 100,
	"the lower bound, or lowest value that should be generated"
	Integer lowerBound = -1M,
	"the higher bound, or maximum value that should be generated"
	Integer higherBound = 1M,
	"Random instance to use for generating Integers"
	Random random = defaultRandom) {

	if (count < 1) {
		throw Exception("Count must be positive");
	}
	if (lowerBound > higherBound) {
		throw Exception("Lower bound must not be larger than higher bound");
	}

	return let (samples = count) object satisfies {Integer+} {
		value result = { lowerBound + random.nextInteger(higherBound - lowerBound) }
				.cycled.take(samples);
				iterator = result.iterator;
			};
		}


"Generates pseudo-random Floats within the given bounds."
throws(`class Exception`, "if count is smaller than 1 or lowerBound > higherBound")
shared {Float+} randomFloats(
    "the number of Floats to generate - must be positive"
    Integer count = 100,
    "the lower bound, or lowest value that should be generated"
    Float lowerBound = -1.0M,
    "the higher bound, or maximum value that should be generated"
    Float higherBound = 1.0M,
    "Random instance to use for generating Floats"
    Random random = defaultRandom) {

    if (count < 1) {
        throw Exception("Count must be positive");
    }
    if (lowerBound > higherBound) {
        throw Exception("Lower bound must not be larger than higher bound");
    }

    return let (samples = count) object satisfies {Float+} {
        value totalRange = (higherBound - lowerBound).magnitude;
        value result = { lowerBound + (random.nextFloat() * totalRange ) }
                .cycled.take(samples);
        iterator = result.iterator;
    };
}

"Generates pseudo-random Boolean values."
throws(`class Exception`, "if count is smaller than 1")
shared {Boolean+} randomBooleans(
	"the number of Booleans to generate - must be positive"
	Integer count = 100,
	"Random instance to use for generating Booleans"
	Random random = defaultRandom) {

	if (count < 1) {
		throw Exception("Count must be positive");
	}

	return { random.nextBoolean() }.chain(
		{ random.nextBoolean() }.cycled.take(count - 1));
}

"Generates pseudo-random Strings."
throws(`class Exception`, "if count is smaller than 1 or longest < shortest")
shared {String+} randomStrings(
    "the number of Strings to generate - must be positive"
    Integer count = 100,
    "the lower bound for the String size"
    Integer shortest = 0,
    "the higher bound for the String size"
    Integer longest = 100,
    "Allowed characters for the returned Strings"
    [Character+] allowedCharacters = '\{#20}'..'\{#7E}',
    "Random instance to use for generating Strings"
    Random random = defaultRandom) {

    if (count < 1) {
        throw Exception("Count must be positive");
    }
    if (longest < shortest) {
        throw Exception("longest must not be smaller than shortest");
    }

    String randomString() {
        Integer checkedShortest = max{ 0, shortest };
        Integer maxBound = longest - checkedShortest;
        Integer size = checkedShortest + random.nextInteger(maxBound + 1);
        if (size == 0) { return ""; }
        return String(random.elements(allowedCharacters).take(size));
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
