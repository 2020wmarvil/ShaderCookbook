using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine;

[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
public class ShellTextureGeo : MonoBehaviour {
	[System.Serializable, StructLayout(LayoutKind.Sequential)]
	public struct InputVertex {
		public Vector3 position;
		public Vector3 normal;
		public Vector2 uv;
	}

	[System.Serializable, StructLayout(LayoutKind.Sequential)]
	public struct InputTriangle {
		public InputVertex vertex0;
		public InputVertex vertex1;
		public InputVertex vertex2;
	}

	public ComputeShader shellTextureCS;
	public Material renderingMaterial;
	[Min(1)] public int layers = 1;
	public float heightOffset = 0f;

	private int kernelID;
	private int threadGroupSize;

	private int[] indirectArgs = new int[] { 0, 1, 0, 0 };

	private List<InputTriangle> inputTriangles;

	private ComputeBuffer inputTrianglesBuffer;
	private ComputeBuffer drawTrianglesBuffer;
	private ComputeBuffer indirectArgsBuffer;

	private const int INPUT_TRIANGLES_STRIDE = sizeof(float) * 3 * (3 + 3 + 2); // 3 vertices each holding a pos, normal, and uv
	private const int DRAW_TRIANGLES_STRIDE = sizeof(float) * 3 * (3 + 3 + 2 + 4);
	private const int INDIRECT_ARGS_STRIDE = sizeof(int) * 4;

	private Mesh mesh;
	private MeshRenderer meshRenderer;
	private int triangleCount;
	private bool initialized;

	private void OnEnable() {
		mesh = GetComponent<MeshFilter>().sharedMesh;
		meshRenderer = GetComponent<MeshRenderer>();
		triangleCount = mesh.triangles.Length / 3;

		SetupBuffers();
		SetupData();
		GenerateGeometry();
	}

	private void OnDisable() {
		ReleaseBuffers();
	}

	private void OnValidate() {
		initialized = false;
		SetupBuffers();
		SetupData();
		GenerateGeometry();
	}

	void SetupBuffers() {
		inputTrianglesBuffer = new ComputeBuffer(triangleCount, INPUT_TRIANGLES_STRIDE, ComputeBufferType.Structured, ComputeBufferMode.Immutable);
		drawTrianglesBuffer = new ComputeBuffer(triangleCount * layers, DRAW_TRIANGLES_STRIDE, ComputeBufferType.Append);
		indirectArgsBuffer = new ComputeBuffer(1, INDIRECT_ARGS_STRIDE, ComputeBufferType.IndirectArguments);
	}

	void ReleaseBuffers() {
		ReleaseBuffer(inputTrianglesBuffer);
		ReleaseBuffer(drawTrianglesBuffer);
		ReleaseBuffer(indirectArgsBuffer);
	}

	void ReleaseBuffer(ComputeBuffer buffer) {
		if (buffer != null) {
			buffer.Release();
			buffer = null;
		}
	}

	void SetupData() {
		if (mesh == null) return;

		inputTriangles = new List<InputTriangle>();
		for (int i=0; i<triangleCount; i++) {
			InputTriangle inputTriangle = new InputTriangle();
			inputTriangles.Add(inputTriangle);
		}

		for (int i=0; i<mesh.triangles.Length; i+=3) {
			int triangle = i / 3;

			InputTriangle tri = inputTriangles[triangle];

			tri.vertex0.position = mesh.vertices[mesh.triangles[i]];
			tri.vertex0.normal = mesh.normals[mesh.triangles[i]];
			tri.vertex0.uv = mesh.uv[mesh.triangles[i]];

			tri.vertex1.position = mesh.vertices[mesh.triangles[i+1]];
			tri.vertex1.normal = mesh.normals[mesh.triangles[i+1]];
			tri.vertex1.uv = mesh.uv[mesh.triangles[i+1]];

			tri.vertex2.position = mesh.vertices[mesh.triangles[i+2]];
			tri.vertex2.normal = mesh.normals[mesh.triangles[i+2]];
			tri.vertex2.uv = mesh.uv[mesh.triangles[i+2]];

			inputTriangles[triangle] = tri;
		}

		inputTrianglesBuffer.SetData(inputTriangles);
		drawTrianglesBuffer.SetCounterValue(0);
		indirectArgsBuffer.SetData(indirectArgs);
	}

	void GenerateGeometry() {
		if (mesh == null || shellTextureCS == null || renderingMaterial == null) return;

		kernelID = shellTextureCS.FindKernel("ShellTextureGeo");
		shellTextureCS.GetKernelThreadGroupSizes(kernelID, out uint threadGroupSizeX, out _, out _);
		threadGroupSize = Mathf.CeilToInt((float)triangleCount / threadGroupSizeX);

		shellTextureCS.SetBuffer(kernelID, "_InputTrianglesBuffer", inputTrianglesBuffer);
		shellTextureCS.SetBuffer(kernelID, "_DrawTrianglesBuffer", drawTrianglesBuffer);
		shellTextureCS.SetBuffer(kernelID, "_IndirectArgsBuffer", indirectArgsBuffer);

		shellTextureCS.SetInt("_TriangleCount", triangleCount);
		shellTextureCS.SetMatrix("_LocalToWorld", transform.localToWorldMatrix);
		shellTextureCS.SetInt("_Layers", layers);
		shellTextureCS.SetFloat("_HeightOffset", heightOffset);

		renderingMaterial.SetBuffer("_DrawTrianglesBuffer", drawTrianglesBuffer);

		shellTextureCS.Dispatch(kernelID, threadGroupSize, 1, 1);

		initialized = true;
	}

	private void Update() {
		if (!initialized) return;

		Graphics.DrawProceduralIndirect(
			renderingMaterial, 
			meshRenderer.bounds, 
			MeshTopology.Triangles, 
			indirectArgsBuffer, 
			0, null, null, 
			UnityEngine.Rendering.ShadowCastingMode.Off, true, gameObject.layer);
	}
}
