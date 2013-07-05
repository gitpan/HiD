# ABSTRACT: Static website publishing framework


package HiD;
{
  $HiD::VERSION = '0.4';
}
BEGIN {
  $HiD::AUTHORITY = 'cpan:GENEHACK';
}
use Moose;
use namespace::autoclean;

use 5.014;
use utf8;
use strict;
use autodie;
use warnings;
use warnings    qw/ FATAL  utf8     /;
use open        qw/ :std  :utf8     /;
use charnames   qw/ :full           /;
use feature     qw/ unicode_strings /;

use Class::Load        qw/ :all /;
use File::Basename;
use File::Find::Rule;
use File::Path         qw/ make_path /;
use File::Remove       qw/ remove /;
use HiD::File;
use HiD::Layout;
use HiD::Page;
use HiD::Post;
use HiD::Types;
use Path::Class        qw/ file /;
use Try::Tiny;
use YAML::XS           qw/ LoadFile /;


has cli_opts => (
  is      => 'ro' ,
  isa     => 'HashRef' ,
  lazy    => 1 ,
  default => sub {{}} ,
);


has config => (
  is      => 'ro' ,
  isa     => 'HashRef' ,
  traits  => [ 'Hash' ],
  lazy    => 1 ,
  builder => '_build_config' ,
  handles => {
    get_config => 'get' ,
  }
);

sub _build_config {
  my $self = shift;

  my( $config , $config_loaded );

  if ( my $file = $self->config_file ) {
    try {
      $config = LoadFile( $file ) // {};
      ref $config eq 'HASH' or die $!;
      $config_loaded++;
    };
  }

  $config_loaded or $config = {}
    and warn "WARNING: Could not read configuration. Using defaults (and options).\n";

  return {
    %{ $self->default_config } ,
    %$config ,
    %{ $self->cli_opts } ,
  };
}


has config_file => (
  is      => 'ro' ,
  isa     => 'Str' ,
);


has default_config => (
  is       => 'ro' ,
  isa      => 'HashRef' ,
  traits   => [ 'Hash' ] ,
  init_arg => undef ,
  default  => sub{{
    destination => '_site'    ,
    include_dir => '_includes',
    layout_dir  => '_layouts' ,
    posts_dir   => '_posts' ,
    source      => '.' ,
  }},
);


has destination => (
  is      => 'ro' ,
  isa     => 'HiD_DirPath' ,
  lazy    => 1 ,
  default => sub {
    my $dest = shift->get_config( 'destination' );
    make_path $dest unless -e -d $dest;
    return $dest;
  },
);


has include_dir => (
  is      => 'ro' ,
  isa     => 'Maybe[HiD_DirPath]' ,
  lazy    => 1,
  default => sub {
    my $self = shift;
    my $dir  = $self->get_config( 'include_dir' );
    ( -e -d '_includes' ) ? $dir : undef;
  } ,
);


has inputs => (
  is      => 'ro' ,
  isa     => 'HashRef',
  default => sub {{}} ,
  traits  => ['Hash'],
  handles => {
    add_input  => 'set' ,
    seen_input => 'exists' ,
  },
);


has layout_dir => (
  is      => 'ro' ,
  isa     => 'HiD_DirPath' ,
  lazy    => 1 ,
  default => sub { shift->get_config( 'layout_dir' ) },
);


has layouts => (
  is      => 'ro' ,
  isa     => 'HashRef[HiD::Layout]',
  lazy    => 1 ,
  builder => '_build_layouts',
  traits  => ['Hash'] ,
  handles => {
    get_layout_by_name => 'get' ,
  },
);

sub _build_layouts {
  my $self = shift;

  my @layout_files = File::Find::Rule->file
    ->in( $self->layout_dir );

  my %layouts;
  foreach my $layout_file ( @layout_files ) {
    my $dir = $self->layout_dir;

    my( $layout_name , $extension ) = $layout_file
      =~ m|^$dir/(.*)\.([^.]+)$|;

    $layouts{$layout_name} = HiD::Layout->new({
      filename  => $layout_file,
      processor => $self->processor ,
    });

    $self->add_input( $layout_file => 'layout' );
  }

  foreach my $layout_name ( keys %layouts ) {
    my $metadata = $layouts{$layout_name}->metadata;

    if ( my $embedded_layout = $metadata->{layout} ) {
      die "FIXME embedded layout fail $embedded_layout"
        unless $layouts{$embedded_layout};

      $layouts{$layout_name}->set_layout(
        $layouts{$embedded_layout}
      );
    }
  }

  return \%layouts;
}


has limit_posts => (
  is     => 'ro' ,
  isa    => 'HiD_PosInt' ,
);


