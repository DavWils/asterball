extends Control

func set_interactable(interactable: Node3D) -> void:
	if not interactable:
		return
		
	if interactable.has_method("get_interact_text"):
		$InteractableLabel.text = interactable.get_interact_text()
