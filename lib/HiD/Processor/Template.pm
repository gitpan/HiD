# ABSTRACT: Use Template Toolkit to publish your HiD files


package HiD::Processor::Template;
{
  $HiD::Processor::Template::VERSION = '0.2';
}
BEGIN {
  $HiD::Processor::Template::AUTHORITY = 'cpan:GENEHACK';
}
use Moose;
extends 'HiD::Processor';
use namespace::autoclean;

use 5.014;
use utf8;
use autodie;
use warnings    qw/ FATAL  utf8     /;
use open        qw/ :std  :utf8     /;
use charnames   qw/ :full           /;
use feature     qw/ unicode_strings /;

use Template;

has 'tt' => (
  is       => 'ro' ,
  isa      => 'Template' ,
  handles  => [ qw/ process / ],
  required => 1 ,
);

# FIXME this should really probably be a builder on the 'tt' attr
# ...which should be called something more generic
# ...and which should get args via a second attr that's required
sub BUILDARGS {
  my $class = shift;

  my %args = ( ref $_[0] && ref $_[0] eq 'HASH' ) ? %{ $_[0] } : @_;

  return { tt => Template->new( %args ) };
}

__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=encoding utf-8

=head1 NAME

HiD::Processor::Template - Use Template Toolkit to publish your HiD files

=head1 SYNOPSIS

    my $processor = HiD::Proccessor::Template->new({ arg => $val });

=head1 DESCRIPTION

Wraps up a L<Template> object and allows it to be used during HiD publication.

=head1 VERSION

version 0.2

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

