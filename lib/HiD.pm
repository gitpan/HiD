# ABSTRACT: Static website publishing framework


package HiD;
$HiD::VERSION = '1.4';
BEGIN {
  $HiD::AUTHORITY = 'cpan:GENEHACK';
}
use Moose;
use namespace::autoclean;
# note: we also do 'with HiD::Role::DoesLogging', just later on because reasons.

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
use DateTime;
use File::Basename;
use File::Find::Rule;
use File::Path         qw/ make_path /;
use File::Remove       qw/ remove /;
use HiD::File;
use HiD::Layout;
use HiD::Page;
use HiD::Pager;
use HiD::Post;
use HiD::Types;
use Module::Find;
use Path::Class        qw/ file /;
use Try::Tiny;
use YAML::XS           qw/ LoadFile /;


has categories => (
  is      => 'ro' ,
  isa     => 'Maybe[HashRef[ArrayRef[HiD::Post]]]' ,
  lazy    => 1 ,
  builder => '_build_categories' ,
);

sub _build_categories {
  my $self = shift;

  return undef unless $self->posts;

  my $categories_hash = {};
  foreach my $post ( @{$self->posts} ) {
    push @{ $categories_hash->{$_} }, $post for @{ $post->categories };
  }

  return $categories_hash;
}


has cli_opts => (
  is      => 'ro' ,
  isa     => 'HashRef' ,
  lazy    => 1 ,
  default => sub {{}} ,
);


has config => (
  is      => 'ro' ,
  isa     => 'HashRef' ,
  traits  => [ 'Hash' ] ,
  lazy    => 1 ,
  builder => '_build_config' ,
  handles => { get_config => 'get' } ,
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
    and warn( 'Could not read configuration. Using defaults (and options).' );

  return {
    %{ $self->default_config } ,
    %$config ,
    %{ $self->cli_opts } ,
  };
}

# this is down here so it will see the 'get_config' delegation...
with 'HiD::Role::DoesLogging';


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
    default_author => 'your name here!' ,
    destination    => '_site'    ,
    include_dir    => '_includes',
    layout_dir     => '_layouts' ,
    plugin_dir     => '_plugins' ,
    posts_dir      => '_posts' ,
    drafts_dir     => '_drafts' ,
    source         => '.' ,
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


has draft_post_file_regex => (
  is      => 'ro' ,
  isa     => 'RegexpRef' ,
  default => sub { qr/^(?:.+?)\.(?:mk|mkd|mkdn|markdown|md|mmd|text|textile|html)$/ },
);


