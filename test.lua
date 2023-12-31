require "utils"

local pb = require "luapb"

-- tests
local proto = {
  [1]={type="bool", name="Bob"},
  [2]={type="map", keytype="string", valuetype="double", name="Cats"},
  [3]={type="string", name="Names", repeated=true},
  [4]={type="int64", name="X"},
  [5]={type="double", name="Num"},
  [6]={type="bytes", name="Y"},
  [7]={type="uint32", name="Nummies"},
  [8]={type="string", name="Dog"},
  [9]={type="proto", name="PR", proto={[1]={type="string", name="Response"}}},
  [10]={type="int32", name="Empty1"},
  [11]={type="map", keytype="string", valuetype="double", name="Empty2"},
  [12]={type="string", name="Empty3"},
  [13]={type="bytes", name="Empty4"},
  [14]={type="int32", name="Empty5", repeated=true}
}
local test = pb.deserialise(bytesToString({0x08, 0x01, 0x12, 0x12, 0x0a, 0x07, 0x4a, 0x61, 0x72, 0x20, 0x4a, 0x61, 0x72, 0x11, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x30, 0xc0, 0x12, 0x0f, 0x0a, 0x04, 0x45, 0x72, 0x6e, 0x6f, 0x11, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x2c, 0x40, 0x12, 0x0e, 0x0a, 0x03, 0x53, 0x69, 0x64, 0x11, 0x00, 0x00, 0x00, 0x00, 0x00, 0xc0, 0x6b, 0x40, 0x1a, 0x03, 0x42, 0x6f, 0x62, 0x1a, 0x06, 0x4a, 0x6f, 0x72, 0x64, 0x61, 0x6e, 0x1a, 0x08, 0x44, 0x69, 0x63, 0x6b, 0x68, 0x65, 0x61, 0x64, 0x1a, 0x05, 0x73, 0x70, 0x6c, 0x6f, 0x6d, 0x20, 0xfb, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x01, 0x29, 0x9a, 0x99, 0x99, 0x99, 0x99, 0x99, 0x1b, 0x40, 0x32, 0x03, 0x00, 0x05, 0xff, 0x38, 0x1b, 0x42, 0x04, 0x57, 0x6f, 0x6f, 0x66, 0x4a, 0x0a, 0x0a, 0x08, 0x66, 0x75, 0x63, 0x6b, 0x20, 0x79, 0x6f, 0x75}),
proto)
printkv(test)
printkv(pb.deserialise(pb.serialise(test, proto), proto))
