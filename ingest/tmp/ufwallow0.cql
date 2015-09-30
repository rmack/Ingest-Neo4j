USING PERIODIC COMMIT 1000
LOAD CSV WITH HEADERS FROM 'file:///tmp/ufwallow0.csv' AS line
MERGE ( a:ufw:udp {
   Label: 'ALLOW',
   Date: line.Date,
   Uptime: line.Uptime,
   Event: line.Event,
   IN: line.IN,
   OUT: line.OUT,
   Length: line.Length,
   TOS: line.TOS,
   PREC: line.PREC,
   TTL: line.TTL,
   ID: line.ID,
   Protocol: line.Protocol,
   SourcePort: line.SourcePort,
   DestPort: line.DestPort
})
MERGE ( d:source {
   IP: line.SourceIP
})
MERGE ( e:dest {
   IP: line.DestIP
})
MERGE (d)-[i:CONNECTED_WITH {
   Date: line.Date
}]->(a)
MERGE (f)-[j:CONNECTED_TO {
   Date: line.Date
}]->(a)
RETURN a,d,e,i,j;