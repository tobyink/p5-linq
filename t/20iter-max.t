=pod

=encoding utf-8

=head1 PURPOSE

Test LINQ C<max> method.

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

is(
	LINQ( [1..6, 0] )->max,
	6,
	'simple max',
);

is(
	LINQ( [qw/Aardvark Bee Cat/] )->max(sub { length($_) }),
	8,
	'simple max(CODE)',
);

done_testing;
