
=pod

=encoding utf-8

=head1 PURPOSE

Checks LINQ::FieldSet::Selector.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2021 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern;
use LINQ qw( LINQ );
use LINQ::Util qw( fields );
use Object::Adhoc qw( object );

my ( $alice, $bob ) = LINQ(
	[
		object( { name => 'Alice', xyz => 'ABC', min => 1,  max => 99 } ),
		object( { name => 'Bob',   xyz => 'DEF', min => 18, max => 49 } ),
	]
)->select(
	fields(
		'name', -as => 'moniker',
		'xyz',
		sub { sprintf( '%d-%d', $_->min, $_->max ) }, -as => 'range',
	)
)->to_list;

object_ok(
	$alice,
	'$alice',
	'can'  => [qw( moniker xyz range )],
	'more' => sub {
		my $object = shift;
		is( $object->moniker, 'Alice' );
		is( $object->xyz,     'ABC' );
		is( $object->range,   '1-99' );
	},
);

object_ok(
	$bob,
	'$bob',
	'can'  => [qw( moniker xyz range )],
	'more' => sub {
		my $object = shift;
		is( $object->moniker, 'Bob' );
		is( $object->xyz,     'DEF' );
		is( $object->range,   '18-49' );
	},
);

my ( $carol ) = LINQ(
	[
		{ name => 'Carol', xyz => 'XYZ', min => 49, max => 75 },
	]
)->select(
	fields(
		'name', -as => 'moniker',
		'xyz',
		sub { sprintf( '%d-%d', $_->{min}, $_->{max} ) }, -as => 'range',
	)
)->to_list;

object_ok(
	$carol,
	'$carol',
	'can'  => [qw( moniker xyz range )],
	'more' => sub {
		my $object = shift;
		is( $object->moniker, 'Carol' );
		is( $object->xyz,     'XYZ' );
		is( $object->range,   '49-75' );
	},
);

my ( $dave ) = LINQ(
	[
		object( { name => 'Dave', xyz => 'UVW', min => 49, max => 75 } ),
	]
)->select(
	fields(
		'name', -as => 'moniker',
		'xyz',
		'*',
		sub { sprintf( '%d-%d', $_->min, $_->max ) }, -as => 'range',
	)
)->to_list;

object_ok(
	$dave,
	'$dave',
	'can'  => [qw( moniker xyz range name min max )],
	'more' => sub {
		my $object = shift;
		is( $object->moniker, 'Dave' );
		is( $object->xyz,     'UVW' );
		is( $object->range,   '49-75' );
		is( $object->name,    'Dave' );
		is( $object->min,     '49' );
		is( $object->max,     '75' );
	},
);

is(
	fields( "foo", "bar", -as => "barr", "baz" )->_sql_selection,
	'"foo", "bar" AS "barr", "baz"',
	'Simple SQL generation',
);

is(
	fields( "foo", "bar", -as => "barr", "baz", "*" )->_sql_selection,
	undef,
	'Simple SQL generation with asterisk',
);

is(
	fields( "foo", sub { }, "bar", -as => "barr", "baz" )->_sql_selection,
	undef,
	'Simple SQL generation with coderef',
);

done_testing;
