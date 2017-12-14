use Test;
use lib "lib";

use Test::Fuzz;
use Test::Fuzz::AggGenerators;

#Make class and use it as a signature.
class Foo { has $.abc = 0; }
my $sig = :(Foo $a);

#Make sure that a custom class can be used.
$sig does Test::Fuzz::AggGenerators;
is $sig.agg-generators, True, "{$sig.gist} does Test::Fuzz::AggGenerators";
can-ok $sig, "compose";
can-ok $sig, "generate-samples";

subtest {
    #Try to compose and generate samples from this signature.
    my $compose = Promise.new;
    my $gen-samp = Promise.new;
    my $generation = start {
        #Set things up.
        $sig.compose;
        #Make sure that each parameter was taken care of.
        is $sig.params.grep(* !~~ Test::Fuzz::Generator).elems, 0,
            "Signature was composed";
        #Mark this step as complete.
        $compose.keep;

        #Generate samples of each parameter.
        my $samp = 5;
        my @samples = $sig.generate-samples: $samp;
        #Make sure that the correct number of samples are generated.
        todo "Generate samples for misc classes";
        is @samples.elems, $samp, "Generated $samp samples: {@samples.gist}";
        #Mark this step as complete.
        $gen-samp.keep;
    }

    #Set a timer to check if this hangs.
    my $timer = Promise.in(15).then: {
        flunk "Hangs on "
            ~ ("compose" unless ?$compose)
            ~ ("generate-samples" unless ?$gen-samp);
    }

    #Wait for either the generator or timer to finish.
    await Promise.anyof: $generation, $timer;
}

done-testing;
