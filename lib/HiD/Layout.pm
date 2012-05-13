# ABSTRACT: Class representing a particular layout


package HiD::Layout;
{
  $HiD::Layout::VERSION = '0.1';
}
BEGIN {
  $HiD::Layout::AUTHORITY = 'cpan:GENEHACK';
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

use File::Slurp qw/ read_file / ;
use HiD::Types;
use YAML::XS;


has content => (
  is       => 'ro' ,
  isa      => 'Str' ,
  required => 1 ,
);


has ext => (
  is       => 'ro'  ,
  isa      => 'HiD_FileExtension' ,
);


has filename => (
  is       => 'ro' ,
  isa      => 'HiD_FilePath' ,
);


has layout => (
  is     => 'rw' ,
  isa    => 'Maybe[HiD::Layout]' ,
  writer => 'set_layout' ,
);


has metadata => (
  is      => 'ro' ,
  isa     => 'HashRef',
  lazy    => 1 ,
  default => sub {{}}
);


has name => (
  is       => 'ro'  ,
  isa      => 'Str' ,
  required => 1 ,
);


has processor => (
  is       => 'ro',
  isa      => 'Object' ,
  required => 1 ,
);


sub BUILDARGS {
  my $class = shift;

  my %args = ( ref $_[0] and ref $_[0] eq 'HASH' ) ? %{ $_[0] } : @_;

  unless ( $args{content} ) {
    ( $args{name} , $args{ext} ) = $args{filename}
      =~ m|^.*/(.+)\.([^.]+)$|;

    my $content  = read_file( $args{filename} );
    my $metadata = {};

    if ( $content =~ /^---\n/s ) {
      my $meta;
      ( $meta , $content ) = ( $content )
        =~ m|^---\n(.*?)---\n(.*)$|s;
      $metadata = Load( $meta ) if $meta;
    }

    $args{metadata} = $metadata;
    $args{content}  = $content;
  }

  return \%args;
}


sub render {
  my( $self , $data ) = @_;

  my $page_data = $data->{page} // {};

  %{ $data->{page} } = (
    %{ $self->metadata } ,
    %{ $page_data },
  );

  my $processed_input_content;
  my $input_content = delete $data->{content};

  $self->processor->process(
    \$input_content ,
    $data ,
    \$processed_input_content ,
  ) or die $self->processor->tt->error;

  $data->{content} = $processed_input_content;

  my $output;

  $self->processor->process(
    \$self->content ,
    $data ,
    \$output ,
  ) or die $self->processor->error;

  if ( my $embedded_layout = $self->layout ) {
    $data->{content} = $output;
    $output = $embedded_layout->render( $data );
  }

  return $output;
}

__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=encoding utf-8

=head1 NAME

HiD::Layout - Class representing a particular layout

=head1 SYNOPSIS

    my $layout = HiD::Layout->new({
      filename  => $path_to_file ,
      processor => $hid_processor_object ,
    });

=head1 DESCRIPTION

Class representing layout files.

=head1 ATTRIBUTES

=head2 content

Content of this layout.

=head2 ext

File extension of this layout.

=head2 filename

Filename of this layout.

=head2 layout

Name of a layout that will be used when processing this layout. (Can be
applied recursively.)

=head2 metadata

Metadata for this layout. Populated from the YAML front matter in the layout
file.

=head2 name

Name of the layout.

=head2 processor

Processor object used to process content through this layout when rendering.

=head1 METHODS

=head2 render

Pass in a hash of data, apply the layout using that hash as input, and return
the resulting output string.

Will recurse into embedded layouts as needed.

=head1 VERSION

version 0.1

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

