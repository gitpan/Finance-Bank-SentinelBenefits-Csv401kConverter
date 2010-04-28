
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Finance::Bank::SentinelBenefits::Csv401kConverter',
                       'DISTNAME' => 'Finance-Bank-SentinelBenefits-Csv401kConverter',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.31'
                                               },
                       'AUTHOR' => 'David Solimano <david@solimano.org>',
                       'BUILD_REQUIRES' => {},
                       'ABSTRACT' => 'Takes a series of lines in Sentinel Benefits format and writes them out as QIF files, subject to the symbol mappings specified.',
                       'EXE_FILES' => [],
                       'VERSION' => '0.5',
                       'PREREQ_PM' => {
                                        'Modern::Perl' => '1.03',
                                        'DateTime' => '0.53',
                                        'Scalar::Util' => '1.22',
                                        'MooseX::Method::Signatures' => '0.30',
                                        'MooseX::StrictConstructor' => '0.08',
                                        'Moose::Util::TypeConstraints' => '0.98',
                                        'Finance::QIF' => '3',
                                        'Moose' => '0.98'
                                      },
                       'LICENSE' => 'gpl'
                     );


delete $WriteMakefileArgs{BUILD_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.56) };

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



