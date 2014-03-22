# ABSTRACT: Pages injected during the build process that don't have corresponding files


package HiD::VirtualPage;
$HiD::VirtualPage::VERSION = '1.4';
BEGIN {
  $HiD::VirtualPage::AUTHORITY = 'cpan:GENEHACK';
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

use File::Basename  qw/ fileparse /;
use File::Path      qw/ make_path /;
use Path::Class     qw/ file / ;


has output_filename => (
  is => 'ro' ,
  isa => 'Str' ,
  required => 1 ,
);

has content => (
  is => 'ro' ,
  isa => 'Str' ,
  required => 1 ,
);


sub publish {
  my $self = shift;

  my( undef , $dir ) = fileparse( $self->output_filename );

  make_path $dir unless -d $dir;

  open( my $out , '>:utf8' , $self->output_filename ) or die $!;
  print $out $self->content;
  close( $out );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding utf-8

=head1 NAME

HiD::VirtualPage - Pages injected during the build process that don't have corresponding files

=head1 SYNOPSIS

    my $page = HiD::VirtualPage->new({
      output_filename => 'path/to/output/file' ,
      content         => 'content to go into file',
    });

=head1 DESCRIPTION

Class representing a virtual "page" object -- that is, a page that will be
generated during the publishing process, but that doesn't have a direct
on-disk component or input prior to that. VirtualPages need to have their
content completely built and provided at the time they are
instantiated. Examples would be Atom and RSS feeds.

=head1 ATTRIBUTES

=head2 output_filename

=head1 METHODS

=head2 publish

Publish -- write out to disk -- this data from this object.

=head1 VERSION

version 1.4

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
