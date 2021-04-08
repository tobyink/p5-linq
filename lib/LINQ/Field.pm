use 5.006;
use strict;
use warnings;

package LINQ::Field;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.000_006';

use Class::Tiny qw( index name value params );

sub BUILD {
	my ( $self ) = ( shift );
	
	if ( not $self->{params} ) {
		$self->{params} = {};
	}
	
	if ( not defined $self->{name} ) {
		if ( defined $self->{params}{as} ) {
			$self->{name} = $self->{params}{as};
		}
		elsif ( ! ref $self->{value} and $self->{value} =~ /\A[^\W0-9]\w*\z/ ) {
			$self->{name} = $self->{value};
		}
		else {
			$self->{name} = sprintf( '_%d', $self->{index} );
		}
	}
	
}

sub getter {
	my ( $self ) = @_;
	$self->{getter} ||= $self->_build_getter;
}

sub _build_getter {
	my ( $self ) = @_;
	
	my $attr = $self->value;
	
	if ( ref( $attr ) eq 'CODE' ) {
		return $attr;
	}
	
	require Scalar::Util;
	
	return sub {
		my $blessed = Scalar::Util::blessed( $_ );
		if ( ( $blessed || '' ) =~ /\AObject::Adhoc::__ANON__::/ ) {
			$blessed = undef;
		}
		scalar( $blessed ? $_->$attr : $_->{$attr} );
	};
}

1;
