# ABSTRACT: publish site


package HiD::App::Command::publish;
{
  $HiD::App::Command::publish::VERSION = '1.0';
}
BEGIN {
  $HiD::App::Command::publish::AUTHORITY = 'cpan:GENEHACK';
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


has limit_posts => (
  is          => 'ro' ,
  isa         => 'Int' ,
  cmd_aliases => 'l' ,
  traits      => [ 'Getopt' ] ,
);

sub _run {
  my( $self , $opts , $args ) = @_;

  my $config = {};
  if ( $self->limit_posts ) {
    $config->{limit_posts} = $self->limit_posts;
  }

  $self->publish;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding utf-8

=head1 NAME

HiD::App::Command::publish - publish site

=head1 SYNOPSIS

    $ hid publish

    $ hid  # 'publish' is the default command...

=head1 DESCRIPTION

Processes files according to the active configuration and writes output files
accordingly.

=head1 ATTRIBUTES

=head2 limit_posts

Limit the number of blog posts that will be written out. If you have a large
number of blog posts that haven't changed, setting this can significantly
speed up the publication process.

=head1 SEE ALSO

See L<HiD::App::Command> for additional command line options supported by all
sub commands.

=head1 VERSION

version 1.0

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
