class Test::Fuzz {
	class Fuzzer {
		has		$.name;
		has 		@.data;
		has Block	$.func;
		has 		$.returns;

		method run() {
			for @.data -> @data {
				my $return = $.func.(|@data);
				$return.exception.throw if $return ~~ Failure;
				CATCH {
					default {
						note "{ $.name }({ @data.join(", ") })  => { $return }";
						die do given .backtrace[*-1] { .file, .line, .subname };
					}
				}
			}
		}
	}

	my %generator{Mu:U};

	%generator{UInt} = gather {
		take 0;
		take 1;
		take 9999999999;
		take $_ for (^10000000000).roll(*)
	};

	%generator{Int}	= gather for @( %generator{UInt} ) -> $int {
		take $int;
		take -$int unless $int == 0;
	};

	my Fuzzer @fuzzers;

	multi trait_mod:<is> (Routine $func, :$fuzzed!) is export {
		#note $func.signature;
		my $counter	= 10;

		my @data = [X] $func.signature.params.map(-> \param {
			my $type = param.type;
			$?CLASS.generate($type, $counter)
		});

		my $name	= $func.name;
		my $returns	= $func.signature.returns;

		@fuzzers.push(Fuzzer.new(:$name:$func:@data:$returns))
	}

	method generate(Test::Fuzz:U: ::Type, Int \size) {
		my $ret;
		if %generator{Type}:exists {
			$ret = %generator{Type}[^size]
		}
		$ret
	}

	method run-tests(Test::Fuzz:U:) {
		#say @fuzzers;
		for @fuzzers -> $fuzz {
			$fuzz.run;
		}
	}
}
