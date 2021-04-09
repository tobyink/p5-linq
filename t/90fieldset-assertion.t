
=pod

=encoding utf-8

=head1 PURPOSE

Checks LINQ::FieldSet::Assertion.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2021 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern;
use LINQ qw( LINQ );
use LINQ::Util qw( check_fields );
use Object::Adhoc qw( object );

my $collection = LINQ(
	[
		object( { name => 'Alice', xyz => 'ABC', min => 1,  max => 99 } ),
		object( { name => 'Bob',   xyz => 'DEF', min => 18, max => 49 } ),
	]
);

is(
	$collection->single( check_fields 'xyz', -is => 'ABC' )->name,
	'Alice',
	'-is stringy',
);

is(
	$collection->where( check_fields 'xyz', -is => 'abc' )->count,
	0,
	'-is stringy is case sensitive',
);

is(
	$collection->single( check_fields 'xyz', -nocase, -is => 'abc' )->name,
	'Alice',
	'-nocase, -is stringy',
);

is(
	$collection->single( check_fields 'min', -is => '18.0' )->name,
	'Bob',
	'-is numeric',
);

is(
	$collection->single( check_fields 'name', -cmp => '<', -is => 'Axel' )->name,
	'Alice',
	'-cmp stringy',
);

is(
	$collection->single( check_fields 'max', -cmp => '>', -is => '98' )->name,
	'Alice',
	'-cmp numeric',
);

is(
	$collection->single( check_fields 'name', -in => [ 'Bob', 'Rob' ] )->name,
	'Bob',
	'-in',
);

is(
	$collection->where( check_fields 'name', -in => [ 'BOB', 'ROB' ] )->count,
	0,
	'-in is case sensitive',
);

is(
	$collection->single( check_fields 'name', -nocase, -in => [ 'BOB', 'ROB' ] )->name,
	'Bob',
	'-nocase, -in',
);

is(
	$collection->single( check_fields 'name', -like => 'Al%' )->name,
	'Alice',
	'-like',
);

ok(
	$collection->all( check_fields 'name', -nix, -like => 'al%' ),
	'-like is case sensitive',
);

is(
	$collection->single( check_fields 'name', -nocase, -like => 'al%' )->name,
	'Alice',
	'-nocase, -like',
);

is(
	$collection->single( check_fields 'name', -match => qr/Alice/ )->name,
	'Alice',
	'-match',
);

is(
	$collection->single( check_fields( 'name', -nocase, -like => 'al%' )->not )->name,
	'Bob',
	'->not',
);

is(
	$collection->where( check_fields( 'name', -is => 'Alice' )->and( 'name', -is => 'Bob' ) )->count,
	0,
	'->and',
);

is(
	$collection->where( check_fields( 'name', -is => 'Alice' )->or( 'name', -is => 'Bob' ) )->count,
	2,
	'->or',
);

my $collection2 = LINQ(
	[
		object( { name => 'Alice', xyz => 'ABC', min => 1,  max => 99, val =>  4 } ),
		object( { name => 'Bob',   xyz => 'DEF', min => 18, max => 49, val => 20 } ),
		object( { name => 'Carol', xyz => 'DEF', min => 75, max => 75, val => 33 } ),
	]
);

is(
	$collection2->where( check_fields(
		'val', -cmp => '>=', -to => 'min',
		'val', -cmp => '<=', -to => 'max',
	) )->select( sub { $_->name } )->aggregate( sub { $_[0] . $_[1] } ),
	'AliceBob',
	'-to, -cmp',
);

use Scalar::Util qw( refaddr );

my $x = check_fields( 'name', -is => 'Alice' );
is( refaddr($x->coderef), refaddr($x->not->not->coderef) );
object_ok( exception { $x->not->right }, '$e', isa => 'LINQ::Exception' );

for my $t (
	[ '*' ],
	[ 'name', -is => 'Bob', -like => 'Alice' ],
	[ 'name', -cmp => '==' ],
	[ 'name', -is => 'Bob', -cmp => 'Potato' ],
	) {
	my $e = exception { check_fields( @$t )->coderef };
	object_ok( $e, '$e', isa => 'LINQ::Exception::CallerError' )
		or diag explain( $t );
}

done_testing;
