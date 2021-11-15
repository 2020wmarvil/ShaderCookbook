using UnityEngine;

[ExecuteInEditMode]
public class BlurImageEffect : MonoBehaviour {
	[SerializeField] Material effectMat;
	[Range(0, 8)]
	[SerializeField] int downSamples;
	[Range(0, 10)]
	[SerializeField] int iterations;

	void OnRenderImage(RenderTexture source, RenderTexture destination) {
		int width = source.width >> downSamples;
		int height = source.height >> downSamples;

		RenderTexture rt = RenderTexture.GetTemporary(width, height);
		Graphics.Blit(source, rt);

		for (int i=0; i<iterations; i++) {
			RenderTexture rt2 = RenderTexture.GetTemporary(width, height);
			Graphics.Blit(rt, rt2, effectMat);
			RenderTexture.ReleaseTemporary(rt);
			rt = rt2;
		}

		Graphics.Blit(rt, destination);
		RenderTexture.ReleaseTemporary(rt);
	}
}
