extends StaticBody2D
## Arbre décoratif (placeholder). Son origine est au pied du tronc pour le tri en Y.


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, 16.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(-4, -22, 8, 22), Color("6b4a2b"))
	draw_circle(Vector2(0, -40), 22.0, Color("2f6b34"))
	draw_circle(Vector2(-8, -48), 12.0, Color("3d8443"))
