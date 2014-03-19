# ABSTRACT: Base class for plugins


package HiD::Plugin;
$HiD::Plugin::VERSION = '1.3';
BEGIN {
  $HiD::Plugin::AUTHORITY = 'cpan:GENEHACK';
}

use Moose;
use namespace::autoclean;

use 5.014;
use utf8;
use autodie;
use warnings   qw/ FATAL utf8 /;
use charnames  qw/ :full           /;
use feature    qw/ unicode_strings /;


sub after_publish { 1 }

1;

__END__

=pod

=encoding utf-8

=head1 NAME

HiD::Plugin - Base class for plugins

=head1 SYNOPSIS

    my $plugin = HiD::Plugin->new;
    $plugin->after_publish($hid);

=head1 DESCRIPTION

Base class for plugin object

=head1 METHODS

=head2 after_publish

=head1 VERSION

version 1.3

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
