# Chord Peer to Peer Implementation
<i>Imthiaz Hussain (imthiazh.hussain@ufl.edu)</i><br>
<i>Lohit Bhambri (lohit.bhambri@ufl.edu)</i><br>

### Problem Statement:
The objective for the project is to implement netowrk join and routing algorithm referred as Chord.<br>
<p>
1. Chord is a protocol and algorithm for a peer-to-peer distributed hash table.<br> 
2. A distributed hash table stores key-value pairs by assigning keys to different nodes; a node will store the values for all the keys for which it is responsible.<br>
3. Chord specifies how keys are assigned to nodes, and how a node can discover the value for a given key by first locating the node responsible for that key.
</p>

### Run Project:
Run the following commands for the project <br>
```
```

### Code Explanation:
Our project will start from the ```chord_start(TotalNodes,Requests)``` function.<br>
We will <i>calibrate</i> the total number of spaces in the chord to the highest nearest power of ``` 2^n```.
```
Example: 
totalNodes = 9
nearest highest power of 2 which is greater than 9 is 16 i.e. 2^4  where n = 4
```

Now we will generate the nodes (a.k.a. Actors) in following:
```
Random_ID = rand:uniform(1000000000),
Hashed_data = crypto:hash(sha, <<Random_ID>>),
<<Hash_to_int:160/integer>> = Hashed_data,
Identifier = Hash_to_int rem TotalSpaces,
```
The above code snippet explains how we will generate the hashed node id. Once generated will spin a node via function call ```node:startLink```and assign the hashed identifier.
<br>

<b>Finger Table:</b><br>
In chord protocol each node maintains a data-structure entry for message distribution called as <i>finger table</i>.
Our message distribution from a random node to the specified nodes work upon the neighbor lookup in the finger table and transmitting the message to the actor.<br>
If the <i>specified key isn't available</i> inside the finger table, we will delegate the call to <i> the nearest responsible node </i> to distribute the message in an efficient way.

### Working Objectives:


### Largest Achievable Network: