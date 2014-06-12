=pod

=encoding utf-8

=head1 PURPOSE

Test LINQ C<count> method.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::Modern;

use LINQ qw( LINQ );

is(
	LINQ( [qw/Aardvark Bee Hawk/] )->count,
	3,
	'simple count',
);

is(
	LINQ( [qw//] )->count,
	0,
	'simple count == 0',
);

is(
	LINQ( [qw/Aardvark Bee Hawk/] )->count(sub { $_ =~ $_[0] }, qr/a/),
	2,
	'count(CODE)',
);

done_testing;
