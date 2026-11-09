extends StaticBody3D

# Interaction proxy for the station's front door. The imported model has no
# colliders, so this invisible body sits in front of the modelled door and
# hands the player over to the interior story scene.


func get_localized_title() -> String:
	return Loc.t("hawkins.entrance")