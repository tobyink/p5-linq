=pod

=encoding utf-8

=head1 PURPOSE

Test LINQ C<take> method.

This test is based on 10array-skip_while.t but runs tests against
L<LINQ::Iterator> rather than L<LINQ::Array>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

BEGIN { $LINQ::FORCE_ITERATOR = 1 }

use Test::Modern;
use LINQ qw( LINQ );

my $collection = LINQ [
	"Aardvark",
	"Aardwolf",
	"Bee",
	"Cat",
	"Dog",
	"Elephant",
	"Apple",
];

is_deeply(
	$collection->skip_while(sub { $_ ne "Cat" })->to_array,
	[qw/ Cat Dog Elephant Apple /],
	'skip_while(CODE)',
);

is_deeply(
	$collection->skip_while(qr/^A/)->to_array,
	[qw/ Bee Cat Dog Elephant Apple /],
	'skip_while(Regexp)',
);

is_deeply(
	$collection->skip_while(qr/^Z/)->to_array,
	$collection->to_array,
	'skip_while(NEVER)',
);

done_testing;
