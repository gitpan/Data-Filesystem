
use strict;
use warnings;

use Module::Build 0.3601;

my %module_build_args = (
                       'dist_abstract' => 'Access and modify data structures like a filesystem',
                       'script_files' => [],
                       'license' => 'perl',
                       'build_requires' => {
                                             'Module::Build' => '0.3601'
                                           },
                       'dist_name' => 'Data-Filesystem',
                       'dist_author' => [
                                          'Steven Haryanto <stevenharyanto@gmail.com>'
                                        ],
                       'module_name' => 'Data::Filesystem',
                       'requires' => {
                                       'perl' => '5.010000',
                                       'Test::Exception' => '0',
                                       'Any::Moose' => '0',
                                       'Mouse' => '0'
                                     },
                       'recommends' => {},
                       'configure_requires' => {
                                                 'Module::Build' => '0.3601'
                                               },
                       'dist_version' => '0.02'
                     );


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
