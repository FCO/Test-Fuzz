use Test;
class Test::Fuzz {
	class Fuzzer {
		has				$.name;
		has 			@.data;
		has Callable	$.get-data;
		has Block		$.func;
		has 			$.returns;
		has Callable	$.test;

		method run() is hidden-from-backtrace {
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
						flunk "{ $.name }({ @data.join(", ") })"
					}
					pass "{ $.name }({ @data.join(", ") })"
				}
			}, $.name
		}
	}

	my Iterable %generator;

	multi fuzz-generator(Str \type) is export is rw {
		%generator{type};
	}

	multi fuzz-generator(::Type) is export is rw {
		%generator{Type.^name};
	}

	fuzz-generator(UInt) = gather {
		take UInt;
		take 0;
		take 1;
		take 3;
		take 9999999999;
		take $_ for (^10000000000).roll(*)
	};

	fuzz-generator(Int)	= gather {
		take Int;
		for @( %generator<UInt> ).grep({.defined}) -> $int {
			take $int;
			take -$int unless $int == 0;
		}
	};

	fuzz-generator(Int:D)	= @( %generator<Int> ).grep({.defined});

	fuzz-generator(Int:U)	= gather loop {take Int};

	my Fuzzer @fuzzers;

	sub fuzz(Routine $func, Int() :$counter = 100, Callable :$test, :@generators is copy) is export {
		if @generators {
			@generators .= map: { $^type || $^type.^name };
		} else {
			@generators = $func.signature.params.map({.type.^name ~ .modifier})
		}
		my $get-data = sub {
			my @data = ([X] @generators.map(-> \type {
				$?CLASS.generate(type, $counter)
			}))[^$counter];
			if @generators.elems <= 1 {
				@data = @data[0].map(-> $item {[$item]});
			}
			@data
		};

		my $name	= $func.name;
		my $returns	= $func.signature.returns;

		@fuzzers.push(Fuzzer.new(:$name, :$func, :$get-data, :$returns, :$test))
	}

	multi trait_mod:<is> (Routine $func, :%fuzzed!) is export {
		fuzz($func, |%fuzzed);
	}

	multi trait_mod:<is> (Routine $func, :$fuzzed!) is export {
		fuzz($func);
	}

	multi method generate(Test::Fuzz:U: Str \type, Int() \size = 100) {
		my $ret;
		if %generator{type}:exists {
			$ret = %generator{type}[^size]
		} else {
			die "Generator for '{type}' does not exists"
		}
		$ret
	}

	multi method generate(Test::Fuzz:U: ::Type, Int() \size) {
		$.generate(Type.^name, size);
	}

	method run-tests(Test::Fuzz:U:) {
		for @fuzzers -> $fuzz {
			$fuzz.run;
		}
	}
}
