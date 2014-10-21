# ABSTRACT: Role for blog posts


package HiD::Role::IsPost;
$HiD::Role::IsPost::VERSION = '1.3';
BEGIN {
  $HiD::Role::IsPost::AUTHORITY = 'cpan:GENEHACK';
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

use DateTime;
use Date::Parse    qw/ str2time  /;
use File::Basename qw/ fileparse /;
use HiD::Types;
use YAML::XS;


has author => (
  is      => 'ro' ,
  isa     => 'Str' ,
  lazy    => 1 ,
  builder => '_build_author' ,
);

sub _build_author {
  my $self = shift;

  my $author = $self->get_metadata( 'author' );

  return $author if defined $author;

  return 'DRAFT AUTHOR -- FIX' if $self->is_draft;

  die "Need author for " . $self->basename . "\n"
}


has categories => (
  is      => 'ro' ,
  isa     => 'ArrayRef' ,
  lazy    => 1 ,
  default => sub {
    my $self = shift;

    if ( my $category = $self->get_metadata( 'category' )) {
      return [ $category ];
    }
    elsif ( my $categories = $self->get_metadata( 'categories' )) {
      if ( ref $categories ) {
        return [ @$categories ];
      }
      else {
        my @categories = split /\s/ , $categories;
        return [ @categories ];
      }
    }
    else { return [] }
  },
);


has date => (
  is      => 'ro' ,
  isa     => 'DateTime' ,
  lazy    => 1,
  handles => {
    day      => 'day' ,
    month    => 'month' ,
    strftime => 'strftime' ,
    year     => 'year' ,
  },
  default => sub {
    my $self = shift;

    if ( $self->get_config( 'publish_drafts' )){
      return DateTime->now if $self->is_draft;
    }

    my( $year , $month , $day );
    if ( my $date = $self->get_metadata( 'date' )) {
      return DateTime->from_epoch(
        epoch     => str2time( $date ),
        time_zone => 'local' ,
      );
    }
    else {
      ( $year , $month , $day ) = $self->input_filename
        =~ m|^.*?/([0-9]{4})-([0-9]{1,2})-([0-9]{1,2})-|;
      return DateTime->new(
        year  => $year ,
        month => $month ,
        day   => $day
      );
    }
  },
);


has excerpt => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  builder => '_build_excerpt',
);

sub _build_excerpt {
  my $self = shift;

  my $content = $self->content;

  return unless defined $content;

  my $sep = $self->hid->excerpt_separator;

  if($content =~ /^$sep/mp) {
    return ${^PREMATCH};
  }

  return $content;
}


has tags => (
  is      => 'ro' ,
  isa     => 'ArrayRef',
  default => sub {
    my $self = shift;

    if ( my $tag = $self->get_metadata( 'tag' )) {
      return [ $tag ];
    }
    elsif ( my $tags = $self->get_metadata( 'tags' )) {
      if ( ref $tags ) {
        return [ @$tags ];
      }
      else {
        my @tags = split /\s/ , $tags;
        return [ @tags ];
      }
    }
    else { return [] }
  } ,
);


has title => (
  is      => 'ro' ,
  isa     => 'Str' ,
  lazy    => 1 ,
  builder => '_build_title' ,
);

sub _build_title {
  my $self = shift;

  my $title = $self->get_metadata( 'title' );

  return $self->basename unless defined $title;

  return ( ref $title ) ? $$title : $title;
}


has twitter => (
  is => 'ro' ,
  isa => 'Maybe[Str]' ,
  lazy => 1 ,
  builder => '_build_twitter' ,
);

sub _build_twitter {
  my $self = shift;

  my $twitter = $self->get_metadata( 'twitter' );

  return defined $twitter ? $twitter : undef;
}

around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;

  my %args = ( ref $_[0] and ref $_[0] eq 'HASH' ) ? %{ $_[0] } : @_;

  if ( my $input = $args{input_filename} ) {
    if ( my $source = $args{source} ) {
      $input =~ s|$source/?||;
    }

    if ( my( $cat ) = $input =~ m|^(.+?)/?_posts/| ) {
      $args{categories} = [ split '/' , $cat ];
    }
  }

  return $class->$orig( \%args );
};


my $drafts_dir;
sub is_draft {
  my $self = shift;

  $drafts_dir //= $self->get_config( 'drafts_dir' );
  return ( $self->input_filename =~ /^$drafts_dir/ ) ? 1 : 0;
}


no Moose::Role;
1;

__END__

=pod

=encoding utf-8

=head1 NAME

HiD::Role::IsPost - Role for blog posts

=head1 SYNOPSIS

    package HiD::ThingThatIsAPost;
    use Moose;
    with 'HiD::Role::IsPost';

    ...

    1;

=head1 DESCRIPTION

This role is consumed by objects that are blog posts and provides blog
post-specific attributes and methods.

=head1 ATTRIBUTES

=head2 author

=head2 categories

=head2 date

DateTime object for this post.

=head2 excerpt

It is generally useful to summarize or lead a post with a "read more" tag
added to the end of the post.  This is ideal for a blog where we might not
want to list the full post on the front page.

=head2 tags

=head2 title

=head2 twitter

=head1 METHODS

=head2 is_draft

Returns a boolean value indicating whether this post is coming from the drafts
folder or not.

=head1 VERSION

version 1.3

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
