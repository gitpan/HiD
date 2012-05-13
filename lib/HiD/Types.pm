# ABSTRACT: HiD type constraints


package HiD::Types;
{
  $HiD::Types::VERSION = '0.1';
}
BEGIN {
  $HiD::Types::AUTHORITY = 'cpan:GENEHACK';
}

use 5.014;
use utf8;
use strict;
use autodie;
use warnings;
use warnings    qw/ FATAL  utf8     /;
use open        qw/ :std  :utf8     /;
use charnames   qw/ :full           /;
use feature     qw/ unicode_strings /;

use Moose::Util::TypeConstraints;

subtype 'HiD_DirPath'
  => as 'Str'
  => where { -d $_ };

# TODO make this a bit more useful?
subtype 'HiD_FileExtension'
  => as 'Str' ,
  #=> where { what, exactly? }
  ;

subtype 'HiD_FilePath'
  => as 'Str'
  => where { -f $_ };

subtype 'HiD_PosInt'
  => as 'Int'
  => where { $_ > 0 }
  => message { "Must be positive integer." };

no Moose::Util::TypeConstraints;
1;

__END__
=pod

=encoding utf-8

=head1 NAME

HiD::Types - HiD type constraints

=head1 DESCRIPTION

Type constraints for HiD.

=head1 VERSION

version 0.1

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
