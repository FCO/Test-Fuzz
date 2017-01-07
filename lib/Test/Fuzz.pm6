unit module Test::Fuzz;
use Test::Fuzz::Generators;
use Test::Fuzz::Fuzzed;

my Routine %funcs;

our sub add-func(Routine $f) {
	%funcs.push: $f.name => $f
}

multi trait_mod:<is> (Routine $func, :$fuzzed! (:$returns, :&test)) is export {
	$func does Test::Fuzz::Fuzzed[:$returns, :&test];
	$func.compose;
	add-func $func
}

multi trait_mod:<is> (Routine $func, :$fuzzed!) is export {
	$func does Test::Fuzz::Fuzzed;
	$func.compose;
	add-func $func
}

sub run-tests(@funcs = %funcs.keys.sort) is export {
	for %funcs{@funcs}:v -> +@f {
		@f>>.run-tests
	}
}
