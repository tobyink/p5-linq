=pod

=encoding utf-8

=head1 PURPOSE

Test LINQ C<where> method.

This test runs against LINQ::Iterator rather than LINQ::Array.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

BEGIN { $LINQ::FORCE_ITERATOR = 1 }

use strict;
use warnings;
use Test::Modern;

use LINQ qw( LINQ );

my $collection = LINQ [
	"Aardvark",
	"Aardwolf",
	"Bee",
	"Cat",
	"Dog",
	"Elephant",
];

my $length8 = $collection->where(sub { length == 8 });

is_deeply(
	$length8->to_array,
	[qw/ Aardvark Aardwolf Elephant /],
	'simple where(CODE)',
);

is_deeply(
	$length8->where(qr/^A/)->to_array,
	[qw/ Aardvark Aardwolf /],
	'simple where(Regexp)',
);

done_testing;
