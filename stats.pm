#
#   GPFUZZ: Grammar-based Performance Fuzzer
#   Copyright (C) 2023 QAMCAS
#   Copyright (C) 2023 Yavuz Koroglu
#
#   This file is part of GPFUZZ.
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
#   mail: ykoerogl@ist.tugraz.at
#   address: Inffeldgasse 16b/II, 8010 Graz/AUSTRIA
#
package stats;

use warnings; no warnings qw(once recursion);
use strict;
use autodie;
use v5.14;

{
    my %inputs = ();
    my %rules = ();

    my %bottlenecks = ();
    my $mean = 0.00;
    my $stddev = 0.00;
    my $variance = 0.00;
    my $k = 2;

    my $outlierThreshold;
    my $termCoverage;

    sub getTestCount {
        return scalar keys %inputs;
    }

    sub setTermCoverage {
        $termCoverage = shift @_ or die 'Unknown Error!';
    }
    
    sub computeStats {


        # Compute mean
        $mean = 0.00;
        my $input;
        my $inputRef;
        my $n = 0;
        open INPUTS, ">inputs.txt" or die;
        open RT, ">responseTimes.txt" or die;
        while (($input, $inputRef) = each (%inputs)) {
            $mean = ($mean * $n + $inputRef->{"responseTime"}) / ($n + 1);
            say INPUTS "$input";
            say RT $inputRef->{"responseTime"};
            $n = $n + 1;
        }
        close RT;
        close INPUTS;

        # Compute stddev
        $variance = 0.00;
        while (($input, $inputRef) = each (%inputs)) {
            my $responseTime = $inputRef->{"responseTime"};
            $variance = $variance + ($responseTime - $mean) * ($responseTime - $mean) / $n;
        }
        $stddev = sqrt($variance);

        # Find bottlenecks
        $outlierThreshold = $mean + $k * $stddev;
        open BOTTLENECKS, ">bottlenecks.txt" or die;
        open BRT, ">bottleneckRTs.txt" or die;
        while (($input, $inputRef) = each (%inputs)) {
            my $responseTime = $inputRef->{"responseTime"};
            if ($responseTime > $outlierThreshold) {
                # We consider all outliers bottlenecks.
                $bottlenecks{"$input"} = 1;
                say BOTTLENECKS "$input";
                say BRT $responseTime;
            }
        }
        close BRT;
        close BOTTLENECKS;

        open RESULTS, ">results.txt" or die;
        say RESULTS "     TERM COVERAGE = %".$termCoverage;
        say RESULTS "          \# Inputs = ".(scalar keys %inputs);
        say RESULTS "Mean Response Time = $mean";
        say RESULTS "          Variance = $variance";
        say RESULTS "Standard Deviation = $stddev";
        say RESULTS "Min. Bottleneck RT = $outlierThreshold";
        say RESULTS "     \# Bottlenecks = ".(scalar keys %bottlenecks);
        close RESULTS;

        # Count bottlenecks of rules and expansions
        my $rule;
        my $ruleRef;
        open RULES, ">rules.txt" or die;
        open EXPANSIONS, ">expansions.txt" or die;
        while (($rule, $ruleRef) = each (%rules)) {
            say RULES "$rule";
            my $nInputs = $ruleRef->{"nInputs"};
            say RULES "\# Inputs = $nInputs";
            my $nBottlenecks = $ruleRef->{"nBottlenecks"};
            while (($input, $inputRef) = each (%{$ruleRef->{"inputs"}})) {
                if (defined $bottlenecks{"$input"}) {
                    $nBottlenecks = $nBottlenecks + 1;
                }
            }
            $ruleRef->{"nBottlenecks"} = $nBottlenecks;
            say RULES "\# Bottlenecks = $nBottlenecks";
            my $likelihood = $nBottlenecks / $nInputs;
            $ruleRef->{"likelihood"} = $likelihood;
            say RULES "P(bottleneck | $rule) = $likelihood";
            my $expansion;
            my $expansionRef;
            while (($expansion, $expansionRef) = each (%{$ruleRef->{"expansions"}})) {
                say EXPANSIONS "$rule ::= $expansion";
                my $nExpansionInputs = $expansionRef->{"nInputs"};
                say EXPANSIONS "\# Inputs = $nExpansionInputs";
                my $nExpansionBottlenecks = $expansionRef->{"nBottlenecks"};
                for my $expansionInput (keys %{$expansionRef->{"inputs"}}) {
                    if (defined $bottlenecks{"$expansionInput"}) {
                        $nExpansionBottlenecks = $nExpansionBottlenecks + 1;
                    }
                }
                $expansionRef->{"nBottlenecks"} = $nExpansionBottlenecks;
                say EXPANSIONS "\# Bottlenecks = $nExpansionBottlenecks";
                my $expansionLikelihood = $nExpansionBottlenecks / $nExpansionInputs;
                $expansionRef->{"likelihood"} = $expansionLikelihood;
                say EXPANSIONS "P(bottleneck | $rule, $expansion) = $expansionLikelihood";
                my $delta = $expansionLikelihood - $likelihood;
                $expansionRef->{"delta"} = $delta;
                say EXPANSIONS "D(bottleneck | $rule, $expansion) = $delta";
                say EXPANSIONS "";
            }
            say RULES "";
        }
        close RULES;
        close EXPANSIONS;
    }

    sub addTest {
        my ($input, $responseTime, $usedRulesRef) = @_;

        if (defined $inputs{"$input"}) {
            my $inputRef = $inputs{"$input"};
            my $oldSampleCount = $inputRef->{"sampleCount"};
            my $newSampleCount = $oldSampleCount + 1;
            my $avgResponseTime = $inputRef->{"responseTime"};
            $avgResponseTime = ($avgResponseTime * $oldSampleCount + $responseTime) / $newSampleCount;
            $inputRef->{"responseTime"} = $avgResponseTime;
            $inputRef->{"sampleCount"} = $newSampleCount;
        } else {
            my %newInput = ();
            $newInput{"sampleCount"} = 1;
            $newInput{"responseTime"} = $responseTime;
            
            my $rule;
            my $expansionsRef;
            while (($rule, $expansionsRef) = each (%$usedRulesRef)) {
                if (defined $rules{"$rule"}) {
                    my $ruleRef = $rules{"$rule"};
                    my $nInputs = $ruleRef->{"nInputs"};
                    $nInputs = $nInputs + 1;
                    $ruleRef->{"nInputs"} = $nInputs;
                    $ruleRef->{"inputs"}->{"$input"} = 1;
                    my $ruleExpansionsRef = $ruleRef->{"expansions"};
                    for my $expansion (keys %$expansionsRef) {
                        if (defined $ruleExpansionsRef->{"$expansion"}) {
                            my $expansionRef = $ruleExpansionsRef->{"$expansion"};
                            my $nExpansionInputs = $expansionRef->{"nInputs"};
                            $nExpansionInputs = $nExpansionInputs + 1;
                            $expansionRef->{"nInputs"} = $nExpansionInputs;
                            my $newExpansionInputsRef = $expansionRef->{"inputs"};
                            $newExpansionInputsRef->{"$input"} = 1;
                        } else {
                            my %newExpansion = ();
                            $newExpansion{"nInputs"} = 1;
                            $newExpansion{"nBottlenecks"} = 0;
                            $newExpansion{"likelihood"} = 0.00;
                            $newExpansion{"delta"} = 0.00;
                            my %newExpansionInputs = ();
                            $newExpansionInputs{"$input"} = 1;
                            $newExpansion{"inputs"} = \%newExpansionInputs;
                            $ruleExpansionsRef->{"$expansion"} = \%newExpansion;
                        }
                    }
                } else {
                    my %newRule = ();
                    $newRule{"nInputs"} = 1;
                    $newRule{"nBottlenecks"} = 0;
                    $newRule{"likelihood"} = 0.00;
                    my %newInputs = ();
                    $newInputs{"$input"} = 1;
                    $newRule{"inputs"} = \%newInputs;
                    my %newExpansions = ();
                    for my $expansion (keys %$expansionsRef) {
                        my %newExpansion = ();
                        $newExpansion{"nInputs"} = 1;
                        $newExpansion{"nBottlenecks"} = 0;
                        $newExpansion{"likelihood"} = 0.00;
                        $newExpansion{"delta"} = 0.00;
                        my %newExpansionInputs = ();
                        $newExpansionInputs{"$input"} = 1;
                        $newExpansion{"inputs"} = \%newExpansionInputs;
                        $newExpansions{"$expansion"} = \%newExpansion;
                    }
                    $newRule{"expansions"} = \%newExpansions;
                    $rules{"$rule"} = \%newRule;
                }
            }
            $inputs{"$input"} = \%newInput;
        }
    }
}

return 1;
