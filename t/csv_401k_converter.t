use Modern::Perl;

my $DEBUG = 1;

use Test::More tests => 71;
use lib './lib';
use File::Temp qw(tempfile);

use_ok( 'Finance::Bank::SentinelBenefits::Csv401kConverter' );
use_ok( 'Finance::Bank::SentinelBenefits::Csv401kConverter::SymbolMap' );

my $date = DateTime->new( year  => 2009 ,
			  month => 11   ,
			  day   => 02   ,);

my $symbol_map;

diag('constructing helper objects');
{
  my $fh_symbol_map;
  open($fh_symbol_map, "t/csv_401k_converter_data/test_symmap.csv") or die "unable to open symbol map";

  $symbol_map = Finance::Bank::SentinelBenefits::Csv401kConverter::SymbolMap->new(symbol_map => $fh_symbol_map);

										  close $fh_symbol_map or die "unable to close symbol map";
}

diag( 'constructor one param' );
{
    my (undef, $primary_filename) = tempfile(UNLINK=>1);

    diag("Temp file is $primary_filename, will be auto-removed") if $DEBUG;

    my $trade_input;
    open ($trade_input, "t/csv_401k_converter_data/01-one_line.csv") or die "Unable to open input file";

    my $parser = Finance::Bank::SentinelBenefits::Csv401kConverter->new
      (
       primary_output_file => $primary_filename,
       trade_input         => $trade_input,
       trade_date          => $date,
       symbol_map          => $symbol_map,
       account             => '12345',
     );

    close $trade_input or die "Unable to close input file";
  }

diag( 'parse one param' );
{
    my (undef, $primary_filename) = tempfile(UNLINK=>1);

    diag("Temp file is $primary_filename, will be auto-removed") if $DEBUG;

    my $trade_input;
    open ($trade_input, "t/csv_401k_converter_data/01-one_line.csv") or die "Unable to open input file";

    {
      my $parser = Finance::Bank::SentinelBenefits::Csv401kConverter->new
	(
	 primary_output_file => $primary_filename,
	 trade_input         => $trade_input,
	 trade_date          => $date,
	 symbol_map          => $symbol_map,
	 account             => '12345',
	);
      $parser->write_output();
    }
    close $trade_input or die "Unable to close input file";

    my $fh;
    open ($fh, $primary_filename) or die "unable to reopen output file";

    my %header = (
		  '!' => 'Account',
		  N   => '12345',
		  T   => 'Type:Invst',
		 );
    assert_trade_match(\%header, $fh, 'Header should match expected');

    my %expectedMatchTradeFields = (
			       '!' => 'Type:Invst',
			       D => '11/2/2009',
			       Q => '2.67',
			       M => 'Match of $8.13 to Foobar Dividend Portfolio - ALGAEMicro-organism Investment Value Fund.',
			       N => 'Buy',
			       Y => 'ALGAE',
			       T => '11.1339',
			       I => '4.17',
			      );
    assert_trade_match(\%expectedMatchTradeFields, $fh, 'Actual field should match expected field');

    my %expectedContribTradeFields = (
			      # '!' => 'Type:Invst',
			       D => '11/2/2009',
			       Q => '0.21',
			       M => 'Deferral of $16.25 to Foobar Dividend Portfolio - ALGAEMicro-organism Investment Value Fund.',
			       N => 'Buy',
			       Y => 'ALGAE',
			       T => '1.0038',
			       I => '4.78',
			      );

    assert_trade_match(\%expectedContribTradeFields, $fh, 'Actual field should match expected field');
    #Employee 401k Contribution,Settled,Deferral of $16.25 to Foobar Dividend Portfolio - ALGAEMicro-organism Investment Value Fund.,0.21,4.78,1.0038,0

    close $fh or die "Unable to close output file";
  }


