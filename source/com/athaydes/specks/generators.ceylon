"Generates a number of integers.

 The integers are not random and depend only on the value of count.
 The generated values are appropriate for tests - an attempt is made
 to include boundary values and uniformly distribute the values."
throws(`class Exception`, "if count is smaller than 1")
shared {Integer+} generateIntegers(
    "the number of integers to generate - must be positive"
    Integer count = 100) {

    if (count < 1) {
        throw Exception("Count must be positive");
    }
    if (count == 1) { return { 0 }; }
    value first = -9P; // near -2^53, the limit in JavaScript
    value last = 9P;
    return (first..last).by((last - first) / (count - 1));

}
