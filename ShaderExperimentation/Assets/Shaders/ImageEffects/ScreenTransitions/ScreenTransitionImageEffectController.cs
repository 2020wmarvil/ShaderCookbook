using UnityEngine;

public class ScreenTransitionImageEffectController : MonoBehaviour {
	[SerializeField] ScreenTransitionImageEffect effect;
	[SerializeField] float duration;
	
	float cutoff = 0f;

	void Update() {
		cutoff += Time.deltaTime / duration;
		if (Input.GetKeyDown(KeyCode.Space)) cutoff = 0f;
		effect.SetCutoff(cutoff);
	}
}