has objects => (
  is  => 'ro' ,
  isa => 'ArrayRef[Object]' ,
  traits => [ 'Array' ] ,
  default => sub{[]} ,
  handles => {
    add_object  => 'push' ,
    all_objects => 'elements' ,
  },
);


has page_file_regex => (
  is      => 'ro' ,
  isa     => 'RegexpRef',
  default => sub { qr/\.(mk|mkd|mkdn|markdown|textile|html)$/ } ,
);


has pages => (
  is      => 'ro',
  isa     => 'Maybe[ArrayRef[HiD::Page]]',
  lazy    => 1 ,
  builder => '_build_pages' ,
);

sub _build_pages {
  my $self = shift;

  # build posts before pages
  $self->posts;

  my @potential_pages = File::Find::Rule->file->
    name( $self->page_file_regex )->in( '.' );

  my @pages = grep { $_ } map {
    if ($self->seen_input( $_ ) or $_ =~ /^_/ ) { 0 }
    else {
      try {
        my $page = HiD::Page->new({
          dest_dir       => $self->destination,
          hid            => $self ,
          input_filename => $_ ,
          layouts        => $self->layouts ,
        });
        $page->content;
        $self->add_input( $_ => 'page' );
        $self->add_object( $page );
        $page;
      }
      catch { 0 };
    }
  } @potential_pages;

  return \@pages;
}


has post_file_regex => (
  is      => 'ro' ,
  isa     => 'RegexpRef' ,
  default => sub { qr/^[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}-(?:.+?)\.(?:mk|mkd|mkdn|markdown|md|text|textile|html)$/ },
);


has posts_dir => (
  is      => 'ro' ,
  isa     => 'HiD_DirPath' ,
  lazy    => 1 ,
  default => sub { shift->get_config( 'posts_dir' ) },
);


has posts => (
  is      => 'ro' ,
  isa     => 'Maybe[ArrayRef[HiD::Post]]' ,
  lazy    => 1 ,
  builder => '_build_posts' ,
);

sub _build_posts {
  my $self = shift;

  # build layouts before posts
  $self->layouts;

  my $rule = File::Find::Rule->new;

  my @posts_directories = $rule->or(
    $rule->new->directory->name( '_posts' ) ,
      $rule->new->directory->name( '_site' )->prune->discard ,
  )->in( $self->source );

  my @potential_posts = File::Find::Rule->file
    ->name( $self->post_file_regex )->in( @posts_directories );

  my @posts = grep { $_ } map {
    try {
      my $post = HiD::Post->new({
        dest_dir       => $self->destination,
        input_filename => $_ ,
        layouts        => $self->layouts ,
      });
      $self->add_input( $_ => 'post' );
      $self->add_object( $post );
      $post
    } catch { 0 };
  } @potential_posts;

  @posts = sort { $b->date <=> $a->date } @posts;

  if ( my $limit = $self->limit_posts ) {
    die "--limit_posts must be positive" if $limit < 1;
    @posts = splice( @posts , -$limit , $limit );
  }

  return \@posts;
}


has processor => (
  is      => 'ro' ,
  isa     => 'HiD::Processor' ,
  lazy    => 1 ,
  default => sub {
    my $self = shift;

    my $processor_name  = $self->get_config( 'processor_name' ) // 'Template';

    my $processor_class = ( $processor_name =~ /^\+/ ) ? $processor_name
      : "HiD::Processor::$processor_name";

    try_load_class( $processor_class );

    return $processor_class->new( $self->processor_args );
  },
);


has processor_args => (
  is      => 'ro' ,
  isa     => 'ArrayRef|HashRef' ,
  lazy    => 1 ,
  default => sub {
    my $self = shift;

    return $self->get_config( 'processor_args' ) if
      defined $self->get_config( 'processor_args' );

    my $include_path = $self->layout_dir;
    $include_path   .= ':' . $self->include_dir
      if defined $self->include_dir;

    return {
      INCLUDE_PATH => $include_path ,
    };
  },
);


has regular_files => (
  is      => 'ro',
  isa     => 'Maybe[ArrayRef[HiD::File]]',
  lazy    => 1 ,
  builder => '_build_regular_files' ,
);

sub _build_regular_files {
  my $self = shift;

  # build pages before regular files
  $self->pages;

  my @potential_files = File::Find::Rule->file->in( '.' );

  my @files = grep { $_ } map {
    if ($self->seen_input( $_ ) or $_ =~ /^_/ ) { 0 }
    else {
      my $file = HiD::File->new({
        dest_dir       => $self->destination,
        input_filename => $_ ,
      });
      $self->add_input( $_ => 'file' );
      $self->add_object( $file );
      $file;
    }
  } @potential_files;

  return \@files;
}


has source => (
  is      => 'ro' ,
  isa     => 'HiD_DirPath' ,
  lazy    => 1 ,
  default => sub {
    my $self   = shift;
    my $source = $self->get_config( 'source' );
    chdir $source or die $!;
    return $source;
  },
);


