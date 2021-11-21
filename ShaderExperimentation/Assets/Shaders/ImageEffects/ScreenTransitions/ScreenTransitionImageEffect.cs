using UnityEngine;

[ExecuteInEditMode]
public class ScreenTransitionImageEffect : MonoBehaviour {
	[SerializeField] Material effectMat;

	void OnRenderImage(RenderTexture source, RenderTexture destination) {
		Graphics.Blit(source, destination, effectMat);
	}

	void OnDisable() {
		effectMat.SetFloat("_Cutoff", 0);
	}

	public void SetCutoff(float cutoff) {
		effectMat.SetFloat("_Cutoff", cutoff);
	}

}
