# netdiagram
A CLI tool for QUICKLY preparing simple network diagrams

## Language
* The script takes an argument string declaring the links between nodes and the desired location in your diagram.
* Node names are Letter+Numbers. R for router, S for switch, H for host.
* Links are declared with a dash. R1-S1 means router 1 is connected to switch 1.
* Links from a node to several others can be shortened by ellipsis like S1-H1..H4
* Topology is a sequence of links separated by semicolon.
* Last component in argument is the diagram layout. 
 * Nodes A above B are written A/B.
 * Nodes A to D located side to side are written A,B,C,D or A..D.

## Examples

Links from a router to a switch, and from the switch to one host. Then, the router is above the switch, the switch is above the host (see https://github.com/egrosclaude/netdiagram/blob/master/test1.png). 

./netdiagram.pl "R1-S1;S1-H1;R1/S1/H1" > test1.png


A somewhat more complicated example (https://github.com/egrosclaude/netdiagram/blob/master/test2.png):

./netdiagram.pl "S1-R1;S1-H1..H3;R1-S3;S3-R2;R2-S2;S2-H4..H5;S3-H6..H8;(H1/H2/H3),S1,R1,(S3/(H6..H8)),R2,S2,(H4/H5)" > test2.png