has written_files => (
  is      => 'ro' ,
  isa     => 'HashRef' ,
  traits  => [ qw/ Hash / ] ,
  default => sub {{}},
  handles => {
    add_written_file  => 'set' ,
    all_written_files => 'keys' ,
    wrote_file        => 'defined' ,
  },
);


sub publish {
  my( $self ) = @_;

  # bootstrap data structures -- FIXME should have a more explicit way to do this
  $self->regular_files;

  $self->add_written_file( $self->destination => '_site_dir' );

  foreach my $file ( $self->all_objects ) {
    $file->publish;

    my $path;
    foreach my $part ( split '/' , $file->output_filename ) {
      $path = file( $path , $part )->stringify;
      $self->add_written_file( $path => 1 );
    }
  }

  foreach ( File::Find::Rule->in( $self->destination )) {
    $self->wrote_file($_) or remove \1 , $_;
  }

  1;

}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding utf-8

=head1 NAME

HiD - Static website publishing framework

=head1 SYNOPSIS

HīD is a blog-aware, GitHub-friendly, static website generation system
inspired by Jekyll.

=head1 DESCRIPTION

HiD users probably want to look at the documentation for the L<hid> command.

Subsequent documentation in this file describes internal details that are only
useful or interesting for people that are trying to modify or extend HiD.

=head1 ATTRIBUTES

=head2 cli_opts

Hashref of command line options to integrate into the config.

(L<HiD::App::Command>s should pass in the C<$opt> variable to this.)

=head2 config

Hashref of configuration information.

=head2 config_file

Path to a configuration file.

=head2 default_config

Hashref of standard configuration options. The default config is:

    destination => '_site'    ,
    include_dir => '_includes',
    layout_dir  => '_layouts' ,
    posts_dir   => '_posts' ,
    source      => '.' ,

=head2 destination

Directory to write output files into.

B<N.B.:> If it doesn't exist and is needed, it will be created.

=head2 include_dir

Directory for template "include" files

=head2 inputs

Hashref of input files. Keys are file paths; values are what type of file the
system has classified that path as.

=head2 layout_dir

Directory where template files are located.

=head2 layouts

Hashref of L<HiD::Layout> objects, keyed by layout name.

=head2 limit_posts

If set, only this many blog post files will be processed during publishing.

Setting this can significantly speed up publishing for sites with many blog posts.

=head2 objects

Array of objects (pages, posts, files) created during site processing.

=head2 page_file_regex

Regular expression for identifying "page" files.

# FIXME should it be possible to set this from the config?

=head2 pages

Arrayref of L<HiD::Page> objects, populated during processing.

=head2 post_file_regex

Regular expression for which files will be recognized as blog posts.

FIXME should this be configurable?

=head2 posts_dir

Directory where blog posts are located.

=head2 posts

Arrayref of L<HiD::Post> objects, populated during processing.

=head2 processor

Slot to hold the L<HiD::Processor> object that will be used during the
publication process.

=head2 processor_args

Arguments to use when instantiating the L<processor> attribute.

Can be an arrayref or a hashref.

Defaults to appropriate Template Toolkit arguments.

=head2 regular_files

ArrayRef of L<HiD::File> objects, populated during processing.

=head2 source

Base directory that all other paths are calculated relative to.

=head2 written_files

Hashref of files written out during the publishing process.

=head1 METHODS

=head2 get_config

    my $config_key_value = $self->get_config( $config_key_name );

Given a config key name, returns a config key value.

=head2 add_input

    $self->add_input( $input_file => $input_type );

Record what input type a particular input file is.

=head2 seen_input

    if( $self->seen_input( $input_file )) { ... }

Check to see if a particular input file has been seen.

=head2 get_layout_by_name

    my $hid_layout_obj = $self->get_layout_by_name( $name );

Given a layout name (e.g., 'default') returns the corresponding L<HiD::Layout> object.

=head2 add_object

    $self->add_object( $generated_object );

Add an object to the set of objects generated during site processing.

=head2 all_objects

    my @objects = $self->all_objects;

Returns the list of all objects that have been generated.

=head2 add_written_file

    $self->add_written_file( $file => 1 );

Record that a file was written.

=head2 all_written_files

    my @files = $self->all_written_files;

Return the list of all files that were written out.

=head2 wrote_file

  if( $self->wrote_file( $file )) { ... }

Check to see if a particular file has been written out.

=head2 publish

    $self->publish;

Process files and generate output per the active configuration.

=head1 SEE ALSO

=over 4

=item *

L<jekyll|http://jekyllrb.com/>

=item *

L<Papery>

=item *

L<StaticVolt>

=back

=head1 VERSION

version 0.4

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
