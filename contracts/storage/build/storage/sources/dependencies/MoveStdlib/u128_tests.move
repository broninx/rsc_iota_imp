// Copyright (c) Mysten Labs, Inc.
// Modifications Copyright (c) 2024 IOTA Stiftung
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module std::u128_tests {
    use std::integer_tests;
    use std::unit_test::assert_eq;

    const BIT_SIZE: u8 = 128;
    const MAX: u128 = 0xFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
    const MAX_PRED: u128 = MAX - 1;

    const CASES: vector<u128> = vector[
        0,
        1,
        10,
        11,
        100,
        111,
        1 << (BIT_SIZE / 2 - 1),
        (1 << (BIT_SIZE / 2 - 1)) + 1,
        1 << (BIT_SIZE - 1),
        (1 << (BIT_SIZE - 1)) + 1,
        MAX / 2,
        (MAX / 2) + 1,
        MAX_PRED,
        MAX,
    ];

    #[test]
    fun test_bitwise_not() {
        integer_tests::test_bitwise_not!(MAX, CASES);
    }

    #[test]
    fun test_max() {
        integer_tests::test_max!(MAX, CASES);
    }

    #[test]
    fun test_min() {
        integer_tests::test_min!(MAX, CASES);
    }

    #[test]
    fun test_diff() {
        integer_tests::test_diff!(MAX, CASES);
    }

    #[test]
    fun test_divide_and_round_up() {
        integer_tests::test_divide_and_round_up!(MAX, CASES);
    }

    #[test, expected_failure(arithmetic_error, location = std::u8)]
    fun test_divide_and_round_up_error() {
        1u8.divide_and_round_up(0);
    }

    #[test]
    fun test_pow() {
        integer_tests::test_pow!(MAX, CASES);
        assert_eq!(2u128.pow(12), integer_tests::slow_pow!(2u128, 12));
        assert_eq!(3u128.pow(27), integer_tests::slow_pow!(3u128, 27));
    }

    #[test, expected_failure(arithmetic_error, location = std::u16)]
    fun test_pow_overflow() {
        255u16.pow(255);
    }

    #[test]
    fun test_sqrt() {
        let reflexive_cases =
            vector[0, 2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32, 35, 38, 41, 44, 47, 50, 53, 56, 59];
        integer_tests::test_sqrt!(MAX, CASES, reflexive_cases)
    }

    #[test]
    fun test_try_as_u8() {
        integer_tests::test_try_as_u8!<u128>(MAX);
    }

    #[test]
    fun test_try_as_u16() {
        integer_tests::test_try_as_u16!<u128>(MAX);
    }

    #[test]
    fun test_try_as_u32() {
        integer_tests::test_try_as_u32!<u128>(MAX);
    }

    #[test]
    fun test_try_as_u64() {
        integer_tests::test_try_as_u64!<u128>(MAX);
    }

    #[test]
    fun test_to_string() {
        integer_tests::test_to_string!<u128>();
        assert_eq!((MAX / 2).to_string(), b"170141183460469231731687303715884105727".to_string());
        assert_eq!((MAX / 2 + 1).to_string(), b"170141183460469231731687303715884105728".to_string());
        assert_eq!(MAX_PRED.to_string(), b"340282366920938463463374607431768211454".to_string());
        assert_eq!(MAX.to_string(), b"340282366920938463463374607431768211455".to_string());
    }
    
    #[test]
    fun test_dos() {
        integer_tests::test_dos!(MAX, CASES);
    }
}
