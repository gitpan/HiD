# ABSTRACT: initialize a new site


package HiD::App::Command::init;
{
  $HiD::App::Command::init::VERSION = '0.3';
}
BEGIN {
  $HiD::App::Command::init::AUTHORITY = 'cpan:GENEHACK';
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

use YAML::XS qw/ DumpFile /;


has blog => (
  is            => 'ro' ,
  isa           => 'Bool' ,
  traits        => [ 'Getopt' ] ,
  cmd_aliases   => 'b' ,
  documentation => 'include blog-specific features when creating site' ,
);


has github => (
  is            => 'ro' ,
  isa           => 'Bool' ,
  traits        => [ 'Getopt' ] ,
  cmd_aliases   => 'g' ,
  documentation => 'create site ready for publishing on GitHub' ,
);


has title => (
  is            => 'ro' ,
  isa           => 'Str' ,
  traits        => [ 'Getopt' ] ,
  cmd_aliases   => 't' ,
  documentation => 'title for your new site' ,
  default       => 'My Great New Site' ,
);

sub _run {
  my( $self , $opts , $args ) = @_;

  die "TODO: github support" if $self->github;

  mkdir "_$_" for qw/ includes layouts site /;

  open( my $fh , '>' , '_layouts/default.html' );
  print $fh <<EOF;
[% content %]
EOF
  close $fh;

  $self->_init_blog if $self->blog;

  DumpFile( '_config.yml' , {
    title => $self->title ,
  });

  say "Enjoy your new site!";
}

sub _init_blog {
  {
    open( my $fh , '>' , '_layouts/post.html' );
    print $fh <<EOF;
---
layout: default
---
[% page.title %]
[% content %]
EOF
    close( $fh );
  }
  {
    mkdir "_posts";
    open( my $fh , '>' , '_posts/1999-09-09-first-post.markdown' );
    print $fh <<EOF;
---
layout: post
title: My First Post
---
this is the first post in my new blog!
EOF
    close( $fh );
  }
}

__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=encoding utf-8

=head1 NAME

HiD::App::Command::init - initialize a new site

=head1 SYNOPSIS

    $ ../bin/hid init
    Enjoy your new site!

    $ ls
    _config.yml  _includes/  _layouts/  _site/

    $ cat _config.yml
    ---
    title: My Great New Site

=head1 DESCRIPTION

Generates a directory structure and basic config for a Hid site.

=head1 ATTRIBUTES

=head2 blog

If enabled, this will add in additional site features useful for bloggers.

# FIXME doesn't actually do anything currently.

=head2 github

If enabled, will set the site up to be hosted on and published through GitHub.

# FIXME doesn't actually do anything currently.

=head2 title

Provide a title for the site being created.

=head1 SEE ALSO

See L<HiD::App::Command> for additional command line options supported by all
sub commands.

=head1 VERSION

version 0.3

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

