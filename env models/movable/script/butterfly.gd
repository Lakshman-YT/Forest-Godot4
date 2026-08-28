extends Node3D

var player: CharacterBody3D 

@export var material: Array[StandardMaterial3D]

func spawn_butterfly():
	$AnimationPlayer.play("fly")
	$Armature/Skeleton3D/Plane.set_surface_override_material(0,material.pick_random())
	
