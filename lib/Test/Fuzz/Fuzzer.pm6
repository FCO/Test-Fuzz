use Test;
class Test::Fuzz::Fuzzer {
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

