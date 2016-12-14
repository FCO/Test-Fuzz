use Test::Fuzz::Fuzzer;
use Test::Fuzz::Generator;

class Test::Fuzz {
	my $instance	= Test::Fuzz.bless;
	has $!generator	= Test::Fuzz::Generator.new;
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
						$!generator.generate($type, $constraints, $counter).map: -> $item {[$item]}
					}
				} else {
					([X] @generators.map(-> (:$type, :$constraints) {
						$!generator.generate($type, $constraints, $counter)
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

