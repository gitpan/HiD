# ABSTRACT: Example generator to create tagged pages


package HiD::Generator::TagPages;
$HiD::Generator::TagPages::VERSION = '1.2';
BEGIN {
  $HiD::Generator::TagPages::AUTHORITY = 'cpan:GENEHACK';
}
use Moose;
with 'HiD::Generator';

use HiD::Page;

has 'destination' => (
  is      => 'ro' ,
  isa     => 'HiD_DirPath' ,
);


sub generate {
  my( $self , $site ) = @_;

  return unless $site->config->{tags}{generate};

  my $input_file = $site->config->{tags}{input}
    or die "Must define tags.layout in config if tags.generate is enabled";

  my $destination = $self->destination // $site->destination;

  foreach my $tag ( keys %{ $site->tags } ) {
    my $page = HiD::Page->new({
      dest_dir => $destination ,
      hid      => $site ,
      url      => "tags/$tag/" ,
      input_filename => $input_file ,
      layouts  => $site->layouts ,
    });
    $page->metadata->{tag} = $tag;

    $site->add_input( "Tag_$tag" => 'page' );
    $site->add_object( $page );

    $site->INFO( "* Injected tag page for '$tag'");
  }
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding utf-8

=head1 NAME

HiD::Generator::TagPages - Example generator to create tagged pages

=head1 DESCRIPTION

This is an example of a generator plugin. It generates one page per key in the
C<< $site->tags >> hash, and injects that page into the site so that it will
be published.

This plugin can be used with minimal work on your part by enabling the
required options in your cnofiguration and putting a file like the following
example into the C<_plugins> directory of your site:

    package Tags;
    use Moose;
    extends 'HiD::Generator::TagPages';

    # you override the default destination like so
    has '+destination' => ( default => '_site/subdir' );

    __PACKAGE__->meta->make_immutable;
    1;

As shown above, you can control where the resulting pages are generated by
overridding the C<destination> attribute. If you want to tweak more than that,
you're probably better off just copying the whole module into your C<_plugins>
directory and modifying it directly.

=head1 METHODS

=head2 generate

=head1 VERSION

version 1.2

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
