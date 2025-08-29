# area_indicator.gd
extends MeshInstance3D
class_name AreaIndicator

func setup(shape: String, size: Vector3):
	var mesh: Mesh
	match shape:
		"circle":
			var m = CylinderMesh.new()
			m.height = size.y
			m.top_radius = size.x
			m.bottom_radius = size.x
			mesh = m
		"line":
			var b = BoxMesh.new()
			b.size = size
			mesh = b
		"cone":
			var c = CylinderMesh.new()
			c.height = size.y
			c.top_radius = size.x
			c.bottom_radius = 0.0
			mesh = c
		_: 
			mesh = BoxMesh.new()
			mesh.size = size
	
	self.mesh = mesh
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0, 0, 0.4) # đỏ trong suốt
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	self.material_override = mat
