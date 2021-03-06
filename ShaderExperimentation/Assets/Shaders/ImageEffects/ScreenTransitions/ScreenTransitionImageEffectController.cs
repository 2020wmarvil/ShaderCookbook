using UnityEngine;

public class ScreenTransitionImageEffectController : MonoBehaviour {
	[SerializeField] ScreenTransitionImageEffect effect;
	[SerializeField] float duration;
	
	float cutoff = 0f;
	bool running = false;

	void Update() {
		if (running) {
			cutoff += Time.deltaTime / duration;
		}

		if (Input.GetKeyDown(KeyCode.Space)) {
			cutoff = 0f;
			running = true;
		}

		effect.SetCutoff(cutoff);
	}
}
