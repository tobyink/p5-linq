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

use Test::Modern qw( use_ok done_testing );

use_ok('LINQ');
use_ok('LINQ::Array');
use_ok('LINQ::Collection');
use_ok('LINQ::Exception');

done_testing;

