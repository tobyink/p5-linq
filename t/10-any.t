=pod

=encoding utf-8

=head1 PURPOSE

Test LINQ C<any> method.

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
use DisneyData qw( people pets );

ok(
	people->any(sub { $_->name eq 'Elsa' }),
	'any returning true',
);

ok(
	! people->any(sub { $_->name eq 'Aurora' }),
	'any returning false',
);

ok(
	! LINQ([])->any(sub { die; }),
	'any returning false on empty collection without even needing to run check',
);

done_testing;
