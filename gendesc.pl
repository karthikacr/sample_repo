#!/usr/bin/perl -w
#
#   Copyright (c) International Business Machines  Corp., 2002
#
#   This program is free software;  you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or (at
#   your option) any later version.
#
#   This program is distributed in the hope that it will be useful, but
#   WITHOUT ANY WARRANTY;  without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#   General Public License for more details.                 
#
#   You should have received a copy of the GNU General Public License
#   along with this program;  if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
#
# gendesc.pl
#
#   This script creates a description file as understood by genhtml.pl.
#   Input file format:
#
#   For each test case:
#     <test name><optional whitespace>
#     <at least one whitespace character (blank/tab)><test description>
#   
#   Actual description may consist of several lines. By default, output is
#   written to stdout. Test names consist of alphanumeric characters
#   including _ and -.
#
#
# History:
#   2002-09-02: created by Peter Oberparleiter <Peter.Oberparleiter@de.ibm.com>
#

use strict;
use File::Basename; 
use Getopt::Long;


# Constants
our $version_info	= "gendesc version 1.0";
our $url		= "http://ltp.sourceforge.net/lcov.php";


# Prototypes
sub print_usage(*);
sub gen_desc();


# Global variables
our $help;
our $version;
our $output_filename;
our $input_filename;


#
# Code entry point
#

# Parse command line options
if (!GetOptions("output-filename=s" => \$output_filename,
		"version" =>\$version,
		"help" => \$help
		))
{
	print_usage(*STDERR);
	exit(1);
}

$input_filename = $ARGV[0];

# Check for help option
if ($help)
{
	print_usage(*STDOUT);
	exit(0);
}

# Check for version option
if ($version)
{
	print($version_info."\n");
	exit(0);
}


# Check for input filename
if (!$input_filename)
{
	print(STDERR "No input filename specified\n");
	print_usage(*STDERR);
	exit(1);
}

# Do something
gen_desc();


#
# print_usage(handle)
#
# Write out command line usage information to given filehandle.
#

sub print_usage(*)
{
	local *HANDLE = $_[0];
	my $tool_name = basename($0);

	print(HANDLE <<END_OF_USAGE)
Usage: $tool_name [OPTIONS] INPUTFILE

Convert a test case description file into a format as understood by genhtml.pl.

  -h, --help                        Print this help, then exit
  -v, --version                     Print version number, then exit
  -o, --output-filename FILENAME    Write description to FILENAME

See $url for more information on this tool.
END_OF_USAGE
	;
}


#
# gen_desc()
#
# Read text file INPUT_FILENAME and convert the contained description to a
# format as understood by genhtml.pl, i.e.
#
#    TN:<test name>
#    TD:<test description>
#
# If defined, write output to OUTPUT_FILENAME, otherwise to stdout.
#
# Die on error.
#

sub gen_desc()
{
	local *INPUT_HANDLE;
	local *OUTPUT_HANDLE;
	my $empty_line = "ignore";

	open(INPUT_HANDLE, $input_filename)
		or die("ERROR: cannot open $input_filename!\n");

	# Open output file for writing
	if ($output_filename)
	{
		open(OUTPUT_HANDLE, ">$output_filename")
			or die("ERROR: cannot create $output_filename!\n");
	}
	else
	{
		*OUTPUT_HANDLE = *STDOUT;
	}

	# Process all lines in input file
	while (<INPUT_HANDLE>)
	{
		chomp($_);

		if (/^\s*(\w[\w-]*)(\s*)$/)
		{
			# Matched test name
			# Name starts with alphanum or _, continues with
			# alphanum, _ or -
			print(OUTPUT_HANDLE "TN: $1\n");
			$empty_line = "ignore";
		}
		elsif (/^(\s+)(\S.*?)\s*$/)
		{
			# Matched test description
			if ($empty_line eq "insert")
			{
				# Write preserved empty line
				print(OUTPUT_HANDLE "TD: \n");
			}
			print(OUTPUT_HANDLE "TD: $2\n");
			$empty_line = "observe";
		}
		elsif (/^\s*$/)
		{
			# Matched empty line to preserve paragraph separation
			# inside description text
			if ($empty_line eq "observe")
			{
				$empty_line = "insert";
			}
		}
	}

	# Close output file if defined
	if ($output_filename)
	{
		close(OUTPUT_HANDLE);
	}

	close(INPUT_HANDLE);
}
