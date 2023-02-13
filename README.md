# GPFUZZ: Grammar-based Performance Fuzzer

### How to Use

```
Usage: perl GPFuzz.pl <N> <grammar-file> <root-rule> "<parser>" "<fail-msg>"
```

GPFUZZ generates `N` distinct inputs, valid according to a `grammar-file`. Then, 
it executes these inputs on the `parser` and produces a bunch of txt files containing
performance statistics.

### Reproducing ITEQS23 Experiments

Please download [mutrex.jar][1] first!

```
perl GPFuzz.pl 1000 original.bnf regexp "timeout 60 java -jar mutrex.jar" "Exception"
```

To execute the input generation with problematic construct avoidance:

```
perl GPFuzz.pl 1000 avoidance.bnf regexp "timeout 60 java -jar mutrex.jar" "Exception"
```

To generate 10 inputs for the toy grammar:

```
perl GPFuzz.pl 10 toy.bnf e "echo" "NoFail"
```

### Copyright Notice

GPFUZZ: Grammar-based Performance Fuzzer
Copyright (C) 2023 QAMCAS
Copyright (C) 2023 Yavuz Koroglu

gfuzzer: Fully Automated Test Generation, Execution, and Evaluation Tool
Copyright (C) 2019 Institute for Software Technology at Graz University of Technology

GPFUZZ is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

GPFUZZ is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with GPFUZZ. If not, see <https://www.gnu.org/licenses/>.

gfuzzer is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

gfuzzer is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with gfuzzer. If not, see <https://www.gnu.org/licenses/>.

* **mail:** ykoerogl@ist.tugraz.at
* **address:** Inffeldgasse 16b/II, 8010 Graz/AUSTRIA

[1]: https://github.com/fmselab/mutrex/raw/master/mutrex.cli/mutrex.jar
