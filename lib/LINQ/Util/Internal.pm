use 5.006;
use strict;
use warnings;

package LINQ::Util::Internal;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.000_003';

sub create_linq {
	my $parent = shift;
	my $class  = $parent->target_class;
	ref( $class ) ? $class->( @_ ) : $class->new( @_ );
}

sub throw {
	require LINQ::Exception;
	my $e = shift;
	"LINQ::Exception::$e"->throw( @_ );
}

sub assert_code {
	my $code = shift;
	
	if ( ref( $code ) eq 'ARRAY' ) {
		@_    = @$code;
		$code = shift;
	}
	
	if ( ref( $code ) eq 'Regexp' ) {
		throw(
			"CallerError",
			message => "Regexp cannot accept curried arguments"
		) if @_;
		
		my $re = $code;
		return sub { m/$re/ };
	}
	
	if ( ref( $code ) ne 'CODE' ) {
		require Scalar::Util;
		require overload;
		
		throw(
			"CallerError",
			message => "Expected coderef; got '$code'"
		) unless Scalar::Util::blessed( $code ) && overload::Method( $code, '&{}' );
	}
	
	if ( @_ ) {
		my @curry = @_;
		return sub { $code->( @curry, @_ ) };
	}
	
	return $code;
}

1;
