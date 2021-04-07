use 5.006;
use strict;
use warnings;

package LINQ::Util;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.000_005';

use Exporter::Shiny qw( fields assert_fields );

sub fields {
	require LINQ::FieldSet::Selection;
	'LINQ::FieldSet::Selection'->new( @_ );
}

sub assert_fields {
	require LINQ::FieldSet::Assertion;
	'LINQ::FieldSet::Assertion'->new( @_ );
}

1;


=pod

=encoding utf-8

=head1 NAME

LINQ::Util - useful utilities to make working with LINQ collections easier

=head1 SYNOPSIS

  use feature qw( say );
  use LINQ qw( LINQ )';
  use LINQ::Util qw( fields  );
  
  my $collection = LINQ( [
    { name => 'Alice', age => 30, dept => 'IT'        },
    { name => 'Bob'  , age => 29, dept => 'IT'        },
    { name => 'Carol', age => 32, dept => 'Marketing' },
    { name => 'Dave',  age => 33, dept => 'Accounts'  },
  ] );
  
  my $dont_care_about_age = $collection->select( fields( 'name', 'dept' ) );
  
  for ( $dont_care_about_age->to_list ) {
    printf( "Hi, I'm %s from %s\n", $_->name, $_->dept );
  }

=head1 DESCRIPTION


=head1 FUNCTIONS

=over

=item C<< fields( SPEC ) >>

Creates a coderef (actually a blessed object overloading C<< &{} >>) which
takes a hashref or object as input, selects just the fields/keys given in the
SPEC, and returns an object with those fields.

A simple example would be:

  my $selector = fields( 'name' );
  my $object   = $selector->( { name => 'Bob', age => 29 } );

In this example, C<< $object >> would be a blessed object with a C<name>
method which returns "Bob".

Fields can be renamed:

  my $selector = fields( 'name', -as => 'moniker' );
  my $object   = $selector->( { name => 'Bob', age => 29 } );
  say $object->moniker;  # ==> "Bob"

A coderef can be used as a field:

  my $selector = fields(
    sub { uc( $_->{'name'} ) }, -as => 'moniker',
  );
  my $object = $selector->( { name => 'Bob', age => 29 } );
  say $object->moniker;  # ==> "BOB"

An asterisk field selects all the input fields:

  my $selector = fields(
    sub { uc( $_->{'name'} ) }, -as => 'moniker',
    '*',
  );
  my $object = $selector->( { name => 'Bob', age => 29 } );
  say $object->moniker;  # ==> "BOB"
  say $object->name;     # ==> "Bob"
  say $object->age;      # ==> 29

The aim of the C<fields> function is to allow the LINQ C<select> method to
function more like an SQL SELECT, where you give a list of fields you wish
to select.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=LINQ>.

=head1 SEE ALSO

L<LINQ::Collection>, L<LINQ>.

L<https://en.wikipedia.org/wiki/Language_Integrated_Query>

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2021 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
