using UnityEngine;

[ExecuteInEditMode]
public class ScreenTransitionImageEffect : MonoBehaviour {
	[SerializeField] Material effectMat;

	void OnRenderImage(RenderTexture source, RenderTexture destination) {
		Graphics.Blit(source, destination, effectMat);
	}
}
