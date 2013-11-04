# ABSTRACT: Blog posts


package HiD::Post;
{
  $HiD::Post::VERSION = '1.0';
}
BEGIN {
  $HiD::Post::AUTHORITY = 'cpan:GENEHACK';
}

use Moose;
with 'HiD::Role::IsConverted';
with 'HiD::Role::IsPost';
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
use String::Errf    qw/ errf /;


sub BUILD {
  my $self = shift;

  if ( defined $self->get_metadata('published')
         and not $self->get_metadata('published')) {
    warn sprintf "WARNING: Skipping %s because 'published' flag is false\n" ,
      $self->input_filename;
    die;
  }
}


sub get_default_layout { 'post' }


sub publish {
  my $self = shift;

  my( undef , $dir ) = fileparse( $self->output_filename );

  make_path $dir unless -d $dir;

  open( my $out , '>:utf8' , $self->output_filename ) or die $!;
  print $out $self->rendered_content;
  close( $out );
}

# override
sub _build_url {
  my $self = shift;

  my %formats = (
    simple => '/posts/%{year}/%{month}/%{title}.html',
    date   => '/%{categories}s/%{year}s/%{month}s/%{day}s/%{title}s.html' ,
    pretty => '/%{categories}s/%{year}s/%{month}s/%{day}s/%{title}s/' ,
    none   => '/%{categories}s/%{title}s.html' ,
  );

  ### FIXME need a way to get overall config in here...
  my $permalink_format = $self->get_metadata( 'permalink' ) // 'date';

  $permalink_format = $formats{$permalink_format}
    if exists $formats{$permalink_format};

  my $categories = ( join '/' , @{ $self->categories } ) || '';
  my $day        = $self->strftime( '%d' , $self->day   );
  my $month      = $self->strftime( '%m' , $self->month );

  my $permalink = errf $permalink_format , {
    categories => $categories ,
    day        => $day ,
    i_day      => $self->day,
    i_month    => $self->month,
    month      => $month ,
    title      => $self->basename ,
    year       => $self->year ,
  };

  $permalink = "/$permalink";
  $permalink =~ s|//+|/|g;

  return $permalink;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding utf-8

=head1 NAME

HiD::Post - Blog posts

=head1 SYNOPSIS

    my $post = HiD::Post->new({
      dest_dir       => 'path/to/output/dir' ,
      hid            => $master_hid_object ,
      input_filename => 'path/to/file/for/this/post' ,
      layouts        => $hashref_of_hid_layout_objects,
    });

=head1 DESCRIPTION

Class representing a "blog post" object.

=head1 METHODS

=head2 get_default_layout

The default layout used when publishing a L<HiD::Post> object. (Defaults to 'post'.)

=head2 publish

Publish -- convert, render through any associated layouts, and write out to
disk -- this data from this object.

=for Pod::Coverage BUILD

=head1 VERSION

version 1.0

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
