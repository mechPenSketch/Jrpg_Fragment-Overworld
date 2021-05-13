tool
extends PlayingPiece

class_name Event

var base

var default_texture
var children_sprites

signal turning
var is_moving = false
export (NodePath) var np_tween
var tween
var target_pos = Vector2()
var blocks = []
var is_blocked:bool = false
export (Dictionary) var raycast_directions
var raycast
export (Resource) var incoming
signal incoming_gone
export (Array, Dictionary) var action_sequences
var jump_targets = {}

func _notification(what):
	match what:
		NOTIFICATION_PARENTED:
			prepare_for_when_children_sprites_are_set()
		NOTIFICATION_UNPARENTED:
			disconnect_children_sprites()
			prepare_for_when_children_sprites_are_set()

func _ready():
	if Engine.editor_hint:
		default_texture = load(get_default_texture_filepath())
		
		# WHEN CHILDREN SPRITES' TEXTURES ARE SET
		prepare_for_when_children_sprites_are_set()
	else:
		base = get_node("/root/Game")
		
		set_parent_tilemap(get_parent())
	
		if np_tween: tween = get_node(np_tween)
		
		if raycast_directions.has(Vector2(0,1)):
			turn(Vector2(0,1))
			
		for i in action_sequences.size():
			var d = action_sequences[i]
			if d["action_type"] == "Label" and d.has("name"):
				jump_targets[d["name"]] = i

func disconnect_children_sprites():
	if children_sprites:
		for cs in children_sprites:
			cs.disconnect("texture_changed", self, "_on_children_sprites_texture_changed")

func prepare_for_when_children_sprites_are_set():
	children_sprites = []
	children_sprites = get_children_sprites(self)
	for cs in children_sprites:
		if !cs.is_connected("texture_changed", self, "_on_children_sprites_texture_changed"):
			cs.connect("texture_changed", self, "_on_children_sprites_texture_changed")

func _draw():
	if !is_drawable_sprite_then_children(self):
		var rect_size
		if parent_tilemap:
			rect_size = parent_tilemap.get_cell_size
		else:
			rect_size = Vector2(32, 32)
		var rect_topleft = get_topleft_corner()
		var rect = Rect2(rect_topleft, rect_size)
		
		draw_texture_rect(default_texture, rect, false)

func _on_children_sprites_texture_changed():
	update()

func _action():
	# PAUSED NODE CAN STILL RECIEVE SIGNALS
	if !get_tree().is_paused():
		var collider = raycast.get_collider()
		if collider:
			collider.perform_actions()

func _direction(dir:Vector2):
	if !get_tree().is_paused() and !is_moving:
		
		turn(dir)
		if !raycast.is_colliding():
			grid_position += dir
			target_pos = get_position() + dir * parent_tilemap.get_cell_size()
			
			# ADD INCOMING BLOCK
			var new_incoming = incoming.instance()
			new_incoming.set_position(target_pos)
			parent_tilemap.add_child(new_incoming)
			connect("incoming_gone", new_incoming, "queue_free")
			
			tween.move_char(self, target_pos)
			is_moving = true

func _on_tween_completed(_o, _k):
	is_moving = false
	emit_signal("incoming_gone")

func _on_area_entered(a):
	if a.get_parent() != $Position2D:
		blocks.append(a)
		is_blocked = true

func _on_area_exited(a):
	blocks.erase(a)
	is_blocked = blocks.size()

func get_default_texture_filepath():
	return "res://content/event/event.svg"

func get_children_sprites(node):
	var array = []
	
	if node is Sprite:
		array += [node]
	
	for c in node.get_children():
		array += get_children_sprites(c)
	
	return array

func get_topleft_corner():
	if parent_tilemap:
		return parent_tilemap.get_cell_size() * -0.5
	else:
		return Vector2(-16, -16)

func is_drawable_sprite(node):
	return node is Sprite and node.texture != null

func is_drawable_sprite_then_children(node):
	if is_drawable_sprite(node):
		return true
	else:
		for c in node.get_children():
			if is_drawable_sprite_then_children(c):
				return true
	return false

func perform_actions(i = 0):
	get_node("/root/Game/Action").initiate_action_sequence(self, i)

func plugset_cell_width(w):
	.plugset_cell_width(w)
	update()
	
func plugset_cell_height(h):
	.plugset_cell_height(h)
	update()

func turn(dir:Vector2):
	raycast = get_node(raycast_directions[dir])
	emit_signal("turning", dir)
