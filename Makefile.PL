
use strict;
use warnings;

use 5.014;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Static website publishing framework",
  "AUTHOR" => "John SJ Anderson <genehack\@genehack.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "HiD",
  "EXE_FILES" => [
    "bin/hid"
  ],
  "LICENSE" => "perl",
  "NAME" => "HiD",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Class::Load" => 0,
    "DDP" => 0,
    "Date::Parse" => 0,
    "DateTime" => 0,
    "Encode" => 0,
    "File::Basename" => 0,
    "File::Copy::Recursive" => 0,
    "File::Find::Rule" => 0,
    "File::Path" => 0,
    "File::Remove" => 0,
    "File::Slurp" => 0,
    "FindBin" => 0,
    "Module::Find" => 0,
    "Moose" => 0,
    "Moose::Role" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "MooseX::App::Cmd" => 0,
    "MooseX::App::Cmd::Command" => 0,
    "Path::Class" => 0,
    "Plack::App::File" => 0,
    "Plack::Runner" => 0,
    "String::Errf" => 0,
    "Template" => 0,
    "Text::Markdown" => 0,
    "Text::Textile" => 0,
    "Try::Tiny" => 0,
    "YAML::XS" => 0,
    "autodie" => 0,
    "charnames" => 0,
    "feature" => 0,
    "namespace::autoclean" => 0,
    "open" => 0,
    "parent" => 0,
    "strict" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "App::Cmd::Tester" => 0,
    "Cwd" => 0,
    "Exporter" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Test::File" => 0,
    "Test::File::Contents" => 0,
    "Test::More" => 0,
    "Test::Routine" => 0,
    "Test::Routine::Util" => 0,
    "Test::Warn" => 0,
    "YAML" => 0
  },
  "VERSION" => "0.6",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



