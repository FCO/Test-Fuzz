#| Augmenting classes to create generate-samples method
unit module Test::Fuzz::Generators;
use MONKEY-TYPING;
augment class Int {
	method generate-samples(::?CLASS:U:) {
		gather {
			take 0;
			take -0;
			take 1;
			take -1;
			take 3;
			take -3;
			take 9999999999;
			take -9999999999;
			take $_ for (-10000000000^..^10000000000).roll(*)
		}
	}
}

augment class Rat {
	method generate-samples(::?CLASS:U:) {
		gather {
			take 0.0;
			take -0.0;
			take 0.00000000000001;
			take -0.00000000000001;
			take 1.0;
			take -1.0;
			take 3.0;
			take -3.0;
			take 9999999999.0;
			take -9999999999.0;
			take rand.Rat for ^Inf
		}
	}
}

augment class Num {
	method generate-samples(::?CLASS:U:) {
		gather {
			take 0e0;
			take -0e0;
			take 1e-100;
			take -1e-100;
			take 1e0;
			take -1e0;
			take 3e0;
			take -3e0;
			take 9999999999e0;
			take -9999999999e0;
			take rand for ^Inf
		}
	}
}

augment class Str {
	method generate-samples(::?CLASS:U:) {
		gather {
			take "";
			take "a";
			take "a" x 99999;
			take "áéíóú";
			take "\n";
			take "\r";
			take "\t";
			take "\r\n";
			take "\r\t\n";
			loop {
				take (0.chr .. 0xc3bf.chr).roll((^999).pick).join
			}
		}
	}
}
