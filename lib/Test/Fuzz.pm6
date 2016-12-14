use Test;
use Test::Fuzz::Generators;

my Iterable %generator;

multi fuzz-generator(::Type) is export is rw {
	%generator{Type.^name};
}

multi fuzz-generator(Str \type) is export is rw {
	%generator{type};
}

for Test::Fuzz::Generators.generators -> (:$key, :@value) {
	fuzz-generator($key) = @value
}

class Test::Fuzz {...}
my $instance;
INIT $instance = Test::Fuzz.bless;
class Test::Fuzz {
	class Fuzzer {
		has				$.name;
		has 			@.data;
		has Callable	$.get-data;
		has Block		$.func;
		has 			$.returns;
		has Callable	$.test;

		#method run() is hidden-from-backtrace {
		method run() {
			subtest {
				@!data = $.get-data.() unless @!data;
				for @.data -> @data {
					my $return = $.func.(|@data);
					$return.exception.throw if $return ~~ Failure;
					CATCH {
						default {
							lives-ok {
								.throw
							}, "{ $.name }({ @data.map({.defined ?? $_ !! "({ $_.^name })"}).join(", ") })"
						}
					}
					if $!test.defined and not $!test($return) {
						flunk "{ $.name }({ @data.map(*.perl).join(", ") })"
					}
					pass "{ $.name }({ @data.map(*.perl).join(", ") })"
				}
			}, $.name
		}
	}
	method new {!!!}
	method instance(::?CLASS:U:) {
		$instance
	}
	has Fuzzer %.fuzzers;

	method fuzz(::?CLASS:D: Routine $func, Int() :$counter = 100, Callable :$test, :@generators is copy) is export {
		if @generators {
			@generators .= map: { ($^type || $^type.^name), all() };
		} else {
			@generators = $func.signature.params.map({:type(.type.^name ~ .modifier), :constraints(.constraints)})
		}
		my $get-data = sub {
			do if $func.signature.params.elems > 0 {
				do if $func.signature.params.elems == 1 {
					with @generators[0] -> (:$type, :$constraints) {
						$?CLASS.generate($type, $constraints, $counter).map: -> $item {[$item]}
					}
				} else {
					([X] @generators.map(-> (:$type, :$constraints) {
						$?CLASS.generate($type, $constraints, $counter)
					}))
				}.pick: $counter
			} else {
				Empty
			}
		};

		my $name	= $func.name;
		my $returns	= $func.signature.returns;

		%!fuzzers.push($name => Fuzzer.new(:$name, :$func, :$get-data, :$returns, :$test));
	}

	method generate(Test::Fuzz:U: Str \type, Mu:D $constraints, Int $size) {
		my Mu @ret;
		my Mu @undefined;
		my $type = type ~~ /^^
			$<type>	= (\w+)
			[
				':'
				$<def>	= (<[UD]>)
			]?
		$$/;
		my \test-type		= ::(~$type<type>);
		my $loaded-types	= set |::.values.grep(not *.defined);
		my $builtin-types	= set |%?RESOURCES<classes>.IO.lines.map({::($_)});
		my $types			= $loaded-types ∪ $builtin-types;
		#my $types			= $builtin-types;
		my @types			= $types.keys.grep(sub (Mu \item) {
			my Mu:U \i = item;
			return so i ~~ test-type;
			CATCH {return False}
		});
		@undefined = @types.grep(sub (Mu \item) {
			my Mu:U \i = item;
			return so i ~~ $constraints;
			CATCH {return False}
		}) if not $type<def>.defined or ~$type<def> eq "U";
		my %indexes := BagHash.new;
		my %gens := @types.map(*.^name) ∩ %generator.keys;
		while @ret.elems < $size {
			for %gens.keys -> $sub {
				my $item = %generator{$sub}[%indexes{$sub}++];
				@ret.push: $item if $item ~~ test-type & $constraints;
			}
		}
		@ret.unshift: |@undefined if @undefined;
		@ret
	}

	method run-tests(::?CLASS:D: +@funcs is copy) {
		@funcs = %!fuzzers.keys.sort if @funcs.elems == 0;
		for %!fuzzers{@funcs}.map(|*) -> $fuzz {
			$fuzz.run
		}
	}
}

multi trait_mod:<is> (Routine $func, :%fuzzed!) is export {
	Test::Fuzz.instance.fuzz($func, |%fuzzed);
}

multi trait_mod:<is> (Routine $func, :$fuzzed!) is export {
	Test::Fuzz.instance.fuzz($func);
}

