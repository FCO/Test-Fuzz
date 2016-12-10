use Test;
my @proms;
class Test::Fuzz {
	class Fuzzer {
		has				$.name;
		has 			@.data;
		has Supply		$.get-data;
		has Block		$.func;
		has 			$.returns;
		has Callable	$.test;

		method run() is hidden-from-backtrace {
			subtest {
				react {
					whenever $.get-data -> @data {
						say "data: {@data}";
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

	sub fuzz(Routine $func, Int() :$counter = 100, Callable :$test, :@generators is copy) is export {
		if @generators {
			@generators .= map: { $^type || $^type.^name };
		} else {
			@generators = $func.signature.params.map({|(.type.^name ~ .modifier, .constraints)})
		}
		my @sups = @generators.map(-> $type, $constraint {
			my $supplier = Supplier.new;
			$?CLASS.generate($type, $constraint, $supplier, $counter);
			#$supplier.Supply.tap: &say;
			$supplier.Supply
		});
		my $get-data = Supply.zip(|@sups);
		say @sups;
		$get-data.tap: &say;

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

	multi method generate(Test::Fuzz:U: Str \type, Mu $constraints, Supplier $supplier, Int() \size = 100) {
		my @ret;
		my @proms;
		my $type = type ~~ /^^
			$<type>	= (\w+)
			[
				':'
				$<def>	= (<[UD]>)
			]?
		$$/;
		my %types := set |::.values.grep(! *.defined), |%?RESOURCES<classes>.IO.lines.map: {::($_)};
		my @types = %types.keys.grep: ::(~$type<type>);
		@ret = @types if not $type<def>.defined or ~$type<def> eq "U";
		@proms.push: start for @types -> $sub {
			@proms.push: do if %generator{$sub.^name}:exists {
				@proms.push: start {
					my $c = 0;
					for @( %generator{$sub.^name} ) -> $item {
						last if $c++ > size²;
						say "{$item} ~~ {~$type<type>} ~~ $constraints";
						#next unless $item ~~ ::(~$type<type>) and $item ~~ $constraints;
						#say $item;
						$supplier.emit: $item
					}
				}
			}
		}
	   	if not @ret {
			die "Generator for '{type}' does not exists"
		}
	}

	multi method generate(Test::Fuzz:U: ::Type, Supplier $sup, Int() \size) {
		$.generate(Type.^name, $sup, size);
	}

	method run-tests(Test::Fuzz:U:) {
		for @fuzzers -> $fuzz {
			$fuzz.run;
		}
		await @proms;
	}
}
