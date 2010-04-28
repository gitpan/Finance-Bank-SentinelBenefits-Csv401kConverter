package Finance::Bank::SentinelBenefits::Csv401kConverter;
BEGIN {
  $Finance::Bank::SentinelBenefits::Csv401kConverter::VERSION = '0.5';
}
use Modern::Perl;

use DateTime;

=head1 NAME

Finance::Bank::SentinelBenefits::Csv401kConverter - Takes a series of lines in Sentinel Benefits format and writes them out as QIF files, subject to the symbol mappings specified.

=head1 VERSION

version 0.5

=head1 SYNOPSIS


=head1 DESCRIPTION

This module takes a CSV file in the format "provided" i.e. copy-pasted from the Sentinel Benefits website.  It also takes a description->symbol mapping, and one or two filenames to write out.  The first file is a list of the transactions in QIF format.  The second file, if provided, is a list of the company matches with the signs reversed, which can be useful if you want to keep unvested company contributions from showing up in your net worth calculations.

=cut

use Moose;
use MooseX::Method::Signatures;
use MooseX::StrictConstructor;

use Finance::Bank::SentinelBenefits::Csv401kConverter::SymbolMap;
use Finance::Bank::SentinelBenefits::Csv401kConverter::LineParser;
use Finance::Bank::SentinelBenefits::Csv401kConverter::QifWriter;

has 'trade_input'  => (
    is       => 'ro',
    isa      => 'FileHandle',
    required => 1,
    );

has 'primary_output_file' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    );

has 'companymatch_output_file' => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
    );

has 'symbol_map' => (
    is       => 'ro',
    isa      => 'Finance::Bank::SentinelBenefits::Csv401kConverter::SymbolMap',
    required => 1,
    );

has 'trade_date' => (
    is       => 'ro',
    isa      => 'DateTime',
    required => 1,
    );

has 'account'    => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    );

has 'companymatch_account' => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
    );

method write_output(){
    my $parser = Finance::Bank::SentinelBenefits::Csv401kConverter::LineParser->new
	(
	 symbol_map => $self->symbol_map()
	);

    my $writer = Finance::Bank::SentinelBenefits::Csv401kConverter::QifWriter->new
	(
	 output_file => ">" . $self->primary_output_file(),
	 trade_date  => $self->trade_date(),
	 account     => $self->account(),
	);

    my $cm_writer;
    if($self->companymatch_account()
       && $self->companymatch_output_file())
    {
	$cm_writer = Finance::Bank::SentinelBenefits::Csv401kConverter::QifWriter->new
	(
	 output_file => ">" . $self->companymatch_output_file(),
	 trade_date  => $self->trade_date(),
	 account     => $self->companymatch_account(),
	);
	
    }

    my $fh = $self->trade_input();
    while(<$fh>){
	my $line = $parser->parse_line($_, $self->trade_date());

	if(defined $line){
	    $writer->output_line($line);

	    if(defined $cm_writer
		&& $line->source() eq 'Match'){
		my $cm_line = Finance::Bank::SentinelBenefits::Csv401kConverter::Line->new
		    (
		     date      => $line->date(),
		     symbol    => $line->symbol(),
		     memo      => $line->memo(),
		     quantity  => $line->quantity(),
		     price     => $line->price(),
		     total     => $line->total(),
		     source    => $line->source(),
		     side      => $line->side() eq 'Buy' ? 'ShtSell' : 'Buy',
		    );
		$cm_writer->output_line($cm_line);
	    }
	}
    }

    $writer->close();

    $cm_writer->close() if $cm_writer;
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;

# Copyright 2009-2010 David Solimano
# This file is part of Finance::Bank::SentinelBenefits::Csv401kConverter

# Finance::Bank::SentinelBenefits::Csv401kConverter is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# Finance::Bank::SentinelBenefits::Csv401kConverter is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with Finance::Bank::SentinelBenefits::Csv401kConverter.  If not, see <http://www.gnu.org/licenses/>.