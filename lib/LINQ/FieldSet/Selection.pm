use 5.006;
use strict;
use warnings;

package LINQ::FieldSet::Selection;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.000_007';

use Class::Tiny;
use parent qw( LINQ::FieldSet );

use overload q[&{}] => 'coderef';

sub _known_parameter_names {
	my ( $self ) = ( shift );
	
	return (
		$self->SUPER::_known_parameter_names,
		'as'   => 1,
	);
}

sub target_class {
	my ( $self ) = ( shift );
	$self->{target_class} ||= $self->_build_target_class;
}

sub _build_target_class {
	my ( $self ) = ( shift );
	require Object::Adhoc;
	return Object::Adhoc::make_class( [ keys %{ $self->fields_hash } ] );
}

sub coderef {
	my ( $self ) = ( shift );
	$self->{coderef} ||= $self->_build_coderef;
}

sub _build_coderef {
	my ( $self ) = ( shift );
	my @fields   = @{ $self->fields };
	my $bless    = $self->target_class;
	my $asterisk = $self->seen_asterisk;
	return sub {
		my %output = ();
		if ( $asterisk ) {
			%output = %$_;
		}
		for my $field ( @fields ) {
			$output{ $field->name } = $field->getter->( $_ );
		}
		$asterisk ? Object::Adhoc::object( \%output ) : bless( \%output, $bless );
	};
}

sub _sql_selection {
	my ( $self, $name_quoter ) = ( shift, @_ );
	$name_quoter ||= sub {
		my $name = shift;
		return sprintf( '"%s"', quotemeta($name) );
	};
	return if $self->seen_asterisk;
	
	my @cols;
	for my $field ( @{ $self->fields } ) {
		my $orig_name = $field->value;
		my $aliased   = $field->name;
		return if ref( $orig_name );
		return if ! defined( $aliased );
		
		if ( $aliased eq $orig_name ) {
			push @cols, $name_quoter->( $orig_name );
		}
		else {
			push @cols, sprintf(
				'%s AS %s',
				$name_quoter->( $orig_name ),
				$name_quoter->( $aliased ),
			);
		}
	}
	return join( q[, ], @cols );
}

1;
