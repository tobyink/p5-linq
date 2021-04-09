
=pod

=encoding utf-8

=head1 PURPOSE

Test that LINQ compiles.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern qw( use_ok exception object_ok is done_testing -pod );

use_ok( 'LINQ' );
use_ok( 'LINQ::Array' );
use_ok( 'LINQ::Iterator' );
use_ok( 'LINQ::Collection' );
use_ok( 'LINQ::Exception' );

all_pod_files_ok( 'lib', 't' );

all_pod_coverage_ok( 'lib' );

# line 36 "01basic.t"
my $e = exception { 'LINQ::Exception'->throw };

object_ok(
	$e, '$e',
	isa  => 'LINQ::Exception',
	can  => [ qw/ message package file line to_string / ],
	more => sub {
		my $e = shift;
		is( $e->message, 'An error occurred' );
		is( $e->package, 'main' );
		is( $e->file,    '01basic.t' );
		is( $e->line,    36 );
	},
);

done_testing;
