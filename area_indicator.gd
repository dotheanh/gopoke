# area_indicator.gd
extends MeshInstance3D
class_name AreaIndicator

func setup(shape: String, size: Vector3):
	var m: Mesh
	match shape:
		"circle":
			var cyl = CylinderMesh.new()
			cyl.height = size.y
			cyl.top_radius = size.x
			cyl.bottom_radius = size.x
			m = cyl
		"line":
			var box = BoxMesh.new()
			box.size = size
			m = box
		"cone":
			var cone = CylinderMesh.new()
			cone.height = size.y
			cone.top_radius = size.x
			cone.bottom_radius = 0.0
			m = cone
		_:
			var def = BoxMesh.new()
			def.size = size
			m = def

	self.mesh = m
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0, 0, 0.4) # đỏ trong suốt
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	self.material_override = mat
