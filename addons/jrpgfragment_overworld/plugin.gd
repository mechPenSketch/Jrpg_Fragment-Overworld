@tool
extends EditorPlugin

const OVERWORLD_SINGLETON_NAME := "GlobalOverworld"
const OVERWORLD_SINGLETON_PATH := "res://content/overworld/global.gd"

const PROP_PIECE_ICON_PATH := "res://addons/jrpgfragment_overworld/toolbtn_icons/add_prop.svg"
const WALKING_PIECE_ICON_PATH := "res://addons/jrpgfragment_overworld/toolbtn_icons/add_walk.svg"
const WARP_PIECE_ICON_PATH := "res://addons/jrpgfragment_overworld/toolbtn_icons/add_warp.svg"

const PROP_PIECE_SCENE_PATH := "res://content/overworld/playing_pieces/playing_piece.tscn"
const WALKING_PIECE_SCENE_PATH := "res://content/overworld/playing_pieces/walkables/walkable.tscn"
const WARP_PIECE_SCENE_PATH := "res://content/overworld/playing_pieces/warps/warp.tscn"

var new_tools: Array[Control]

var nearest_game_board: GameBoard

func _enter_tree():
	# Define new buttons
	#	Prop Piece
	var prop_piece_btn = generate_toolbtn()
	prop_piece_btn.set_button_icon(load(PROP_PIECE_ICON_PATH))
	prop_piece_btn.pressed.connect(_add_new_node.bind(load(PROP_PIECE_SCENE_PATH)))
	new_tools.append(prop_piece_btn)
	
	#	Walking Piece
	var walk_piece_btn = generate_toolbtn()
	walk_piece_btn.set_button_icon(load(WALKING_PIECE_ICON_PATH))
	walk_piece_btn.pressed.connect(_add_new_node.bind(load(WALKING_PIECE_SCENE_PATH)))
	new_tools.append(walk_piece_btn)
	
	#	Warping
	var warp_piece_btn = generate_toolbtn()
	warp_piece_btn.set_button_icon(load(WARP_PIECE_ICON_PATH))
	warp_piece_btn.pressed.connect(_add_new_node.bind(load(WARP_PIECE_SCENE_PATH)))
	new_tools.append(warp_piece_btn)
	
	# Add new buttons to toolbar
	for nd in new_tools:
		add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, nd)
	
	# On changing scenes
	scene_changed.connect(func(scene_root):
		nearest_game_board = null
		show_or_hide_new_toolbtns(scene_root)
	)


func _exit_tree():
	# Toolbar buttons
	for nd in new_tools:
		remove_control_from_container(CONTAINER_CANVAS_EDITOR_MENU, nd)
		nd.queue_free()


func _disable_plugin():
	remove_autoload_singleton(OVERWORLD_SINGLETON_NAME)


func _enable_plugin():
	# Add singleton for overworld data
	add_autoload_singleton(OVERWORLD_SINGLETON_NAME, OVERWORLD_SINGLETON_PATH)


func _add_new_node(pksc: PackedScene):
	if nearest_game_board:
		var inst = pksc.instantiate()
		nearest_game_board.add_child(inst, true)
		inst.set_owner(get_editor_interface().get_edited_scene_root())
		get_editor_interface().mark_scene_as_unsaved()


func generate_toolbtn()-> Button:
	var btn = Button.new()
	btn.set_flat(true)
	return btn


func node_is_gameboard(node)-> bool:
	if node is GameBoard:
		nearest_game_board = node
		return true
	else:
		for n in node.get_children():
			if node_is_gameboard(n):
				return true
	
	return false


## Sets the visibility of the new tool buttons
## to [param true] or [param false], depending
## on whether the scene contains [GameBoard].
func show_or_hide_new_toolbtns(scene_root):
	var visibility = node_is_gameboard(scene_root)
	
	for nd in new_tools:
		nd.set_visible(visibility)
