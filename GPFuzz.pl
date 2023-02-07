#!/usr/bin/env perl
#
#   GPFUZZ: Grammar-based Performance Fuzzer
#   Copyright (C) 2023 QAMCAS
#   Copyright (C) 2023 Yavuz Koroglu
#
#   gfuzzer: Fully Automated Test Generation, Execution, and Evaluation Tool
#   Copyright (C) 2019 Institute for Software Technology in Graz University of Technology
#
#   This file is part of GPFUZZ and gfuzzer.
#
#   GPFUZZ is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   GPFUZZ is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with GPFUZZ.  If not, see <https://www.gnu.org/licenses/>.
#
#   gfuzzer is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   gfuzzer is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with gfuzzer.  If not, see <https://www.gnu.org/licenses/>.
#
#   mail: ykoerogl@ist.tugraz.at
#   address: Inffeldgasse 16b/II, 8010 Graz/AUSTRIA
#
use lib '.';
use warnings; no warnings 'once'; no warnings 'recursion';
use strict;
use autodie;
use v5.14;

use String::Random;

use grammar;
use stats;

our $stringGenerator = String::Random->new;

our %coveredTerms;

our $maxSymbols = 10;

our %usedRules = ();

#
# Parameters
#   NONE
#
# Returns
#   UNUSED
#
sub showCopyright {
    say 'GPFUZZ Copyright (C) 2023 QAMCAS';
    say 'GPFUZZ Copyright (C) 2023 Yavuz Koroglu';
    say 'gfuzzer Copyright (C) 2019 Institute for Software Technology at Graz University of Technology';
    say 'This program comes with ABSOLUTELY NO WARRANTY; for details type "show w".';
    say 'This is free software, and you are welcome to redistribute it';
    say 'under certain conditions; type "show c" for details.';
}

#
# Parameters
#   NONE
#
# Returns
#   UNUSED
#
sub showWarranty {
    say 'This program is distributed in the hope that it will be useful,';
    say 'but WITHOUT ANY WARRANTY; without even the implied warranty of';
    say 'MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the';
    say 'GNU General Public License for more details.';
    say '';
    say 'You should have received a copy of the GNU General Public License';
    say 'along with this program.  If not, see <https://www.gnu.org/licenses/>.';
}

#
# Parameters
#   NONE
#
# Returns
#   UNUSED
#
sub showLicense {
    open LICENSE, "<LICENSE" or die("No LICENSE file found!");
    print while(<LICENSE>);
    close LICENSE;
}

#
# Parameters
#	NONE
#
# Returns
#	UNUSED
#
sub showUsage {
	say '';
	say "$0";
	say '';
	say "\tUsage: $0 <TestCount> <Grammar-File> <RuleUnderTest> \"<ParserUnderTest>\" \"<FailMessage>\"";
	say '';
}

