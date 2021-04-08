use 5.006;
use strict;
use warnings;

package LINQ::FieldSet::Assertion;

my $_process_args = sub {
	require Scalar::Util;
	if ( Scalar::Util::blessed( $_[0] )
		and Scalar::Util::blessed( $_[1] )
		and @_ < 4 )
	{
		return $_[2] ? ( $_[1], $_[0] ) : ( $_[0], $_[1] );
	}
	
	my ( $self, @other ) = @_;
	my $other = __PACKAGE__->new( @other );
	return ( $self, $other );
};

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.000_007';

use Class::Tiny;
use parent qw( LINQ::FieldSet );

use LINQ::Util::Internal ();

use overload (
	q[&{}] => 'coderef',
	q[|]   => 'or',
	q[&]   => 'and',
	q[~]   => 'not',
);

sub _known_parameter_names {
	my ( $self ) = ( shift );
	
	return (
		$self->SUPER::_known_parameter_names,
		'is'      => 1,
		'in'      => 1,
		'like'    => 1,
		'match'   => 1,
		'cmp'     => 1,
		'numeric' => 0,
		'string'  => 0,
		'not'     => 0,
		'nocase'  => 0,
	);
} #/ sub _known_parameter_names

sub coderef {
	my ( $self ) = ( shift );
	$self->{coderef} ||= $self->_build_coderef;
}

sub BUILD {
	my ( $self ) = ( shift );
	if ( $self->seen_asterisk ) {
		LINQ::Util::Internal::throw(
			"CallerError",
			message => "Field '*' does not make sense for assertions",
		);
	}
}

sub _build_coderef {
	my ( $self ) = ( shift );
	my @checks   = map $self->_make_check( $_ ), @{ $self->fields };
	return sub {
		for my $check ( @checks ) {
			return !!0 unless $check->( $_ );
		}
		return !!1;
	};
} #/ sub _build_coderef

my %templates = (
	'numeric ==' => '%s == %s',
	'numeric !=' => '%s != %s',
	'numeric >'  => '%s >  %s',
	'numeric >=' => '%s >= %s',
	'numeric <'  => '%s <  %s',
	'numeric <=' => '%s <= %s',
	'string =='  => '%s eq %s',
	'string !='  => '%s ne %s',
	'string >'   => '%s gt %s',
	'string >='  => '%s ge %s',
	'string <'   => '%s lt %s',
	'string <='  => '%s le %s',
	'null =='    => 'defined( %s )',
);

my $_like_to_regexp = sub {
	my ( $like, $ci ) = @_;
	my $re      = '';
	my %anchors = (
		start => substr( $like, 0,  1 ) ne '%',
		end   => substr( $like, -1, 1 ) ne '%',
	);
	my @parts = split qr{(\\*[.%])}, $like;
	for my $p ( @parts ) {
		next unless length $p;
		my $backslash_count =()= $p =~ m{(\\)}g;
		my $wild_count      =()= $p =~ m{([%.])}g;
		if ( $wild_count ) {
			if ( $backslash_count && $backslash_count % 2 ) {
				my $last = substr( $p, -2, 2, '' );
				$p =~ s{\\\\}{\\};
				$re .= quotemeta( $p . substr( $last, -1, 1 ) );
			}
			elsif ( $backslash_count ) {
				my $last = substr( $p, -1, 1, '' );
				$p =~ s{\\\\}{\\};
				$re .= quotemeta( $p ) . ( $last eq '%' ? '.*' : '.' );
			}
			else {
				$re .= $p eq '%' ? '.*' : '.';
			}
		} #/ if ( $wild_count )
		else {
			$p =~ s{\\(.)}{$1}g;
			$re .= quotemeta( $p );
		}
	} #/ for my $p ( @parts )
	
	substr( $re, 0, 0, '\A' ) if $anchors{start};
	$re .= '\z'               if $anchors{end};
	
	$ci ? qr/$re/i : qr/$re/;
};

