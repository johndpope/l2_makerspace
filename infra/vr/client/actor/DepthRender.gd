extends Spatial

var rvl = load("res://addons/rvl/main.gd").new()

# TODO properly handle scale
const SCALE = 0.01
const SCALE_FACTOR = 1000.0

onready var geom = $Geometry
var dims = [16,16]

func setup(width: int, height: int, topic: String):
  dims = [width, height]
  ROSBridge.ros_connect("0", 
    "sensor_msgs/CompressedImage", 
    self, "_point_data_set", 
    "depth_render_sub", 
    true) # Raw

func _point_data_set(data, id):
  if typeof(data) != TYPE_RAW_ARRAY:
    print("Got wrong type:", typeof(data))
    return
  if len(data) == 0:
    return
  # print("%d: %d %d %d" % [len(data), data[0], data[1], data[2]])
  rvl.Clear()
  rvl.encoded = data
  rvl.DecompressRVL(dims[0]*dims[1])
  geom.clear()
  geom.begin(Mesh.PRIMITIVE_POINTS, null)
  var row = 0
  var col = 0
  for v in rvl.plain: #list of Vector3s
    geom.add_vertex(Vector3(row*SCALE, v / SCALE_FACTOR, col*SCALE))
    row += 1
    if row >= dims[0]:
      row = 0
      col += 1
    if col >= dims[1]:
      break
  geom.end()
