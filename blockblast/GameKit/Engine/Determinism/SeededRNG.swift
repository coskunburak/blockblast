import Foundation

struct SeededRNG {
    private(set) var seed: UInt64

    mutating func next() -> UInt64 {
        var x = seed
        x ^= x >> 12
        x ^= x << 25
        x ^= x >> 27
        seed = x
        return x &* 2685821657736338717
    }
}
