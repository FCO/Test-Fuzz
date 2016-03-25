use lib ".";
use Test::Fuzz;

#sub bla (Int $bla, Int $ble --> UInt) is fuzzed {
#	$bla + $ble
#}
#
#sub ble (Int $ble) is fuzzed {
#	die "it is prime!" if $ble.is-prime
#}
#
#sub bli (Int $bli) is fuzzed(:counter(3)) {}

sub blo (UInt $blo) is fuzzed({counter => 5, test => not *.is-prime, generators => [<UInt>]}) {
	return $blo
}

multi MAIN(Bool :$fuzz!) {
	Test::Fuzz.run-tests
}
