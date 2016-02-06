# netdiagram
A CLI tool for QUICKLY preparing simple network diagrams

## Language
* The script takes an argument string declaring the links between nodes and the desired location in your diagram.
* Node names are Letter+Numbers. R for router, S for switch, H for host.
* Links are declared with a dash. R1-S1 means router 1 is connected to switch 1.
* Links from a node to several hosts can be shortened by ellipsis like S1-H1..H4.
* Topology is a sequence of links separated by semicolon.
* Last component in argument is the diagram layout. 
 * Nodes A above B are written A/B.
 * Nodes A and B, side to side, are written A,B.
 * Nodes A to D located side to side are written A,B,C,D or A..D.
 * Nodes A to D located on a stack are written A/B/C/D or A//D.

## Examples

Please have look at the wiki: https://github.com/egrosclaude/netdiagram/wiki
