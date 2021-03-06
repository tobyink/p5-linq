
=pod

=encoding utf-8

=head1 PURPOSE

Test the C<take> method of L<LINQ::Array>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

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
	$collection->take_while( sub { $_ ne "Cat" } )->to_array,
	[qw/ Aardvark Aardwolf Bee /],
	'take_while(CODE)',
);

is_deeply(
	$collection->take_while( qr/^A/ )->to_array,
	[qw/ Aardvark Aardwolf /],
	'take_while(Regexp)',
);

is_deeply(
	$collection->take_while( qr/./ )->to_array,
	$collection->to_array,
	'take_while(ALWAYS)',
);

done_testing;
