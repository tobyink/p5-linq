
=pod

=encoding utf-8

=head1 PURPOSE

Check the LINQ::Iterator constructor.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2021 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

BEGIN { $LINQ::FORCE_ITERATOR = 1 }

use Test::Modern;
use LINQ ();
use LINQ::Iterator ();

my $CLASS = 'LINQ::Iterator';

my @c1 = qw( 3 5 2 );
my $c1 = $CLASS->new( sub {
	my $multiplier = shift;
	return LINQ::END unless @c1;
	$multiplier * shift( @c1 );
}, 4 );

is_deeply(
	$c1->to_array,
	[ 12, 20, 8 ],
	'Iterator using currying.',
);

ok(
	$c1->_guts,
	'Iterator still has its guts',
);

is_deeply(
	[ $c1->to_list ],
	[ 12, 20, 8 ],
	'->to_list',
);

ok(
	! $c1->_guts,
	'Iterator lost its guts',
);

is_deeply(
	[ $c1->to_list ],
	[ 12, 20, 8 ],
	'->to_list',
);

object_ok(
	exception { $CLASS->new },
	'$e',
	isa    => 'LINQ::Exception::CallerError'
);


done_testing;
