use 5.006;
use strict;
use warnings;

package LINQ::FieldSet;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.000_007';

use Class::Tiny qw( fields seen_asterisk );
use LINQ::Util::Internal ();

sub _known_parameter_names {
	my ( $self ) = ( shift );
	return ();
}

sub BUILDARGS {
	my ( $class, @args ) = ( shift, @_ );
	
	if ( @args == 1 and ref( $args[0] ) eq 'HASH' ) {
		return $args[0];
	}
	
	require LINQ::Field;
	
	my %known = $class->_known_parameter_names;
	
	my @fields;
	my $idx = 0;
	my $seen_asterisk;
	
	ARG: while ( @args ) {
		my $value  = shift @args;
		if ( $value eq '*' ) {
			$seen_asterisk = 1;
			next ARG;
		}
		my %params = ();
		while ( @args and ! ref $args[0] and $args[0] =~ /\A-/ ) {
			my $p_name = substr( shift( @args ), 1 );
			if ( $known{$p_name} ) {
				$params{$p_name} = shift( @args );
			}
			elsif ( exists $known{$p_name} ) {
				$params{$p_name} = 1;
			}
			else {
				LINQ::Util::Internal::throw(
					'CallerError',
					message => "Unknown field parameter '$p_name'",
				);
			}
		}
		
		my $field = 'LINQ::Field'->new(
			value  => $value,
			index  => ++$idx,
			params => \%params,
		);
		push @fields, $field;
	}
	
	return {
		fields        => \@fields,
		seen_asterisk => $seen_asterisk,
	};
}

sub fields_hash {
	my ( $self ) = ( shift );
	$self->{fields_hash} ||= $self->_build_fields_hash;
}

sub _build_fields_hash {
	my ( $self ) = ( shift );
	my %fields;
	foreach my $field ( @{ $self->fields } ) {
		$fields{$field->name} = $field;
	}
	return \%fields;
}

1;
