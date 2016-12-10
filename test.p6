use lib ".";
use Test::Fuzz;

sub bla (Int $bla, Int $ble --> UInt) is fuzzed {
	$bla + $ble
}

sub ble (Int $ble) is fuzzed {
	die "it is prime!" if $ble.is-prime
}

sub bli (Int $bli) is fuzzed(:counter(3)) {}

sub blo (UInt $blo) is fuzzed({counter => 5, test => not *.is-prime}) {
	return $blo
}

subset Prime of UInt where *.is-prime;

fuzz-generator("Prime") = (^Inf).grep: *.is-prime;

sub blu (Prime $blu) is fuzzed({test => not *.is-prime}) {
	return $blu * $blu
}

multi MAIN(Bool :$fuzz!) {
	Test::Fuzz.run-tests
}

multi MAIN {
	say bla(1, 2);
	ble(4);
	bli(42);
	say blo(42);
}
