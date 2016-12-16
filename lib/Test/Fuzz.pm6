use Test::Fuzz::Generators;
use Test::Fuzz::Fuzzed;

my Routine %funcs;

multi trait_mod:<is> (Routine $func, :$fuzzed! (:$returns, :&test)) is export {
	$func does Test::Fuzz::Fuzzed[:$returns, :&test];
	$func.compose;
	%funcs.push: $func.name => $func
}

multi trait_mod:<is> (Routine $func, :$fuzzed!) is export {
	$func does Test::Fuzz::Fuzzed;
	$func.compose;
	%funcs.push: $func.name => $func
}

sub run-tests(@funcs = %funcs.keys.sort) is export {
	for %funcs{@funcs}:v -> +@f {
		@f>>.run-tests
	}
}