diag( 'parse two param' );
{
    my (undef, $primary_filename) = tempfile(UNLINK=>1);
    my (undef, $secondary_filename) = tempfile(UNLINK=>0);

    diag("Temp file is $primary_filename, will be auto-removed") if $DEBUG;
    diag("Secondary temp file is $secondary_filename, will be auto-removed") if $DEBUG;

    my $trade_input;
    open ($trade_input, "t/csv_401k_converter_data/01-one_line.csv") or die "Unable to open input file";

    {
      my $parser = Finance::Bank::SentinelBenefits::Csv401kConverter->new
	(
	 primary_output_file      => $primary_filename,
	 companymatch_output_file => $secondary_filename,
	 trade_input              => $trade_input,
	 trade_date               => $date,
	 symbol_map               => $symbol_map,
	 account                  => '12345',
	 companymatch_account     => '45678',
	);
      $parser->write_output();
    }
    close $trade_input or die "Unable to close input file";

    my $fh;
    open ($fh, $primary_filename) or die "unable to reopen output file";

    my %header = (
		  '!' => 'Account',
		  N   => '12345',
		  T   => 'Type:Invst',
		 );
    assert_trade_match(\%header, $fh, 'Header should match expected');

    my %expectedMatchTradeFields = (
			       '!' => 'Type:Invst',
			       D => '11/2/2009',
			       Q => '2.67',
			       M => 'Match of $8.13 to Foobar Dividend Portfolio - ALGAEMicro-organism Investment Value Fund.',
			       N => 'Buy',
			       Y => 'ALGAE',
			       T => '11.1339',
			       I => '4.17',
			      );
    assert_trade_match(\%expectedMatchTradeFields, $fh, 'Actual field should match expected field');

    my %expectedContribTradeFields = (
			      # '!' => 'Type:Invst',
			       D => '11/2/2009',
			       Q => '0.21',
			       M => 'Deferral of $16.25 to Foobar Dividend Portfolio - ALGAEMicro-organism Investment Value Fund.',
			       N => 'Buy',
			       Y => 'ALGAE',
			       T => '1.0038',
			       I => '4.78',
			      );

    assert_trade_match(\%expectedContribTradeFields, $fh, 'Actual field should match expected field');

    close $fh or die "Unable to close primary output filename";

    my $fh_secondary;
    open ($fh_secondary, $secondary_filename) or die "unable to reopen output file";

    my %header_companymatch = (
		  '!' => 'Account',
		  N   => '45678',
		  T   => 'Type:Invst',
		 );

    assert_trade_match(\%header_companymatch, $fh_secondary, 'Header should match expected');


    my %expected_cr_trade = (
			     '!' => 'Type:Invst',
			       D => '11/2/2009',
			       Q => '2.67',
			       M => 'Match of $8.13 to Foobar Dividend Portfolio - ALGAEMicro-organism Investment Value Fund.',
			       N => 'ShtSell',
			       Y => 'ALGAE',
			       T => '11.1339',
			       I => '4.17',
			     );

    assert_trade_match(\%expected_cr_trade, $fh_secondary, 'Actual field should match expected field');

  }

diag ('test sell and make sure the flip is a buy');
{
  my (undef, $primary_filename) = tempfile(UNLINK=>1);
  my (undef, $secondary_filename) = tempfile(UNLINK=>0);

  diag("Temp file is $primary_filename, will be auto-removed") if $DEBUG;
  diag("Secondary temp file is $secondary_filename, will be auto-removed") if $DEBUG;

  my $trade_input;
  open ($trade_input, "t/csv_401k_converter_data/02-sell.csv") or die "Unable to open input file";
    {
      my $parser = Finance::Bank::SentinelBenefits::Csv401kConverter->new
	(
	 primary_output_file      => $primary_filename,
	 companymatch_output_file => $secondary_filename,
	 trade_input              => $trade_input,
	 trade_date               => $date,
	 symbol_map               => $symbol_map,
	 account                  => '12345',
	 companymatch_account     => '45678',
	);
      $parser->write_output();
    }
    close $trade_input or die "Unable to close input file";

    my $fh;
    open ($fh, $primary_filename) or die "unable to reopen output file";

    my %header = (
		  '!' => 'Account',
		  N   => '12345',
		  T   => 'Type:Invst',
		 );
    assert_trade_match(\%header, $fh, 'Header should match expected');

    my %expectedMatchTradeFields = (
			       '!' => 'Type:Invst',
			       D => '11/2/2009',
			       Q => '2.67',
			       M => 'Sell Foobar Dividend Portfolio - ALGAEMicro-organism Investment Value Fund.(Dollar certain)',
			       N => 'Sell',
			       Y => 'ALGAE',
			       T => '11.1339',
			       I => '4.17',
			      );
    assert_trade_match(\%expectedMatchTradeFields, $fh, 'Actual field should match expected field');

    close $fh or die "Unable to close primary output filename";

    my $fh_secondary;
    open ($fh_secondary, $secondary_filename) or die "unable to reopen output file";

    my %header_companymatch = (
		  '!' => 'Account',
		  N   => '45678',
		  T   => 'Type:Invst',
		 );

    assert_trade_match(\%header_companymatch, $fh_secondary, 'Header should match expected');


    my %expected_cr_trade = (
			     '!' => 'Type:Invst',
			       D => '11/2/2009',
			       Q => '2.67',
			       M => 'Sell Foobar Dividend Portfolio - ALGAEMicro-organism Investment Value Fund.(Dollar certain)',
			       N => 'Buy',
			       Y => 'ALGAE',
			       T => '11.1339',
			       I => '4.17',
			     );

    assert_trade_match(\%expected_cr_trade, $fh_secondary, 'Actual field should match expected field');
}



sub assert_trade_match{
  my $expected = shift;
  my $fh = shift;
  my $message = shift;

  my %actualMatchTradeFields;

    my $matchFieldCount = 0;
    while(<$fh>){
      last if /[\^]/; #^ is record seperator
      my $line = $_;
      chomp $line;
      $actualMatchTradeFields{substr($line, 0, 1)} = substr($line, 1);
    }

    while(my ($key, $value) = each(%$expected)){
      is($actualMatchTradeFields{$key}, $value, $message);
    }

}

END;

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
