# ABSTRACT: Pages that are converted during the output process


package HiD::Page;
{
  $HiD::Page::VERSION = '1.0';
}
BEGIN {
  $HiD::Page::AUTHORITY = 'cpan:GENEHACK';
}
use Moose;
with 'HiD::Role::IsConverted';
with 'HiD::Role::IsPublished';
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


sub get_default_layout { 'default' }


sub publish {
  my $self = shift;

  my( undef , $dir ) = fileparse( $self->output_filename );

  make_path $dir unless -d $dir;

  open( my $out , '>:utf8' , $self->output_filename ) or die $!;
  print $out $self->rendered_content;
  close( $out );
}

# used to populate the 'url' attr in Role::IsPublished
sub _build_url {
  my $self = shift;

  my $format = $self->get_metadata( 'permalink' ) // 'none';

  my $source = $self->source;
  my $path_frag = $self->input_path;
  $path_frag =~ s/^$source//;

  my $naive = join '/' , $path_frag , $self->basename;

  my %_valid_exts = map { $_=>1 } qw(rss xml html htm xhtml xhtm shtml shtm);
  my $ext = exists $_valid_exts{$self->ext} ? $self->ext : 'html';

  my $url;

  if(    $format eq 'none'   ) { $url = $naive . ".$ext" }
  elsif( $format eq 'pretty' ) { $url = $naive . '/'     }
  else                         { $url = "/$format"       }

  $url =~ s|//+|/|g;

  return $url;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding utf-8

=head1 NAME

HiD::Page - Pages that are converted during the output process

=head1 SYNOPSIS

    my $page = HiD::Page->new({
      dest_dir       => 'path/to/output/dir' ,
      hid            => $hid_object ,
      input_filename => 'path/to/page/file' ,
      layouts        => $hash_of_hid_layout_objects,
    });

=head1 DESCRIPTION

Class representing a "page" object -- i.e., a file that is not a blog post,
but that is still processed (e.g., converted from Markdown or Textile to HTML
and run through a layout rendering step) during publication.

=head1 METHODS

=head2 get_default_layout

Get the name of the default page layout. (The default is 'default'.)

=head2 publish

Publish -- convert, render through any associated layouts, and write out to
disk -- this data from this object.

=head1 NOTE

Also consumes L<HiD::Role::IsConverted> and L<HiD::Role::IsPublished>; see
documentation for that role as well if you're trying to figure out how an
object from this class works.

=head1 VERSION

version 1.0

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
