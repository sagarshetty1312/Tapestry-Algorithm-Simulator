# Proj3 Tapestry Algorithm Simulator

## Group members

* Jayanth Shetty, Sagar	[UFID: 4351-7929]
* Mittal, Prakhar 		  [UFID: 3909-9969]

## Instructions

* Run the following command:
	mix run project3.exs <noOfNodes> <noOfRequests>


## What is working
We have used base 16 (hexadecimal) with sha1 encryption and 128 bits for our node_id.
Creation of a parallel nodes is working along with every node initializing a routing table.
Every node sends <noOfRequests> requests and calculates the number of hops every time and the maximum number of hops is returned.

## What is the largest network you managed to deal with
5000 nodes with 5 requests
