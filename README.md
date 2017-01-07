[![Build Status](https://travis-ci.org/FCO/Test-Fuzz.svg?branch=master)](https://travis-ci.org/FCO/Test-Fuzz)

[https://perl6advent.wordpress.com/2016/12/22/day-22-generative-testing/]()

```perl6
use lib ".";
use Test::Fuzz;

sub bla (Int $bla, Int $ble --> UInt) is fuzzed {
	$bla + $ble
}

sub ble (Int $ble) is fuzzed {
	die "it is prime!" if $ble.is-prime
}

multi MAIN(Bool :$fuzz!) {
	run-tests
}
```