sub _make_check {
	my ( $self, $field ) = ( shift, @_ );
	my $getter = $field->getter;
	
	if ( exists $field->params->{is} ) {
		for ( qw/ like in match / ) {
			LINQ::Util::Internal::throw(
				"CallerError",
				message => "Cannot use '-is' and '-$_' together",
			) if $field->params->{$_};
		}
		my $expected = $field->params->{is};
		my $cmp      = $field->params->{cmp} || "==";
		my $type =
			$field->params->{numeric}             ? 'numeric'
			: $field->params->{string}            ? 'string'
			: !defined( $expected )               ? 'null'
			: $expected =~ /^[0-9]+(?:\.[0-9]+)$/ ? 'numeric'
			:                                       'string';
		my $template = $templates{"$type $cmp"}
			or LINQ::Util::Internal::throw(
			"CallerError",
			message => "Unexpected comparator '$cmp' for type '$type'",
			);
			
		my $guts;
		if ( $type eq 'null' ) {
			$guts = sprintf( $template, '$getter->( $_ )' );
		}
		elsif ( $field->params->{nocase} ) {
			my $fold = ( $] > 5.016 ) ? 'CORE::fc' : 'lc';
			$guts = sprintf(
				$template,
				"$fold( \$getter->( \$_ ) )",
				ref( $expected ) ? "$fold( \$expected )" : do {
					require B;
					"$fold( " . B::perlstring( $expected ) . ' )';
				},
			);
		} #/ elsif ( $field->params->{...})
		else {
			$guts = sprintf(
				$template,
				'$getter->( $_ )',
				ref( $expected ) ? '$expected' : do {
					require B;
					B::perlstring( $expected );
				},
			);
		} #/ else [ if ( $type eq 'null' )]
		
		if ( $field->params->{not} ) {
			$guts = "not( $guts )";
		}
		
		no warnings qw( uninitialized );
		return eval "sub { $guts }";
	} #/ if ( exists $field->params...)
	
	if ( exists $field->params->{in} ) {
		for ( qw/ is cmp numeric string like match / ) {
			LINQ::Util::Internal::throw(
				"CallerError",
				message => "Cannot use '-in' and '-$_' together",
			) if $field->params->{$_};
		}
		
		my @expected = @{ $field->params->{in} };
		
		if ( $field->params->{not} ) {
			return sub {
				my $value = $getter->( $_ );
				for my $expected ( @expected ) {
					return !!0 if $value eq $expected;
				}
				return !!1;
			};
		}
		else {
			return sub {
				my $value = $getter->( $_ );
				for my $expected ( @expected ) {
					return !!1 if $value eq $expected;
				}
				return !!0;
			};
		}
	} #/ if ( exists $field->params...)
	
	if ( exists $field->params->{like} ) {
		for ( qw/ is cmp numeric string in match / ) {
			LINQ::Util::Internal::throw(
				"CallerError",
				message => "Cannot use '-like' and '-$_' together",
			) if $field->params->{$_};
		}
		my $match = $_like_to_regexp->(
			$field->params->{like},
			$field->params->{nocase},
		);
		if ( $field->params->{not} ) {
			return sub {
				my $value = $getter->( $_ );
				$value !~ $match;
			};
		}
		else {
			return sub {
				my $value = $getter->( $_ );
				$value =~ $match;
			};
		}
	} #/ if ( exists $field->params...)
	
	if ( exists $field->params->{match} ) {
		for ( qw/ is cmp numeric string in like / ) {
			LINQ::Util::Internal::throw(
				"CallerError",
				message => "Cannot use '-match' and '-$_' together",
			) if $field->params->{$_};
		}
		my $match = $field->params->{match};
		require match::simple;
		if ( $field->params->{not} ) {
			return sub {
				my $value = $getter->( $_ );
				not match::simple::match( $value, $match );
			};
		}
		else {
			return sub {
				my $value = $getter->( $_ );
				match::simple::match( $value, $match );
			};
		}
	} #/ if ( exists $field->params...)
	
	LINQ::Util::Internal::throw(
		"CallerError",
		message => "Expected '-is', '-in', or '-like'",
	) if $field->params->{$_};
} #/ sub _make_check

sub not {
	my ( $self ) = ( shift );
	return 'LINQ::FieldSet::Assertion::NOT'->new(
		left => $self,
	);
}

sub and {
	my ( $self, $other ) = &$_process_args;
	return 'LINQ::FieldSet::Assertion::AND'->new(
		left  => $self,
		right => $other,
	);
}

sub or {
	my ( $self, $other ) = &$_process_args;
	return 'LINQ::FieldSet::Assertion::OR'->new(
		left  => $self,
		right => $other,
	);
}

package LINQ::FieldSet::Assertion::Combination;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.000_007';

use Role::Tiny;
requires( qw/ left right _build_coderef / );

sub coderef {
	my ( $self ) = ( shift );
	$self->{coderef} ||= $self->_build_coderef;
}

sub not {
	my ( $self ) = ( shift );
	return 'LINQ::FieldSet::Assertion::NOT'->new(
		left => $self,
	);
}

sub and {
	my ( $self, $other ) = &$_process_args;
	return 'LINQ::FieldSet::Assertion::AND'->new(
		left  => $self,
		right => $other,
	);
}

sub or {
	my ( $self, $other ) = &$_process_args;
	return 'LINQ::FieldSet::Assertion::OR'->new(
		left  => $self,
		right => $other,
	);
}

package LINQ::FieldSet::Assertion::NOT;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.000_007';

use Class::Tiny qw( left );
use Role::Tiny::With ();
Role::Tiny::With::with( 'LINQ::FieldSet::Assertion::Combination' );

use overload ();
'overload'->import(
	q[&{}] => 'coderef',
	q[|]   => 'or',
	q[&]   => 'and',
	q[~]   => 'not',
);

sub _build_coderef {
	my ( $self ) = ( shift );
	my $left = $self->left->coderef;
	return sub { not $left->( $_ ) };
}

sub not {
	my ( $self ) = ( shift );
	return $self->left;
}

sub right {
	LINQ::Util::Internal::throw(
		"InternalError",
		message => 'Unexpected second branch to NOT.',
	);
}

package LINQ::FieldSet::Assertion::AND;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.000_007';

use Class::Tiny qw( left right );
use Role::Tiny::With ();
Role::Tiny::With::with( 'LINQ::FieldSet::Assertion::Combination' );

use overload ();
'overload'->import(
	q[&{}] => 'coderef',
	q[|]   => 'or',
	q[&]   => 'and',
	q[~]   => 'not',
);

sub _build_coderef {
	my ( $self ) = ( shift );
	my $left     = $self->left->coderef;
	my $right    = $self->right->coderef;
	return sub { $left->( $_ ) and $right->( $_ ) };
}

package LINQ::FieldSet::Assertion::OR;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.000_007';

use Class::Tiny qw( left right );
use Role::Tiny::With ();
Role::Tiny::With::with( 'LINQ::FieldSet::Assertion::Combination' );

use overload ();
'overload'->import(
	q[&{}] => 'coderef',
	q[|]   => 'or',
	q[&]   => 'and',
	q[~]   => 'not',
);

sub _build_coderef {
	my ( $self ) = ( shift );
	my $left     = $self->left->coderef;
	my $right    = $self->right->coderef;
	return sub { $left->( $_ ) or $right->( $_ ) };
}

1;
