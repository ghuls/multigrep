# multigrep: Grep for multiple patterns at once in one or more columns of a file.

Easily grep for multiple patterns in a (CSV/TSV) file by only matching patterns in specified columns of the file.



## Installation


### Install multigrep

```bash
# Clone repository.
git clone https://github.com/ghuls/multigrep

cd multigrep

# Run multigrep.
./multigrep
```


### Install mawk

Install `mawk` from [https://invisible-island.net/mawk/](https://invisible-island.net/mawk/)
if you want the fastest experience. `mawk` provided by Debian is buggy and not recommended.
If `mawk` is not found `gawk` is used instead.

```
# Download mawk tarball.
wget 'https://invisible-island.net/datafiles/release/mawk.tar.gz'

# Extract mawk tarball.
tar xvzf mawk.tar.gz

# Change directory to extracted mawk tarball dir.
cd mawk-1.3.4-20171017

# configure
./configure

# Build.
make

# Install mawk globally.
sudo make install

# Or add mawk to the "${PATH}" variable:
export PATH="$(pwd):${PATH}"
echo "export PATH=\"${PATH}\""

# Or set "${MAWK}" variable to the path of mawk.
export MAWK="$(pwd):/mawk"
echo "export MAWK=\"$(pwd)/mawk\""
```



## Usage

```
$ ./multigrep.sh

Usage:

  ./multigrep.sh [-g grep_patterns_file]
                 [-G grep_patterns_file_field_number]
                 [-p search_pattern] [-P pattern_separator]
                 [-f field_numbers]  [-s field_separator]
                 [-a] [-r] [-w] [-v]
                 [file(s)]

Options:

  -f field_numbers       Comma separated list of field numbers.   (default: 0)
                         If specified, pattern matching will only be performed
                         on the specified fields instead of on the whole line.
  -g grep_patterns_file  File with patterns to grep for.   (required if no -p)
  -G grep_patterns_file_field_number
                         Use only specified field from grep patterns file and
                         and append content of grep pattern file to lines
                         matching the specified field.
  -p search_pattern      Pattern(s) to search for.         (required if no -g)
  -P pattern_separator   Pattern separator.                      (default: '')
                         Make separate patterns by splitting search_pattern
                         string of -p option at each pattern_separator.
  -a                     Append grep patterns file content.
  -r                     Interpret patterns as regular expressions.
  -s field_separator     Field separator.                      (default: '\t')
  -w                     Pattern(s) need to match the whole line or field.
                         Pattern matching will be very fast with this option.
  -v                     Invert the sense of matching, to select non-matching
                         fields/lines.

Purpose:

  Grep for multiple patterns at once in one or more columns.
```



## Examples



### Create example files

```bash
alphabeth='abcdefghijklmnopqrstuvwxyz'
four_character_words='talclotaoticlocaiotatailcalotaliloticolttacocolalaictoillatialtotolaclotciaocoatcoillocialitcoal'

# Create file to search in.
for i in $(seq 1 1000) ; do
    printf 'chr1\t%d\t%d\tregion_%d\t%s\t%s\t%s\n' \
        "$(( ${i} * 10 ))" \
        "$(( ${i} * 30 ))" \
        "${i}" \
        "${four_character_words:$(( ${i} % 24 )):4}" \
        "${four_character_words:$(( ${i} % 12 )):8}" \
        "${alphabeth:$(( ${i} % 26 )):1}";
done > '/tmp/multigrep_example_file.tsv'


# Create file with patterns to grep for in the first file.
for i in $(seq 50 50 1000) ; do
   printf 'region_%d\tgene_%d\n' \
      "${i}" \
      "$(( ${i} / 50 ))";
done > '/tmp/multigrep_patterns_file.tsv'
```

First 40 lines of `/tmp/multigrep_example_file.tsv` and `/tmp/multigrep_patterns_file.tsv`:

```bash
$ head -n 40 '/tmp/multigrep_example_file.tsv' '/tmp/multigrep_patterns_file.tsv'
==> /tmp/multigrep_example_file.tsv <==
chr1	10	30	region_1	alcl	alclotao	b
chr1	20	60	region_2	lclo	lclotaot	c
chr1	30	90	region_3	clot	clotaoti	d
chr1	40	120	region_4	lota	lotaotic	e
chr1	50	150	region_5	otao	otaoticl	f
chr1	60	180	region_6	taot	taoticlo	g
chr1	70	210	region_7	aoti	aoticloc	h
chr1	80	240	region_8	otic	oticloca	i
chr1	90	270	region_9	ticl	ticlocai	j
chr1	100	300	region_10	iclo	iclocaio	k
chr1	110	330	region_11	cloc	clocaiot	l
chr1	120	360	region_12	loca	talclota	m
chr1	130	390	region_13	ocai	alclotao	n
chr1	140	420	region_14	caio	lclotaot	o
chr1	150	450	region_15	aiot	clotaoti	p
chr1	160	480	region_16	iota	lotaotic	q
chr1	170	510	region_17	otat	otaoticl	r
chr1	180	540	region_18	tata	taoticlo	s
chr1	190	570	region_19	atai	aoticloc	t
chr1	200	600	region_20	tail	oticloca	u
chr1	210	630	region_21	ailc	ticlocai	v
chr1	220	660	region_22	ilca	iclocaio	w
chr1	230	690	region_23	lcal	clocaiot	x
chr1	240	720	region_24	talc	talclota	y
chr1	250	750	region_25	alcl	alclotao	z
chr1	260	780	region_26	lclo	lclotaot	a
chr1	270	810	region_27	clot	clotaoti	b
chr1	280	840	region_28	lota	lotaotic	c
chr1	290	870	region_29	otao	otaoticl	d
chr1	300	900	region_30	taot	taoticlo	e
chr1	310	930	region_31	aoti	aoticloc	f
chr1	320	960	region_32	otic	oticloca	g
chr1	330	990	region_33	ticl	ticlocai	h
chr1	340	1020	region_34	iclo	iclocaio	i
chr1	350	1050	region_35	cloc	clocaiot	j
chr1	360	1080	region_36	loca	talclota	k
chr1	370	1110	region_37	ocai	alclotao	l
chr1	380	1140	region_38	caio	lclotaot	m
chr1	390	1170	region_39	aiot	clotaoti	n
chr1	400	1200	region_40	iota	lotaotic	o

==> /tmp/multigrep_patterns_file.tsv <==
region_50	gene_1
region_100	gene_2
region_150	gene_3
region_200	gene_4
region_250	gene_5
region_300	gene_6
region_350	gene_7
region_400	gene_8
region_450	gene_9
region_500	gene_10
region_550	gene_11
region_600	gene_12
region_650	gene_13
region_700	gene_14
region_750	gene_15
region_800	gene_16
region_850	gene_17
region_900	gene_18
region_950	gene_19
region_1000	gene_20
```



### Specify patterns to use on the command line with `-p`


#### Grep for a single pattern

```bash
# Grep for "region_95" (partial match) in column 4:
#   -f 4                     :  Only look in column 4.
#   -p 'region_95'           :  Look for pattern "region_95" and "region_11"
$ ./multigrep.sh -f 4 -p 'region_95' '/tmp/multigrep_example_file.tsv'
chr1	950	2850	region_95	lcal	clocaiot	r
chr1	9500	28500	region_950	caio	lclotaot	o
chr1	9510	28530	region_951	aiot	clotaoti	p
chr1	9520	28560	region_952	iota	lotaotic	q
chr1	9530	28590	region_953	otat	otaoticl	r
chr1	9540	28620	region_954	tata	taoticlo	s
chr1	9550	28650	region_955	atai	aoticloc	t
chr1	9560	28680	region_956	tail	oticloca	u
chr1	9570	28710	region_957	ailc	ticlocai	v
chr1	9580	28740	region_958	ilca	iclocaio	w
chr1	9590	28770	region_959	lcal	clocaiot	x


# Grep for "region_95" (exact match) in column 4:
#   -f 4                     :  Only look in column 4.
#   -w                       :  Pattern needs to match the whole column (speeds up multigrep significantly).
#   -p 'region_95'           :  Look for pattern "region_95" and "region_11".
$ ./multigrep.sh -f 4 -w -p 'region_95' '/tmp/multigrep_example_file.tsv'
chr1	950	2850	region_95	lcal	clocaiot	r
```


#### Grep for multiple patterns

```bash
# Grep for "region_95" and "region_11" (partial match) in column 4:
#   -f 4                     :  Only look in column 4.
#   -P '|'                   :  Split pattern string specified by "-p" in multiple patterns on "|".
#   -p 'region_95|region_11' :  Look for pattern "region_95" and "region_11".
$ ./multigrep.sh -f 4 -P '|' -p 'region_95|region_11' '/tmp/multigrep_example_file.tsv'
chr1	110	330	region_11	cloc	clocaiot	l
chr1	950	2850	region_95	lcal	clocaiot	r
chr1	1100	3300	region_110	caio	lclotaot	g
chr1	1110	3330	region_111	aiot	clotaoti	h
chr1	1120	3360	region_112	iota	lotaotic	i
chr1	1130	3390	region_113	otat	otaoticl	j
chr1	1140	3420	region_114	tata	taoticlo	k
chr1	1150	3450	region_115	atai	aoticloc	l
chr1	1160	3480	region_116	tail	oticloca	m
chr1	1170	3510	region_117	ailc	ticlocai	n
chr1	1180	3540	region_118	ilca	iclocaio	o
chr1	1190	3570	region_119	lcal	clocaiot	p
chr1	9500	28500	region_950	caio	lclotaot	o
chr1	9510	28530	region_951	aiot	clotaoti	p
chr1	9520	28560	region_952	iota	lotaotic	q
chr1	9530	28590	region_953	otat	otaoticl	r
chr1	9540	28620	region_954	tata	taoticlo	s
chr1	9550	28650	region_955	atai	aoticloc	t
chr1	9560	28680	region_956	tail	oticloca	u
chr1	9570	28710	region_957	ailc	ticlocai	v
chr1	9580	28740	region_958	ilca	iclocaio	w
chr1	9590	28770	region_959	lcal	clocaiot	x


# Grep for "region_95" and "region_11" (exact match) in column 4:
#   -f 4                     :  Only look in column 4.
#   -w                       :  Pattern needs to match the whole column (speeds up multigrep significantly).
#   -P '|'                   :  Split pattern string specified by "-p" in multiple patterns on "|".
#   -p 'region_95|region_11' :  Look for pattern "region_95" and "region_11".
$ ./multigrep.sh -f 4 -w -P '|' -p 'region_95|region_11' '/tmp/multigrep_example_file.tsv'
chr1	110	330	region_11	cloc	clocaiot	l
chr1	950	2850	region_95	lcal	clocaiot	r
```


#### Grep for multiple patterns via a regular expression

```bash
# Grep for all regions from "region_700" till "region_709" and  from "region_730" till "region_739":
#   -f 4                     :  Only look in column 4.
#   -r                       :  Interpret pattern as a regular expression.
#   -p '^region_7[03][0-9]$' :  Look for regular expression pattern "^region_7[03][0-9]$".
$ ./multigrep.sh -f 4 -r -p '^region_7[03][0-9]$' '/tmp/multigrep_example_file.tsv'
chr1	7000	21000	region_700	lota	lotaotic	y
chr1	7010	21030	region_701	otao	otaoticl	z
chr1	7020	21060	region_702	taot	taoticlo	a
chr1	7030	21090	region_703	aoti	aoticloc	b
chr1	7040	21120	region_704	otic	oticloca	c
chr1	7050	21150	region_705	ticl	ticlocai	d
chr1	7060	21180	region_706	iclo	iclocaio	e
chr1	7070	21210	region_707	cloc	clocaiot	f
chr1	7080	21240	region_708	loca	talclota	g
chr1	7090	21270	region_709	ocai	alclotao	h
chr1	7300	21900	region_730	iclo	iclocaio	c
chr1	7310	21930	region_731	cloc	clocaiot	d
chr1	7320	21960	region_732	loca	talclota	e
chr1	7330	21990	region_733	ocai	alclotao	f
chr1	7340	22020	region_734	caio	lclotaot	g
chr1	7350	22050	region_735	aiot	clotaoti	h
chr1	7360	22080	region_736	iota	lotaotic	i
chr1	7370	22110	region_737	otat	otaoticl	j
chr1	7380	22140	region_738	tata	taoticlo	k
chr1	7390	22170	region_739	atai	aoticloc	l


# Grep for all regions from "region_700" till "region_709" and  from "region_730" till "region_739":
#   -f 4                     :  Only look in column 4.
#   -r                       :  Interpret pattern as a regular expression.
#   -p '^region_7[03][0-9]$' :  Look for regular expression pattern "^region_7[03][0-9]$".
# Grep in column 5 and 6 for strings that end with "cloc":
#   -f 5,6                   :  Only look in column 5 and 6.
#   -r                       :  Interpret pattern as a regular expression.
#   -p 'cloc$'               :  Look for regular expression pattern "cloc$" in column 5 and 6.
$ ./multigrep.sh -f 4 -r -p '^region_7[03][0-9]$' -w '/tmp/multigrep_example_file.tsv' | ./multigrep.sh -f 5,6 -r -p 'cloc$'
chr1	7030	21090	region_703	aoti	aoticloc	b
chr1	7070	21210	region_707	cloc	clocaiot	f
chr1	7310	21930	region_731	cloc	clocaiot	d
chr1	7390	22170	region_739	atai	aoticloc	l
```



### Use file with list of patterns with `-g`


#### Grep for multiple patterns from a file

```bash
# Grep for all region ids defined in column 1 of "/tmp/multigrep_patterns_file.tsv" (partial match) in column 4
# of "/tmp/multigrep_example_file.tsv":
#   -f 4                     :  Only look in column 4 of "/tmp/multigrep_example_file.tsv".
#   -G 1                     :  Use only column 1 of "/tmp/multigrep_patterns_file.tsv" as patterns to look for.
#   -g /tmp/multigrep_patterns_file.tsv
#                            :  Read the patterns (from column 1) from "/tmp/multigrep_patterns_file.tsv" .
$ ./multigrep.sh -f 4 -g '/tmp/multigrep_patterns_file.tsv' -G 1 '/tmp/multigrep_example_file.tsv'
chr1	500	1500	region_50	lclo	lclotaot	y
chr1	1000	3000	region_100	lota	lotaotic	w
chr1	1500	4500	region_150	taot	taoticlo	u
chr1	2000	6000	region_200	otic	oticloca	s
chr1	2500	7500	region_250	iclo	iclocaio	q
chr1	3000	9000	region_300	loca	talclota	o
chr1	3500	10500	region_350	caio	lclotaot	m
chr1	4000	12000	region_400	iota	lotaotic	k
chr1	4500	13500	region_450	tata	taoticlo	i
chr1	5000	15000	region_500	tail	oticloca	g
chr1	5010	15030	region_501	ailc	ticlocai	h
chr1	5020	15060	region_502	ilca	iclocaio	i
chr1	5030	15090	region_503	lcal	clocaiot	j
chr1	5040	15120	region_504	talc	talclota	k
chr1	5050	15150	region_505	alcl	alclotao	l
chr1	5060	15180	region_506	lclo	lclotaot	m
chr1	5070	15210	region_507	clot	clotaoti	n
chr1	5080	15240	region_508	lota	lotaotic	o
chr1	5090	15270	region_509	otao	otaoticl	p
chr1	5500	16500	region_550	ilca	iclocaio	e
chr1	6000	18000	region_600	talc	talclota	c
chr1	6500	19500	region_650	lclo	lclotaot	a
chr1	7000	21000	region_700	lota	lotaotic	y
chr1	7500	22500	region_750	taot	taoticlo	w
chr1	8000	24000	region_800	otic	oticloca	u
chr1	8500	25500	region_850	iclo	iclocaio	s
chr1	9000	27000	region_900	loca	talclota	q
chr1	9500	28500	region_950	caio	lclotaot	o
chr1	10000	30000	region_1000	iota	lotaotic	m


# Grep for all region ids defined in column 1 of "/tmp/multigrep_patterns_file.tsv" (exact match) in column 4
# of "/tmp/multigrep_example_file.tsv":
#   -f 4                     :  Only look in column 4 of "/tmp/multigrep_example_file.tsv".
#   -w                       :  Pattern needs to match the whole column (speeds up multigrep significantly).
#   -G 1                     :  Use only column 1 of "/tmp/multigrep_patterns_file.tsv" as patterns to look for.
#   -g /tmp/multigrep_patterns_file.tsv
#                            :  Read the patterns (from column 1) from "/tmp/multigrep_patterns_file.tsv" .
$ ./multigrep.sh -f 4 -w -G 1 -g '/tmp/multigrep_patterns_file.tsv' '/tmp/multigrep_example_file.tsv'
chr1	500	1500	region_50	lclo	lclotaot	y
chr1	1000	3000	region_100	lota	lotaotic	w
chr1	1500	4500	region_150	taot	taoticlo	u
chr1	2000	6000	region_200	otic	oticloca	s
chr1	2500	7500	region_250	iclo	iclocaio	q
chr1	3000	9000	region_300	loca	talclota	o
chr1	3500	10500	region_350	caio	lclotaot	m
chr1	4000	12000	region_400	iota	lotaotic	k
chr1	4500	13500	region_450	tata	taoticlo	i
chr1	5000	15000	region_500	tail	oticloca	g
chr1	5500	16500	region_550	ilca	iclocaio	e
chr1	6000	18000	region_600	talc	talclota	c
chr1	6500	19500	region_650	lclo	lclotaot	a
chr1	7000	21000	region_700	lota	lotaotic	y
chr1	7500	22500	region_750	taot	taoticlo	w
chr1	8000	24000	region_800	otic	oticloca	u
chr1	8500	25500	region_850	iclo	iclocaio	s
chr1	9000	27000	region_900	loca	talclota	q
chr1	9500	28500	region_950	caio	lclotaot	o
chr1	10000	30000	region_1000	iota	lotaotic	m
```


#### Grep for multiple patterns from a file and append matched pattern line from grep patterns file

```bash
# Grep for all region ids defined in column 1 of "/tmp/multigrep_patterns_file.tsv" (exact match) in column 4
# of "/tmp/multigrep_example_file.tsv" and add relevant content of "/tmp/multigrep_example_file.tsv" for each
# matched pattern:
#   -f 4                     :  Only look in column 4 of "/tmp/multigrep_example_file.tsv".
#   -w                       :  Pattern needs to match the whole column (speeds up multigrep significantly).
#   -a                       :  Append relevant content of "/tmp/multigrep_patterns_file.tsv" for each matched pattern (join operation).
#   -G 1                     :  Use only column 1 of "/tmp/multigrep_patterns_file.tsv" as patterns to look for.
#   -g /tmp/multigrep_patterns_file.tsv
#                            :  Read the patterns (from column 1) from "/tmp/multigrep_patterns_file.tsv" .
$ ./multigrep.sh -f 4 -w -a -g '/tmp/multigrep_patterns_file.tsv' -G 1 '/tmp/multigrep_example_file.tsv'
chr1	500	1500	region_50	lclo	lclotaot	y	region_50	gene_1
chr1	1000	3000	region_100	lota	lotaotic	w	region_100	gene_2
chr1	1500	4500	region_150	taot	taoticlo	u	region_150	gene_3
chr1	2000	6000	region_200	otic	oticloca	s	region_200	gene_4
chr1	2500	7500	region_250	iclo	iclocaio	q	region_250	gene_5
chr1	3000	9000	region_300	loca	talclota	o	region_300	gene_6
chr1	3500	10500	region_350	caio	lclotaot	m	region_350	gene_7
chr1	4000	12000	region_400	iota	lotaotic	k	region_400	gene_8
chr1	4500	13500	region_450	tata	taoticlo	i	region_450	gene_9
chr1	5000	15000	region_500	tail	oticloca	g	region_500	gene_10
chr1	5500	16500	region_550	ilca	iclocaio	e	region_550	gene_11
chr1	6000	18000	region_600	talc	talclota	c	region_600	gene_12
chr1	6500	19500	region_650	lclo	lclotaot	a	region_650	gene_13
chr1	7000	21000	region_700	lota	lotaotic	y	region_700	gene_14
chr1	7500	22500	region_750	taot	taoticlo	w	region_750	gene_15
chr1	8000	24000	region_800	otic	oticloca	u	region_800	gene_16
chr1	8500	25500	region_850	iclo	iclocaio	s	region_850	gene_17
chr1	9000	27000	region_900	loca	talclota	q	region_900	gene_18
chr1	9500	28500	region_950	caio	lclotaot	o	region_950	gene_19
chr1	10000	30000	region_1000	iota	lotaotic	m	region_1000	gene_20
```

