# netdiagram
A CLI tool for QUICKLY preparing simple network diagrams


## Examples

A router above a switch, above one host. Links from router to switch, from switch to host:

./netdiagram.pl "R1-S1;S1-H1;R1/S1/H1" > test1.png


A somewhat more complicated example:

./netdiagram.pl "S1-R1;S1-H1..H3;R1-S3;S3-R2;R2-S2;S2-H4..H5;S3-H6..H8;(H1/H2/H3),S1,R1,(S3/(H6..H8)),R2,S2,(H4/H5)" > x.png
