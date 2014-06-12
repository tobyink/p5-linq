=pod

=encoding utf-8

=head1 PURPOSE

Test LINQ C<of_type> method.

This test is based on 10array-of_type.t but runs tests against
L<LINQ::Iterator> rather than L<LINQ::Array>.

=head1 DEPENDENCIES

This test requires L<Types::Standard>. It will be skipped otherwise.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

BEGIN { $LINQ::FORCE_ITERATOR = 1 }

use Test::Modern -requires => { 'Types::Standard' => 0 };
use LINQ qw( LINQ );
use Types::Standard -types;

my $collection = LINQ [
	"Aardvark",
	"Aardwolf",
	6,
	"Bee",
	"Cat",
	9,
	"Dog",
	"Elephant",
	3.14,
];

is_deeply(
	$collection->of_type(Int)->to_array,
	[qw/ 6 9 /],
	'simple of_type',
);

my $Rounded = Int->plus_coercions(Num, sub { int($_) });

is_deeply(
	$collection->of_type($Rounded)->to_array,
	[qw/ 6 9 3 /],
	'of_type plus coercions',
);

done_testing;
