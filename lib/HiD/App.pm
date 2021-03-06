# ABSTRACT: Static website generation system


package HiD::App;
$HiD::App::VERSION = '1.7';
use Moose;
extends 'MooseX::App::Cmd';
use namespace::autoclean;

use 5.014;
use utf8;
use autodie;
use warnings    qw/ FATAL  utf8     /;
use open        qw/ :std  :utf8     /;
use charnames   qw/ :full           /;
use feature     qw/ unicode_strings /;

sub default_command { 'help' };

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding utf-8

=head1 NAME

HiD::App - Static website generation system

=head1 SYNOPSIS

See C<perldoc hid> for usage information.

=head1 VERSION

version 1.7

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
