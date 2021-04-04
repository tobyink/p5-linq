use 5.006;
use strict;
use warnings;

if ( $] < 5.010000 ) {
	require UNIVERSAL::DOES;
}

{

	package LINQ::Exception;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.000_003';
	
	use Class::Tiny qw( package file line );
	use overload q[""] => sub { shift->to_string };
	
	sub message { "An error occurred" }
	
	sub to_string {
		my $self = shift;
		sprintf(
			"%s at %s line %d.\n",
			$self->message,
			$self->file,
			$self->line,
		);
	}
	
	sub throw {
		my $class = shift;
		
		my ( $level, %caller ) = 0;
		$level++ until caller( $level ) !~ /\ALINQx?::/;
		@caller{qw/ package file line /} = caller( $level );
		
		die( $class->new( %caller, @_ ) );
	}
}

{

	package LINQ::Exception::Unimplemented;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.000_003';
	use parent -norequire, qw( LINQ::Exception );
	use Class::Tiny qw( method );
	
	sub message {
		my $self = shift;
		my $meth = $self->method;
		"Method $meth is unimplemented";
	}
}

{

	package LINQ::Exception::InternalError;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.000_003';
	use parent -norequire, qw( LINQ::Exception );
	use Class::Tiny qw( message );
}

{

	package LINQ::Exception::CallerError;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.000_003';
	use parent -norequire, qw( LINQ::Exception );
	use Class::Tiny qw( message );
	
	sub BUILD {
		my $self = shift;
		'LINQ::Exception::InternalError'
			->throw( message => 'Required attribute "message" not defined' )
			unless defined $self->message;
	}
}

{

	package LINQ::Exception::CollectionError;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.000_003';
	use parent -norequire, qw( LINQ::Exception );
	use Class::Tiny qw( collection );
	
	sub BUILD {
		my $self = shift;
		'LINQ::Exception::InternalError'
			->throw( message => 'Required attribute "collection" not defined' )
			unless defined $self->collection;
	}
}

{

	package LINQ::Exception::NotFound;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.000_003';
	use parent -norequire, qw( LINQ::Exception::CollectionError );
	sub message { "Item not found" }
}

{

	package LINQ::Exception::MultipleFound;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.000_003';
	use parent -norequire, qw( LINQ::Exception::CollectionError );
	use Class::Tiny qw( found );
	sub message { "Item not found" }
}

{

	package LINQ::Exception::Cast;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.000_003';
	use parent -norequire, qw( LINQ::Exception::CollectionError );
	use Class::Tiny qw( type );
	
	sub message {
		my $type = shift->type;
		"Not all elements in the collection could be cast to $type";
	}
	
	sub BUILD {
		my $self = shift;
		'LINQ::Exception::InternalError'
			->throw( message => 'Required attribute "type" not defined' )
			unless defined $self->type;
	}
}

1;