#
# Parameters
#	(1) Reference to Grammar
#	(2) Rule to generate sentence for
#	(3) MaxSymbols
#
# Returns
#	UNUSED
#
sub fuzzRule {
	my $grammarRef = shift @_ or die 'Illegal Argument Exception!';
	my $rule = shift @_ or die 'Illegal Argument Exception!';
	my $maxSymbols = shift @_ or die 'Illegal Argument Exception!';
	
	die "$rule IS NOT DEFINED!!" unless (defined $grammarRef->{$rule});
	
	my @terms = split /\|/, $grammarRef->{$rule};
	my @uncoveredTerms = ();
	for my $term (@terms) {
		push @uncoveredTerms, $term unless (defined $coveredTerms{"<${rule}> ::= ${term}"});
	}
	
	my $term = (@uncoveredTerms == 0) ? $terms[rand @terms] : $uncoveredTerms[rand @uncoveredTerms];
    if (defined $usedRules{"<${rule}>"}) {
        my $expansionsRef = $usedRules{"<${rule}>"};
        $expansionsRef->{"$term"} = 1;
    } else {
        my %expansions = ();
        $expansions{"$term"} = 1;
        $usedRules{"<${rule}>"} = \%expansions;
    }
	$coveredTerms{"<${rule}> ::= ${term}"} = (defined $coveredTerms{"<${rule}> ::= ${term}"}) ? $coveredTerms{"<${rule}> ::= ${term}"} + 1 : 1;
	
	# Instantiate all subterms
	my $instantiatedTerm = '';
	my @subterms = ($term =~ /(<\S+>)|('\S+')/ig);
	for (@subterms) {
		if (defined) {
			if (/<(\S+)>/) {
				$instantiatedTerm .= ' ' . fuzzRule($grammarRef, $1, $maxSymbols);
			} elsif (/'(\S+)'/) {
				$instantiatedTerm .= " $1";
			}
		}
	}
	$instantiatedTerm =~ s/  / /g;
	$term = $instantiatedTerm;
	
	# Instantiate all regular expressions
	while ($term =~ /(.*)\/(\S+)\/(.*)/) {
		my ($prefix, $expression, $suffix) = ($1, $2, $3);
		
		# Replace all stars with random [0, maxSymbols]
		while ($expression =~ /(.*)\*(.*)/) {
			$expression = $1 . '{' . int(rand($maxSymbols)) . '}' . $2;
		}
		
		# Replace all pluses with random [1, maxSymbols]
		while ($expression =~ /(.*)\+(.*)/) {
			$expression = $1 . '{' . (int(rand($maxSymbols-1)) + 1) . '}' . $2;
		}
		
		$term = $prefix.$stringGenerator->randregex($expression).$suffix;
	}
	
	# Insert all newline characters
	$term =~ s/\\n/\n/g;
	
	# Remove all ' signs
	$term =~ s/'//g;
	$term =~ s/ //g;
	
	return $term;
}

sub main {
    my $n = shift @ARGV or (showUsage(), exit); 
	my $grammarFile = shift @ARGV or (showUsage(), exit);
	my $ruleUnderTest = shift @ARGV or (showUsage(), exit);
	my $parserUnderTest = shift @ARGV or (showUsage(), exit);
	my $failMessage = shift @ARGV or (showUsage(), exit);
	
    say "TARGET TEST COUNT = $n";
	say "GENERATOR GRAMMAR FILE = $grammarFile";
	say "RULE UNDER TEST = $ruleUnderTest";
	say "PARSER UNDER TEST = $parserUnderTest";
	say "FAIL MESSAGE = $failMessage";
	
	if ($ruleUnderTest =~ /<(\S+)>/) {
		$ruleUnderTest = $1;
	}
	
	say '';
	say "LOADING = $grammarFile";
	my %grammar = grammar::load($grammarFile);
	say "LOADED = $grammarFile";
	say '';
	
	die "Rule <$ruleUnderTest> NOT FOUND in $grammarFile!" unless (defined $grammar{$ruleUnderTest});
	
    while (stats::getTestCount() < $n) {
        %usedRules = ();
		my $testInput = fuzzRule(\%grammar, $ruleUnderTest, $maxSymbols);
        say "TRYING => $testInput";
		
		my $parserOutput = `gtime --format=\"%U\" $parserUnderTest \"$testInput\" 2>&1`;
        $parserOutput =~ s/\n$//;
		
		unless ($parserOutput =~ /$failMessage/) {
            my $responseTime = 0.00;
            warn "Unknown Error! => '$testInput'" unless($parserOutput =~ /.*\n([^\n]+)$/);
            $responseTime = $responseTime + $1;
            stats::addTest($testInput, $responseTime, \%usedRules);
            say "GOT ".stats::getTestCount()." TESTS READY!";
		}
	}

    stats::setTermCoverage(100 * (scalar keys %coveredTerms) / grammar::getTermCount());
    say "COMPUTING LAST STATS...";
    stats::computeStats();
}

showCopyright();
if ("@_" =~ /show w/) {
    showWarranty();
    exit;
} elsif ("@_" =~ /show c/) {
    showLicense();
    exit;
} else {
    main();    
}
