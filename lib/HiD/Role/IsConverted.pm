# ABSTRACT: Role for objects that are converted during the publishing process


package HiD::Role::IsConverted;
$HiD::Role::IsConverted::VERSION = '1.4';
BEGIN {
  $HiD::Role::IsConverted::AUTHORITY = 'cpan:GENEHACK';
}
use Moose::Role;
use namespace::autoclean;

use 5.014;
use utf8;
use autodie;
use warnings    qw/ FATAL  utf8     /;
use open        qw/ :std  :utf8     /;
use charnames   qw/ :full           /;
use feature     qw/ unicode_strings /;

use Carp;
use Class::Load  qw/ :all /;
use Encode;
use File::Slurp  qw/ read_file /;
use HiD::Types;
use YAML::XS     qw/ Load /;

requires 'get_default_layout';


has content => (
  is       => 'ro',
  isa      => 'Str',
  required => 1 ,
);


has converted_content => (
  is      => 'ro' ,
  isa     => 'Str' ,
  lazy    => 1 ,
  default => sub {
    my $self = shift;
    return _convert_by_extension( $self->content , $self->ext );
  }
);


has converted_excerpt => (
  is      => 'ro' ,
  isa     => 'Str' ,
  lazy    => 1 ,
  default => sub {
    my $self = shift;

    my $converted_excerpt = _convert_by_extension( $self->excerpt , $self->ext );

    if ( $self->excerpt ne $self->content ) {
      # Add the "read more" link
      ### FIXME this should be configurable
      $converted_excerpt .= $self->readmore_link;
    }

    return $converted_excerpt;
  },
);


has hid => (
  is       => 'ro' ,
  isa      => 'HiD' ,
  required => 1 ,
  handles  => [ qw/ get_config /] ,
);


has layouts => (
  is       => 'ro' ,
  isa      => 'HashRef[HiD::Layout]' ,
  required => 1 ,
);


has metadata => (
  is      => 'ro' ,
  isa     => 'HashRef' ,
  default => sub {{}} ,
  lazy    => 1,
  traits  => [ 'Hash' ] ,
  handles => {
    get_metadata => 'get',
  },
);


has readmore_link => (
  is      => 'ro' ,
  isa     => 'Str' ,
  lazy    => 1 ,
  default => sub {
    my $self = shift;

    if ( defined $self->get_config('readmore_link')) {
      my $link = $self->get_config('readmore_link');
      my $url = $self->url;
      $link =~ s/__URL__/$url/;
      return $link;
    };

    return
      q{<p class="readmore"><a href="}
      . $self->url
      . q{" class="readmore">read more</a></p>};
  },
);


has rendered_content => (
  is      => 'ro' ,
  isa     => 'Str' ,
  lazy    => 1 ,
  default => sub {
    my $self = shift;

    my $layout_name = $self->get_metadata( 'layout' ) // $self->get_default_layout;

    my $layout = $self->layouts->{$layout_name} // $self->layouts->{default} //
      die "FIXME no default layout?";

    my $output = $layout->render( $self->template_data );

    return $output;
  }
);


has template_data => (
  is      => 'ro' ,
  isa     => 'HashRef' ,
  lazy    => 1 ,
  default => sub {
    my $self = shift;

    my $data = {
      content  => $self->converted_content ,
      page     => $self->metadata ,
      site     => $self->hid ,
    };

    $data->{page}{baseurl} = $self->hid->config->{baseurl};

    ## FIXME this sucks, you need a better way to deal with this...
    foreach my $method ( qw/ all_tags author categories date
                             metadata tags title url year / ) {
      $data->{page}{$method} = $self->$method
        if $self->can( $method );
    }

    return $data;
  },
);

around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;

  my %args = ( ref $_[0] and ref $_[0] eq 'HASH' ) ? %{ $_[0] } : @_;

  unless ( $args{content} and $args{metadata} ) {
    my $file_content = read_file( $args{input_filename}, binmode => ':utf8' );

    my( $metadata , $content );
    if ( $file_content =~ /^---/ ) {
      ( $metadata , $content ) = $file_content
        =~ /^---\n?(.*?)---\n?(.*)$/ms;
    }
    elsif ( $args{input_filename} =~ /\.html?$/ ) {
      die "plain HTML file without YAML front matter"
    }
    else {
      $content  = $file_content;
      $metadata = '';
    }

    $args{content}  = $content;
    $args{metadata} = Load( encode('utf8',$metadata) ) // {};
  }

  return $class->$orig( \%args );
};

{ # hide the map

  ### FIXME make this extensible
  my %conversion_extension_map = (
    markdown => [ 'Text::Markdown'      , 'markdown' ] ,
    mkdn     => [ 'Text::Markdown'      , 'markdown' ] ,
    mk       => [ 'Text::Markdown'      , 'markdown' ] ,
    md       => [ 'Text::Markdown'      , 'markdown' ] ,
    mmd      => [ 'Text::MultiMarkdown' , 'markdown' ] ,
    textile  => [ 'Text::Textile'       , 'process'  ] ,
  );

  sub _convert_by_extension {
    my( $content , $extension ) = @_;

    return $content
      unless exists $conversion_extension_map{ $extension };

    my( $module , $method ) = @{ $conversion_extension_map{ $extension }};
    load_class( $module );

    my $converted = $module->new->$method( $content );
    return $converted;
  }
}

no Moose::Role;
1;

__END__

=pod

=encoding utf-8

=head1 NAME

HiD::Role::IsConverted - Role for objects that are converted during the publishing process

=head1 SYNOPSIS

    package HiD::ThingThatIsConverted
    use Moose;
    with 'HiD::Role::IsConverted';

    ...

    1;

=head1 DESCRIPTION

This role is consumed by objects that are converted during the publication
process -- e.g., from Markdown or Textile to HTML, or rendered through a
layout object. This role provides required attributes and methods used during
that process.

=head1 ATTRIBUTES

=head2 content ( ro / Str / required )

Page content (stuff after the YAML front matter)

=head2 converted_content ( ro  / Str / lazily built from content )

Content after it has gone through the conversion process.

=head2 converted_excerpt ( ro / Str / lazily built from content )

Excerpt after it has gone through the conversion process

=head2 hid

The HiD object for the current site. Here primarily to provide access to site
metadata.

=head2 layouts ( ro / HashRef[HiD::Layout] / required )

Hashref of layout objects keyed by name.

=head2 metadata ( ro / HashRef )

Hashref of info from YAML front matter

=head2 readmore_link

Placed at the bottom of rendered excerpts. Intended to link to the full
version of the content.

A string matching C<__URL__> will be replaced with the URL of the object (i.e.,
the output of C<$self->url>) being converted.

=head2 rendered_content

Content after any layouts have been applied

=head2 template_data

Data for passing to template processing function.

=head1 VERSION

version 1.4

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
