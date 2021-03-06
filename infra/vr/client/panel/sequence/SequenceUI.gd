extends Control

signal run_sequence
signal stop_sequence

# onready var label = $ColorRect/Label
onready var nodes = $MarginContainer/VBoxContainer/Spacer/Nodes
onready var items = $MarginContainer/VBoxContainer/Controls/MarginContainer/Items
onready var status = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer3/Status
onready var seqItemNode = load("res://panel/sequence/SequenceItemNode.tscn")
onready var seqItem = load("res://panel/sequence/SequenceItem.tscn")

var running = false

func _log(s):
  print(s)
  if status != null:
    status.text = s

export var seq_items = [] setget _set_seq_items
func _set_seq_items(si):
  for c in items.get_children():
    c.queue_free()
  for i in si:
    var inst = seqItem.instance()
    inst.text = i
    items.add_child(inst)
    var err = inst.connect("create_item", self, "_on_sequence_item_pressed")
    if err != OK:
      _log("Error connecting seqItem: %s" % err)
      inst.queue_free()
      continue
    
  seq_items = items

func _ready():
  _set_seq_items(["test1", "test2"])
  # $MarginContainer/VBoxContainer/Spacer/Nodes.get_zoom_hbox().visible = false

func _on_GridContainer_connection_request(from, from_slot, to, to_slot):
  # TODO prevent creation of cycles
  if running:
    _log("Cannot change connections while running")
    return
  nodes.connect_node(from, from_slot, to, to_slot)

func _on_sequence_item_pressed(n):
  rpc("create_sequence_item", n)

remotesync func create_sequence_item(n):
  var i = seqItemNode.instance()
  i.title = n  
  nodes.add_child(i)
  _log("Added node %s" % n)

func _on_Left_pressed():
  print("left")

func _on_Right_pressed():
  print("right")

func _on_Run_pressed():
  var seqMap = {}
  for c in nodes.get_connection_list():
    if c.from_port != 0 or c.to_port != 0:
      _log("Error: weird port connection %s" % c)
      return
    if seqMap.get(c.from) != null:
      _log("Error: multiple edges out from %s" % c.from)
      return
    seqMap[c.from] = c.to

  var origins = {}
  for c in nodes.get_children():
    if c is GraphNode:
      origins[c.name] = true
  for k in seqMap:
    origins[seqMap[k]] = false
  var seq = []
  for k in origins:
    if origins[k]:
      seq.append(k)
  if len(seq) != 1:
    _log("Error: need 1 start node, got: %s" % [seq])
    return
  
  print(seq[0])
  var cmds = [nodes.get_node(seq[0]).title]
  while seqMap.get(seq[-1]):
    seq.append(seqMap[seq[-1]])
    cmds.append(nodes.get_node(seq[-1]).title)
  
  running = true
  emit_signal("run_sequence", cmds, seq)
  print("TODO run from start %s" % [cmds])

func _on_Stop_pressed():
  running = false
  emit_signal("stop_sequence")

func _on_Clear_pressed():
  for c in nodes.get_children():
    if c is GraphNode:
      c.queue_free()
