# ABSTRACT: Regular files that are only copied, not processed (e.g., CSS, JS, etc.)


package HiD::File;
{
  $HiD::File::VERSION = '0.4';
}
BEGIN {
  $HiD::File::AUTHORITY = 'cpan:GENEHACK';
}
use Moose;
with 'HiD::Role::IsPublished';
use namespace::autoclean;

use 5.014;
use utf8;
use autodie;
use warnings    qw/ FATAL  utf8     /;
use open        qw/ :std  :utf8     /;
use charnames   qw/ :full           /;
use feature     qw/ unicode_strings /;

use File::Basename         qw/ fileparse /;
use File::Copy::Recursive  qw/ fcopy /;
use File::Path             qw/ make_path /;
use Path::Class            qw/ file / ;


sub publish {
  my $self = shift;

  my( undef , $dir ) = fileparse( $self->output_filename );

  make_path $dir unless -d $dir;

  fcopy( $self->input_filename , $self->output_filename )
    or die $!;
}

# used to populate the 'url' attr in Role::IsPublished
sub _build_url { return shift->input_filename }

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding utf-8

=head1 NAME

HiD::File - Regular files that are only copied, not processed (e.g., CSS, JS, etc.)

=head1 SYNOPSIS

    my $file = HiD::File->new({
      dest_dir       => 'directory/for/output'
      input_filename => $file_filename ,
    });

=head1 DESCRIPTION

Object class representing "normal" files (ones that HiD just copies from
source to destination, without further processing).

=head1 METHODS

=head2 publish

Publishes (in this case, copies) the input file to the output file.

=head1 NOTE

Also consumes L<HiD::Role::IsPublished>; see documentation for that role as
well if you're trying to figure out how an object from this class works.

=head1 VERSION

version 0.4

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
