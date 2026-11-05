extends RefCounted
class_name ShopMapLoader

const LAYER_ORDER := [
	"Floor",
	"Floor_wood",
	"Stairs",
	"Carpet",
	"Walls1",
	"Walls2",
	"Walls3",
	"Furniture1",
	"Furniture2",
	"Furniture3",
	"Furniture4",
	"Furniture5",
	"Furniture6",
	"Forge",
]

const COLLISION_LAYERS := {
	"Walls1": true,
	"Walls2": true,
	"Walls3": true,
}

const TILESETS := [
	{
		"first_gid": 1,
		"texture": "res://assets/craftpix/tiles/Walls_interior.png",
		"columns": 16,
	},
	{
		"first_gid": 273,
		"texture": "res://assets/craftpix/tiles/Interior_objects.png",
		"columns": 13,
	},
	{
		"first_gid": 780,
		"texture": "res://assets/craftpix/maps/Forge.png",
		"columns": 24,
	},
	{
		"first_gid": 924,
		"texture": "res://assets/craftpix/maps/Light_animation.png",
		"columns": 8,
	},
]


static func build(parent: Node2D, tmx_path: String, scene_owner: Node = null) -> Dictionary:
	var xml_text := FileAccess.get_file_as_string(tmx_path)
	if xml_text.is_empty():
		push_error("TMX não encontrado: %s" % tmx_path)
		return {}

	# Rebuild limpo para manter o mapa previsível no editor.
	for child in parent.get_children():
		child.queue_free()

	var tile_set := _create_tile_set()
	var layers := _parse_layers(xml_text)
	var bounds := Rect2i(9999, 9999, -9999, -9999)
	var collision_cells: Dictionary = {}

	for layer_name in LAYER_ORDER:
		if not layers.has(layer_name):
			continue
		var layer := TileMapLayer.new()
		layer.name = layer_name
		layer.tile_set = tile_set
		layer.z_index = LAYER_ORDER.find(layer_name)
		parent.add_child(layer)
		if scene_owner != null:
			layer.owner = scene_owner

		for chunk in layers[layer_name]:
			var chunk_x: int = chunk["x"]
			var chunk_y: int = chunk["y"]
			var width: int = chunk["width"]
			var height: int = chunk["height"]
			var cells: PackedInt32Array = chunk["cells"]
			for local_y in range(height):
				for local_x in range(width):
					var gid: int = cells[local_y * width + local_x]
					if gid <= 0:
						continue
					var world_cell := Vector2i(chunk_x + local_x, chunk_y + local_y)
					var mapped := _map_gid(gid)
					if mapped.is_empty():
						continue
					layer.set_cell(world_cell, mapped["source"], mapped["atlas"])
					bounds = _expand_bounds(bounds, world_cell)
					if COLLISION_LAYERS.has(layer_name):
						collision_cells[world_cell] = true

	if bounds.size.x < 0:
		return {"bounds": Rect2i(), "world_offset": Vector2.ZERO}

	var world_offset := Vector2(-bounds.position.x * 16, -bounds.position.y * 16)
	parent.position = world_offset
	_build_colliders(parent, collision_cells, scene_owner)
	var pixel_bounds := Rect2i(
		0,
		0,
		(bounds.size.x + 1) * 16,
		(bounds.size.y + 1) * 16
	)
	return {"bounds": pixel_bounds, "world_offset": world_offset}


static func _build_colliders(parent: Node2D, collision_cells: Dictionary, scene_owner: Node = null) -> void:
	var collision_root := StaticBody2D.new()
	collision_root.name = "MapColliders"
	parent.add_child(collision_root)
	if scene_owner != null:
		collision_root.owner = scene_owner

	for cell in collision_cells.keys():
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(16, 16)
		shape.shape = rect
		shape.position = Vector2(cell.x * 16 + 8, cell.y * 16 + 8)
		collision_root.add_child(shape)
		if scene_owner != null:
			shape.owner = scene_owner


static func _create_tile_set() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(16, 16)

	for source_index in range(TILESETS.size()):
		var info: Dictionary = TILESETS[source_index]
		var texture: Texture2D = load(info["texture"])
		var columns: int = info["columns"]
		var rows := int(ceil(float(texture.get_height()) / 16.0))

		var source := TileSetAtlasSource.new()
		source.texture = texture
		source.texture_region_size = Vector2i(16, 16)
		for y in range(rows):
			for x in range(columns):
				if (y * 16) >= texture.get_height() or (x * 16) >= texture.get_width():
					continue
				source.create_tile(Vector2i(x, y))
		tile_set.add_source(source, source_index)

	return tile_set


static func _map_gid(gid: int) -> Dictionary:
	var clean_gid := gid & 0x1FFFFFFF
	for source_index in range(TILESETS.size() - 1, -1, -1):
		var info: Dictionary = TILESETS[source_index]
		if clean_gid >= info["first_gid"]:
			var local_id: int = clean_gid - info["first_gid"]
			var columns: int = info["columns"]
			return {
				"source": source_index,
				"atlas": Vector2i(local_id % columns, local_id / columns),
			}
	return {}


static func _parse_layers(xml_text: String) -> Dictionary:
	var layers := {}
	var current_layer := ""
	var in_chunk := false
	var chunk := {}
	var chunk_lines: PackedStringArray = []

	for raw_line in xml_text.split("\n"):
		var line := raw_line.strip_edges()
		if line.begins_with("<layer "):
			var name_start := line.find("name=\"")
			if name_start != -1:
				name_start += 6
				var name_end := line.find("\"", name_start)
				current_layer = line.substr(name_start, name_end - name_start)
				layers[current_layer] = []
		elif line.begins_with("</layer>"):
			current_layer = ""
		elif current_layer.is_empty():
			continue
		elif line.begins_with("<chunk "):
			in_chunk = true
			chunk = {}
			chunk_lines = []
			for key in ["x", "y", "width", "height"]:
				var token := "%s=\"" % key
				var start := line.find(token)
				if start != -1:
					start += token.length()
					var end := line.find("\"", start)
					chunk[key] = int(line.substr(start, end - start))
		elif line.begins_with("</chunk>"):
			in_chunk = false
			var width: int = chunk.get("width", 0)
			var height: int = chunk.get("height", 0)
			var cells := PackedInt32Array()
			cells.resize(width * height)
			var row := 0
			for chunk_line in chunk_lines:
				if chunk_line.is_empty():
					continue
				var values := chunk_line.split(",")
				for col in mini(values.size(), width):
					var value := values[col].strip_edges()
					if value.is_empty():
						continue
					cells[row * width + col] = int(value)
				row += 1
				if row >= height:
					break
			chunk["cells"] = cells
			layers[current_layer].append(chunk)
		elif in_chunk and not line.begins_with("<"):
			chunk_lines.append(line)

	return layers


static func _expand_bounds(current: Rect2i, cell: Vector2i) -> Rect2i:
	if current.size.x < 0:
		return Rect2i(cell, Vector2i(1, 1))
	var min_x: int = mini(current.position.x, cell.x)
	var min_y: int = mini(current.position.y, cell.y)
	var max_x: int = maxi(current.position.x + current.size.x - 1, cell.x)
	var max_y: int = maxi(current.position.y + current.size.y - 1, cell.y)
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
