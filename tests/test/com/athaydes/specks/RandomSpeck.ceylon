import ceylon.collection {
    HashSet,
    unlinked,
    Hashtable
}
import ceylon.test {
    testExecutor,
    test
}

import com.athaydes.specks {
    SpecksTestExecutor,
    Specification,
    feature,
    randomIntegers,
    success
}
import com.athaydes.specks.assertion {
    expect,
    AssertionResult
}
import com.athaydes.specks.matcher {
    toBe,
    largerThan,
    smallerThan,
    containEvery,
    to
}

[Integer[]+] partition({Integer*} ints, Integer partitionsCount, variable Integer low, Integer partitionWidth) {
    variable value high = low + partitionWidth;
    value partitions = (1..partitionsCount).collect((_) {
            value part = ints.select((element) => low <= element < high);
            low += partitionWidth;
            high += partitionWidth;
            return part;
        });
    return partitions;
}

Value nonNull<Value>(Value? val)
        given Value satisfies Object {
    assert (exists val);
    return val;
}

AssertionResult naturalDistribution({Integer*} ints, Integer min = -(2 ^ 53), Integer partitionWidth = 2 ^ 50) {
    value partitions = partition(ints, 16, min, partitionWidth);
    
    variable Integer left = 0;
    variable Integer right = partitions.size - 1;
    
    while (left < right) {
        value rightPartitionSize = nonNull(partitions[right]?.size).float;
        value leftPartitionSize = nonNull(partitions[left]?.size).float;
        
        if (rightPartitionSize < 0.9*leftPartitionSize ||
                    rightPartitionSize > 1.1*leftPartitionSize) {
            return "Natural distribution - FAIL: Partitions not naturally distributed: ``partitions.map((it) => it.size)``";
        }
        left++;
        right--;
    }
    
    value partitionsItems = sum(partitions*.size);
    if (partitionsItems != ints.size) {
        return "Natural distribution - FAIL: Expected ``ints.size`` total integers in all partitions but found ``partitionsItems``";
    }
    return success;
}

AssertionResult uniformDistribution({Integer*} ints, Integer min = -2^52, Integer width = 2^48) {
    value partitions = partition(ints, 16, min, width);
    
    value tolerance = 0.05;
    value minPartitionSize = (1.0 - tolerance) * partitions.first.size;
    value maxPartitionSize = (1.0 + tolerance) * partitions.first.size;
    
    for (partition in partitions.rest) {
        if (partition.size.float<minPartitionSize ||
                    partition.size.float>maxPartitionSize) {
            return "Uniform distribution - FAIL: Partitions not uniformly distributed: ``partitions.map((it) => it.size)``";
        }
    }
    value partitionsItems = sum(partitions*.size);
    if (partitionsItems != ints.size) {
        return "Natural distribution - FAIL: Expected ``ints.size`` total integers in all partitions but found ``partitionsItems``";
    }
    return success;
}

Integer uniqueElements(Object[] elements) {
    value set = HashSet(unlinked, Hashtable((elements.size / 0.75).integer + 1), elements);
    return set.size;
}

{Integer*} successiveDiff({Integer*} ints) {
    if (exists first = ints.first) {
        variable value prev = first;
        return ints.rest.map((it) {
            value result = it - prev;
            prev = it;
            return result;
        });    
    } else {
        return empty;
    }
}

testExecutor (`class SpecksTestExecutor`)
class RandomSpeck() {

    shared test
    Specification randomIntegersReturnsApparentlyRandomValues() => Specification {
        feature {
            description = "Random integers span the whole range of expected values";
            when () => randomIntegers(10k, 1, 100).sequence();
            (Integer* testIntegers) => expect(testIntegers, to(containEvery(1..100)))()
        },
        feature {
            description = "Random integers are generated with uniform distribution";
            when() => randomIntegers(100k, -2^52, 2^52).sequence();
            (Integer* testIntegers) => uniformDistribution(testIntegers)
        },
        feature {
            description = "The difference between successive values has natural distribution";
            when() => randomIntegers(100k, -2^52, 2^52).sequence();
            (Integer* testIntegers) => naturalDistribution(successiveDiff(testIntegers))
        },
        feature {
            description = "Nearly no repitition within a million integers";
            when() => randomIntegers(1M, -2^52, 2^52).sequence();
            (Integer* testIntegers) => expect(uniqueElements(testIntegers),
                    toBe(largerThan(1M - 5), smallerThan(1M + 5)))()
        }
    };
}
