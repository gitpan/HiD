# ABSTRACT: Base class for HiD Processor objects


package HiD::Processor;
{
  $HiD::Processor::VERSION = '0.2';
}
BEGIN {
  $HiD::Processor::AUTHORITY = 'cpan:GENEHACK';
}
use Moose;
use namespace::autoclean;

use 5.014;
use utf8;
use autodie;
use warnings    qw/ FATAL  utf8     /;
use open        qw/ :std  :utf8     /;
use charnames   qw/ :full           /;
use feature     qw/ unicode_strings /;


### FIXME figure out whether this makes more sense as a role that would make
###       it easier to see as something implementing a particular interface,
###       for example.


__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=encoding utf-8

=head1 NAME

HiD::Processor - Base class for HiD Processor objects

=head1 SYNOPSIS

    my $processor = HiD::Processor->new({ %args });

=head1 DESCRIPTION

Base class for HiD Processor objects.

To create a new HiD Processor type, extend this class with something that
implements a 'process' method.

=head1 VERSION

version 0.2

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

