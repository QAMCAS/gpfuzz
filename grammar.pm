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
package grammar;

use warnings; no warnings qw(once recursion);
use strict;
use autodie;
use v5.14;

{
	my %myGrammar = ();
	my %terminalRules = ();
	my %regexRules = ();
	my $nTerms = 0;
	
	#
	# Parameters
	#	(1) File Name
	#
	# Returns
	#	HASH: Grammar
	#
	sub load {
		my $inputFileName = shift @_ or die 'Illegal Argument Exception!';
		open INPUT, "<$inputFileName" or die "$inputFileName NOT FOUND!";
		%myGrammar = ();
		while (my $line = <INPUT>) {
			chomp $line;
			if ($line =~ /^\s*<(\S+)>\s*::=(.*)$/) {
				my ($ruleName, $terms) = ($1, $2);
				
				for my $term (split /\|/, $terms) {
					$nTerms++;
					if ($term =~ /'(\S+)'/) {
						$_ = $1; s/\\n//g;
						if (defined $terminalRules{$_}) {
							$terminalRules{$_} = "$terminalRules{$_}|$ruleName";
						} else {
							$terminalRules{$_} = $ruleName;
						}
					} elsif ($term =~ /\/(.*)\//) {
						$_ = $1;
						$regexRules{$_} = defined $regexRules{$_} ? $regexRules{$_}."|$ruleName" : $ruleName;
					}
				}
				
				if (defined $myGrammar{$ruleName}) {
					$myGrammar{$ruleName} .= " | $terms";
				} else {
					$myGrammar{$ruleName} = $terms;
				}
			}
		}
		close INPUT;
		
		return %myGrammar;
	}
	
	#
	# Parameters
	#	NONE
	#
	# Returns
	#	ARRAY: List of candidate rules
	#
	sub findCandidateRulesFor {
		my $str = "@_";
		my @candidates = ();
		for (sort keys %myGrammar) {
			push @candidates, $_ if ($myGrammar{$_} =~ /$str/);
		}
		return @candidates;
	}
	
	#
	# Parameters
	#	NONE
	#
	# Returns
	#	HASH: Grammar
	#
	sub getGrammar {
		return %myGrammar;
	}
	
	#
	# Parameters
	#	NONE
	#
	# Returns
	#	SCALAR: # Terms in the grammar
	#
	sub getTermCount {
		return $nTerms;
	}
	
	#
	# Parameters
	#	(1) Candidate Terminal String
	#
	# Returns
	#	ARRAY: List of applicable rules or ();
	#
	sub getPossibleRulesOf {
		my $terminal = shift @_;
		
		my @possibleRules = ();
		if ($terminal) {
			push @possibleRules, (split /\|/, $terminalRules{$terminal}) if (defined $terminalRules{$terminal});
			for my $regex (keys %regexRules) {
				push @possibleRules, split(/\|/, $regexRules{$regex}) if ($terminal =~ /$regex/);
			}
		}
		
		return @possibleRules;
	}
}

return 1;