has excerpt_separator => (
  is  => 'ro' ,
  isa => 'Str' ,
  lazy => 1 ,
  default => sub { shift->get_config( 'excerpt_separator' ) // "\n\n" }
);


has include_dir => (
  is      => 'ro' ,
  isa     => 'Maybe[HiD_DirPath]' ,
  lazy    => 1 ,
  default => sub {
    my $self = shift;
    my $dir  = $self->get_config( 'include_dir' );
    ( -e -d '_includes' ) ? $dir : undef;
  },
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

  $self->INFO( "Building layouts" );

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

    $self->DEBUG( "* Added layout $layout_file" );
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
  is      => 'ro' ,
  isa     => 'ArrayRef[Object]' ,
  traits  => [ 'Array' ] ,
  default => sub {[]},
  handles => {
    add_object  => 'push' ,
    all_objects => 'elements' ,
  },
);


has page_file_regex => (
  is      => 'ro' ,
  isa     => 'RegexpRef',
  default => sub { qr/\.(mk|mkd|mkdn|markdown|mmd|textile|html|htm|xml|xhtml|xhtm|shtm|shtml|rss)$/ } ,
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

  $self->INFO( "Posts built." );

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


has plugin_dir => (
  is      => 'ro',
  isa     => 'Maybe[HiD_DirPath]',
  lazy    => 1,
  default => sub {
    my $dir = shift->get_config('plugin_dir');
    (-e -d $dir) ? $dir : undef;
  },
);


has plugins => (
  is      => 'ro' ,
  isa     => 'ArrayRef[Pluginish]' ,
  lazy    => 1 ,
  builder => '_build_plugins' ,
);

sub _build_plugins {
  my $self = shift;

  my @loaded_plugins;

  if ( my $plugin_list = $self->config->{plugins} ){
    my @plugins = ( ref $plugin_list eq 'ARRAY' ) ? @$plugin_list
      : (split /\s+/ , $plugin_list );

    foreach ( @plugins ) {

      my $plugin_name = ( /^\+/ ) ? $_ : "HiD::Generator::$_";
      $self->INFO( "* Loading plugin $plugin_name" );
      next unless _load_plugin_or_warn( $plugin_name );
      push @loaded_plugins , $plugin_name->new;
    }
  }

  if ( my $plugin_dir = $self->plugin_dir ) {
    # plugin modules in plugin_dir
    my @mods = File::Find::Rule->file->
      name( '*.pm' )->in( $plugin_dir );

    push @INC , $plugin_dir;

    foreach my $m ( @mods ) {
      $m =~ s|$plugin_dir/?||;
      $m =~ s|.pm$||;
      $self->INFO("* Loading plugin $m" );
      next unless _load_plugin_or_warn( $m );
      push @loaded_plugins, $m->new;
    }
  }

  return \@loaded_plugins;
}

sub _load_plugin_or_warn {
  my $plugin = shift;

  my( $lrlt , $lerr ) = try_load_class( $plugin );

  warn "plugin $plugin cannot be loaded : $lerr \n" and return undef
    unless $lrlt;

  ( $plugin->isa('HiD::Plugin') or
    $plugin->does('HiD::Plugin') or
    $plugin->does('HiD::Generator') )
    or warn "plugin $plugin is not a valid plugin.\n"
      and return undef;

  return 1;
}


has post_file_regex => (
  is      => 'ro' ,
  isa     => 'RegexpRef' ,
  default => sub { qr/^[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}-(?:.+?)\.(?:mk|mkd|mkdn|markdown|md|mmd|text|textile|html)$/ },
);


has posts_dir => (
  is      => 'ro' ,
  isa     => 'HiD_DirPath' ,
  lazy    => 1 ,
  default => sub { shift->get_config( 'posts_dir' ) },
);


has posts => (
  is      => 'ro' ,
  isa     => 'ArrayRef[HiD_Post]' ,
  traits  => [ qw/ Array / ] ,
  handles => { posts_size => 'count' } ,
  lazy    => 1 ,
  builder => '_build_posts' ,
);

sub _build_posts {
  my $self = shift;

  # build layouts before posts
  $self->layouts;

  $self->INFO("Layouts built.");

  $self->INFO("Building posts." );

  my $rule = File::Find::Rule->new;

  my @posts_directories = $rule->or(
    $rule->new->directory->name( $self->get_config( 'posts_dir' )) ,
    $rule->new->directory->name( $self->get_config( 'destination' ))->prune->discard ,
  )->in( $self->source );

  my @potential_posts = File::Find::Rule->file
    ->name( $self->post_file_regex )->in( @posts_directories );

  if ( $self->get_config( 'publish_drafts' )){
    push @potential_posts , $self->_build_potential_draft_posts_list ,
  }

  my @posts = grep { $_ } map {
    try {
      $self->DEBUG( "* Trying to build post $_" );
      my $post = HiD::Post->new({
        dest_dir       => $self->destination,
        hid            => $self ,
        input_filename => $_ ,
        layouts        => $self->layouts ,
      });
      $self->add_input( $_ => 'post' );
      $self->add_object( $post );
      $self->DEBUG( "* Built post $_" );
      $post;
    }
    catch { $self->ERROR( "ERROR: Post failed to build: $_" ) ; return 0 };
  } @potential_posts;

  @posts = sort { $b->date <=> $a->date } @posts;

  if ( my $limit = $self->limit_posts ) {
    die "--limit_posts must be positive" if $limit < 1;
    @posts = splice( @posts , -$limit , $limit );
  }

  return \@posts;
}

sub _build_potential_draft_posts_list {
  my( $self ) = @_;

  my $rule = File::Find::Rule->new;

  my @posts_directories = $rule->or(
    $rule->new->directory->name( $self->get_config( 'drafts_dir' )) ,
    $rule->new->directory->name( $self->get_config( 'destination' ))->prune->discard ,
  )->in( $self->source );

  my @potential_posts = File::Find::Rule->file
    ->name( $self->draft_post_file_regex )->in( @posts_directories );

  return @potential_posts;
}


has processor => (
  is      => 'ro' ,
  isa     => 'HiD::Processor' ,
  lazy    => 1 ,
  default => sub {
    my $self = shift;

    my $processor_name  = $self->get_config( 'processor_name' ) // 'Handlebars';

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

    my @path = ( $self->layout_dir );
    push @path , $self->include_dir
      if defined $self->include_dir;

    return { path => \@path };
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

  $self->INFO( "Pages built" );

  my @potential_files = File::Find::Rule->file->in( '.' );

  my @files = grep { $_ } map {
    if ($self->seen_input( $_ ) or $_ =~ /^_/ ) { 0 }
    elsif( $_ =~ /^\.git/ ) { 0 }
    elsif( $_ =~ /^\.svn/ or $_ =~ /\/\.svn\// ) { 0 }
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


has remove_unwritten_files => (
  is => 'ro' ,
  isa => 'Bool' ,
  lazy => 1 ,
  default => sub {
    my $self = shift;
    return $self->get_config('remove_unwritten_files')
      if defined $self->get_config('remove_unwritten_files');

    return 1;
  },
);


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


has 'tags' => (
  is      => 'ro',
  isa     => 'Maybe[HashRef[ArrayRef[HiD::Post]]]',
  lazy    => 1,
  builder => '_build_tags',
);

sub _build_tags {
  my $self = shift;

  return undef unless $self->posts;

  my $tags_hash = {};
  foreach my $post (@{$self->posts}) {
    push @{$tags_hash->{$_}}, $post for @{$post->tags};
  }
  return $tags_hash;
}


has time => (
  is       => 'ro',
  isa      => 'DateTime' ,
  init_arg => undef ,
  default  => sub { DateTime->now() } ,
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

  if ( -e $self->destination && $self->get_config( 'clean_destination' )){
    remove( \1 , $self->destination );
    $self->INFO( "cleaned destination directory" );
    make_path $self->destination;
  }

  $self->INFO( "publish" );

  # bootstrap data structures
  # FIXME should have a more explicit way to do this
  $self->regular_files;

  $self->INFO( "files bootstrapped" );

  $self->add_written_file( $self->destination => '_site_dir' );

  $self->INFO( "processing plugins for generate()" );

  foreach my $plugin ( @{ $self->plugins } ) {
    if ( $plugin->does( 'HiD::Generator' )) {
      $plugin->generate($self)
    }
  }

  if ( $self->config->{pagination} ){
    my $entries_per_page = $self->config->{pagination}{entries}
      or die "Must set 'pagination.entries' key in pagination config";

    my $page_fstring = $self->config->{pagination}{page}
      or die "Must set 'pagination.page' key in pagination config";

    my $template = $self->config->{pagination}{template}
      or die "Must set 'pagination.template' key in pagination config";

    my $pager = HiD::Pager->new({
      entries             => $self->posts ,
      entries_per_page    => $entries_per_page ,
      hid                 => $self ,
      page_pattern        => $page_fstring
    });

    while ( my $page_data = $pager->next ) {
      my $page = HiD::Page->new({
        dest_dir       => $self->destination ,
        hid            => $self ,
        input_filename => $template ,
        layouts        => $self->layouts ,
        url            => $page_data->{current_page_url} ,
      });
      $page->metadata->{page_data} = $page_data;

      $self->add_input( "Paged page $page_data->{page_number}" => 'page' );
      $self->add_object( $page );
    }
  }


  foreach my $file ( $self->all_objects ) {
    $file->publish;

    $self->INFO( sprintf "* Published %s" , $file->output_filename );

    my $path;
    foreach my $part ( split '/' , $file->output_filename ) {
      $path = file( $path , $part )->stringify;
      $self->add_written_file( $path => 1 );
    }
  }

  if ( $self->remove_unwritten_files ) {
    foreach ( File::Find::Rule->in( $self->destination )) {
      $self->wrote_file($_) or remove \1 , $_;
    }
  }

  return 1 unless $self->plugins;

  $self->INFO( "processing plugins for after_publish()" );

  foreach my $plugin ( @{ $self->plugins } ) {
    if ( $plugin->does( 'HiD::Plugin' ) or
         ### FIXME remove after 13 Nov 2014
         $plugin->isa( 'HiD::Plugin'  )) {
      $plugin->after_publish($self)
    }
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

=head2 categories

Categories hash, contains (category, post) pairs

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
    plugin_dir  => '_plugins' ,
    posts_dir   => '_posts' ,
    drafts_dir  => '_drafts' ,
    source      => '.' ,

=head2 destination

Directory to write output files into.

B<N.B.:> If it doesn't exist and is needed, it will be created.

=head2 draft_post_file_regex

Regular expression for which files will be recognized as draft blog posts.

FIXME should this be configurable?

FIXME this and post_file_regex should probably be built based on a common
underlying "post_extensions_regex" attr...

=head2 excerpt_separator

String that distinguishes initial excerpt from "below the fold" content

Defaults to "\n\n"

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

=head2 plugin_dir

Directory for plugins, which will be called after publish.

=head2 plugins

Plugins, which consume either of the L<HiD::Plugin> or L<HiD::Generator> roles.

Plugins used to subclass L<HiD::Plugin>, but that behavior is deprecated and
will be removed on or after 13 Nov 2014.

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

=head2 remove_unwritten_files ( Boolean )

Boolean value controlling whether files found in the C<dest_dir> that weren't
produced by HiD should be removed. In other words, when this is true, after a
C<hid publish> run, only files produced by HiD will be found in the
C<dest_dir>.

Defaults to true.

=head2 source

Base directory that all other paths are calculated relative to.

=head2 tags

Tags hash, contains (tag, posts) pairs

=head2 time

DateTime object from the start of the latest run of the system.

Cannot be set via argument.

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

=head1 CONTRIBUTORS

=over 4

=item *

ChinaXing

=item *

reyjrar

=back

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

version 1.4

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
