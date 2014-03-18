# ABSTRACT: Base class for generators


package HiD::Generator;
$HiD::Generator::VERSION = '1.2';
BEGIN {
  $HiD::Generator::AUTHORITY = 'cpan:GENEHACK';
}
use Moose::Role;

use 5.014;
use utf8;
use autodie;
use warnings   qw/ FATAL utf8 /;
use charnames  qw/ :full           /;
use feature    qw/ unicode_strings /;

requires 'generate';


no Moose::Role;
1;

__END__

=pod

=encoding utf-8

=head1 NAME

HiD::Generator - Base class for generators

=head1 DESCRIPTION

Role for generator objects

See L<http://jekyllrb.com/docs/plugins/#generators> for more details. The HiD
implementation differs somewhat, particularly in supporting additional plugin
functionality in a post-publication phase (see L<HiD::Plugin>), but generators
should still be used for things that need to modify content or inject new
programatically generated objects into the publication process.

Generator objects should consume this role, and implement the C<generate>
method that it requires. This method will be passed the C<$site> object from
L<HiD>. Pages to be generated are in C<< $site->pages >>, posts are in C<<
$site->posts >> and so on.

=head1 METHODS

=head2 generate

=head1 VERSION

version 1.2

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
