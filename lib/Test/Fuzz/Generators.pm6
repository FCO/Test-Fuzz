unit class Test::Fuzz::Generators;

method generators {
	{
		"Str"	=> gather {
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
		},
		"UInt"	=> gather {
			take 0;
			take 1;
			take 3;
			take 9999999999;
			take $_ for (^10000000000).roll(*)
		},
		"Int"	=> gather {
			for @( ::?CLASS.generators<UInt> ).grep({.defined}) -> $int {
				take -$int;
			}
		}
	}
};

