use lib ".";
use Test::Fuzz;

#`{{{
sub bla (Int $bla, Int $ble --> UInt) is fuzzed {
	$bla + $ble
}

sub bla2 (Int:D $bla, Int:D $ble --> UInt) is fuzzed {
	$bla + $ble
}

sub ble (Int $ble) is fuzzed {
	die "it is prime!" if $ble.is-prime
}

sub bli (Int $bli) is fuzzed(:counter(3)) {}

sub blo (UInt $blo) is fuzzed({counter => 5, test => not *.is-prime, generators => [UInt]}) {
	return $blo
}

subset Prime of UInt where *.is-prime;

fuzz-generator("Prime") = (^Inf).grep: *.is-prime;

sub blu (Prime $blu) is fuzzed({counter => 5, test => not *.is-prime, generators => ["Prime"]}) {
	return $blu * $blu
}
}}}

sub bla (Int $bla, Int:D $ble --> Int) is fuzzed {
	die unless $bla.defined;
	$bla + $ble
}

#`{{{
class Bla is Any {
	method ble(Int $a) is fuzzed {
		die "Morreu!"
	}
}
}}}

Test::Fuzz.run-tests
