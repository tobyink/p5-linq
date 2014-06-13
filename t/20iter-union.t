=pod

=encoding utf-8

=head1 PURPOSE

Test LINQ C<union> method.

This test is based on 10array-union.t but runs tests against
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
use DisneyData qw( pets );

my $begins_S = pets->where(sub { $_->name =~ /^S/ });
my $ends_n   = pets->where(sub { $_->name =~ /n$/ });
my $union    = $begins_S->union($ends_n, sub { $_[0]->id == $_[1]->id });

is_deeply(
	$union->select(sub { $_->name })->order_by(-string, sub { $_ })->to_array,
	[qw/ Robin Stella Sven /],
	'simple union',
);

done_testing;
