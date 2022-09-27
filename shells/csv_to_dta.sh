#!/bin/bash

# Unzip .csv files
for F in England_*.zip
do
	unzip $F
done

# Converts .csv files to .dta files using stat/transfer
for F in England_*.csv
do
	FILE=${F%.csv}
	st $F ${FILE}.dta -v -y
done

# Add .dta files to .zip file 
for F in England_*.dta
do
	FILE=${F%.dta}
	zip ${FILE} $F 
done
