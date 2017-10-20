
var SHA3 = require("sha3");
var d = new SHA3.SHA3Hash(256);

d.update(new Buffer('01','hex'));
d.digest('hex')

47f0b630b501111421093d10c9b02dd84c0c5d49312cb589411194f7e4e88dea