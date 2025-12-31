=begin pod

=head1 Test::Fuzz

This module performs
L<generative testing|https://perl6advent.wordpress.com/2016/12/22/day-22-generative-testing/> on
Raku functions.

=head2 INSTALL

Install with:

    zef install Test::Fuzz

=head2 Synopsis

=begin code

use Test::Fuzz;

sub bla(Int $bla, Int $ble --> UInt) is fuzzed {
	$bla + $ble
}

sub ble(Int $ble) is fuzzed {
	die "it is prime!" if $ble.is-prime
}

sub bli(Str :$bli) is fuzzed {
	die "it's too long" unless $bli.chars < 10
}

sub blo("test") is fuzzed {
	"ok"
}

sub blu(Str $blu) {
	"ok";
}

fuzz &blu;

multi MAIN(Bool :$fuzz!) {
	run-tests
}

=end code

=head2 Description

C<Test::Fuzz> is a tool for L<C<fuzzing> or C<generative/fuzz> testing|https://en.wikipedia.org/wiki/Fuzzing>.

Add the C<is fuzzed> trait to a method or function and C<Test::Fuzz>
will try to figure out the best generators to use to test your
function. If the function was already created without this trait, pass it to the C<fuzz> function for the same effect.

To run the tests, just call the C<run-tests> function.

=head2 INSTALLATION

=begin code
    # with zef
    > zef install Test::Fuzz

    # or, with 6pm (https://github.com/FCO/6pm)
    > $ 6pm install Test::Fuzz
=end code

=end pod

unit module Test::Fuzz;
use Test::Fuzz::Generators;
use Test::Fuzz::Fuzzed;

my %funcs;

our sub add-func(Routine $f) {
	%funcs.push: $f.name => $f
}

#| trait is fuzzed can receive params :returns and :test
multi trait_mod:<is> (Routine $func,
		:$fuzzed! where Map|List (:$returns, :&test)
) is export {
	$func does Test::Fuzz::Fuzzed[:$returns, :&test];
	$func.compose;
	add-func $func
}

#| trait is fuzzed
multi trait_mod:<is> (Routine $func, Bool :$fuzzed!) is export {
	$func does Test::Fuzz::Fuzzed;
	$func.compose;
	add-func $func
}

#| fuzz an existing sub
sub fuzz(&func) is export {
	for (&func.candidates) -> $f {
		&trait_mod:<is>($f, :fuzzed);
	}
}

#| function that run fuzzed tests
sub run-tests(
	@funcs = %funcs.keys.sort, #= if no specified the functions, it runs all fuzzed tests
	Int :$runs #The number of tests to run.
	--> Nil
) is export {
		(%funcs{@funcs}:v)».run-tests: |($_ with $runs)
}
