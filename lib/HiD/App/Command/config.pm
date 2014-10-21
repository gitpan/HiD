# ABSTRACT: dump configuration


package HiD::App::Command::config;
$HiD::App::Command::config::VERSION = '1.4';
BEGIN {
  $HiD::App::Command::config::AUTHORITY = 'cpan:GENEHACK';
}
use Moose;
extends 'HiD::App::Command';
use namespace::autoclean;

use 5.014;
use utf8;
use autodie;
use warnings    qw/ FATAL  utf8     /;
use open        qw/ :std  :utf8     /;
use charnames   qw/ :full           /;
use feature     qw/ unicode_strings /;

sub _run {
  my( $self , $opts , $args ) = @_;

  $args = [ 'config' ] unless $args->[0];

  use DDP;
  my $out;
  $out .= p $self->hid->$_ foreach @$args;

  print $out;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding utf-8

=head1 NAME

HiD::App::Command::config - dump configuration

=head1 SYNOPSIS

    $ hid config
    \ {
        destination   "_site",
        include_dir   "_includes",
        layout_dir   "_layouts",
        posts_dir   "_posts",
        source   "."
    }
    $ hid config pages
    [ massive output elided ]

=head1 DESCRIPTION

Dumps the active configuration (using L<Data::Printer>)

If given an argument, will dump the corresponding attribute from the active
L<HiD> instance. This can be useful when debugging, because it allows you to
see precisely what data structures are being built.

=head1 SEE ALSO

See L<HiD::App::Command> for additional command line options supported by all
sub commands.

=head1 VERSION

version 1.4

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
