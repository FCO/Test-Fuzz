use Test;
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

	my Iterable %generator;

	multi fuzz-generator(::Type) is export is rw {
		%generator{Type.^name};
	}

	multi fuzz-generator(Str \type) is export is rw {
		%generator{type};
	}

	fuzz-generator("Str") = gather {
		take "";
		take "a";
		take "a" x 9999999;
		take "áéíóú";
		take "\n";
		take "\r";
		take "\t";
		take "\r\n";
		take "\r\t\n";
		loop {
			take (0.chr .. 0xc3bf.chr).roll((^999999).pick).join
		}
	};

	fuzz-generator("UInt") = gather {
		take 0;
		take 1;
		take 3;
		take 9999999999;
		take $_ for (^10000000000).roll(*)
	};

	fuzz-generator("Int")	= gather {
		for @( %generator<UInt> ).grep({.defined}) -> $int {
			take -$int;
		}
	};

	my Fuzzer @fuzzers;

	sub fuzz(Routine $func, Int() :$counter = 1000, Callable :$test, :@generators is copy) is export {
		if @generators {
			@generators .= map: { ($^type || $^type.^name), all() };
		} else {
			@generators = $func.signature.params.map({|(.type.^name ~ .modifier, .constraints)})
		}
		my $get-data = sub {
			do if $func.signature.params.elems > 0 {
				my @data = ([X] @generators.map(-> \type, \constraints {
					say "type: {type}; constraints: {constraints}; counter: {$counter}";
					$?CLASS.generate(type, constraints, $counter / $func.signature.params.elems)
				})).pick($counter);
				if @generators.elems <= 2 {
					@data = @data[0].map(-> $item {[$item]});
				}
				@data
			} else {
				()
			}
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

	multi method generate(Test::Fuzz:U: Str \type, Mu \constraints, Int() \size = 1000) {
		my @ret;
		my $type = type ~~ /^^
			$<type>	= (\w+)
			[
				':'
				$<def>	= (<[UD]>)
			]?
		$$/;
		my $test-type		= ::(~$type<type>);
		my $loaded-types	= set |::.values.grep(not *.defined);
		my $builtin-types	= set |%?RESOURCES<classes>.IO.lines.map({::($_)});
		my $types			= $loaded-types ∪ $builtin-types;
		my @types			= $types.keys.grep(sub (Mu \item) {
			return item ~~ $test-type & constraints;
			CATCH {return False}
		});
		@ret				= @types if not $type<def>.defined or ~$type<def> eq "U";
		my %indexes			:= BagHash.new;
		while @ret.elems < size {
			for @types -> $sub {
				#say $sub;
				if %generator{$sub.^name}:exists {
					my $item = %generator{$sub.^name}[%indexes{$sub.^name}++];
					#say $item;
					@ret.push: $item if $item ~~ $test-type and $item ~~ constraints;
				}
			}
		}
		@ret
	}

	multi method generate(Test::Fuzz:U: ::Type, Mu \constraints, Int() \size) {
		$.generate(Type.^name, constraints, size);
	}

	method run-tests(Test::Fuzz:U:) {
		for @fuzzers -> $fuzz {
			$fuzz.run;
		}
	}
}
