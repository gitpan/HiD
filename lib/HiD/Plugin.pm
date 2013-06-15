# ABSTRACT: Plugin


package HiD::Plugin;
{
  $HiD::Plugin::VERSION = '0.7';
}
BEGIN {
  $HiD::Plugin::AUTHORITY = 'cpan:GENEHACK';
}

use Moose;
use namespace::autoclean;

use 5.014;
use utf8;
use autodie;
use warnings qw/ FATAL utf8 /;
use charnames   qw/ :full           /;
use feature  qw/ unicode_strings /;

sub after_publish { 1 }

1;

__END__

=pod

=encoding utf-8

=head1 NAME

HiD::Plugin - Plugin

=head1 SYNOPSIS

    my $plugin = HiD::Plugin;
    $plugin->after_publish($hid);

=head1 DESCRIPTION

Class representing a "Plugin" object.

=head1 VERSION

version 0.7

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
