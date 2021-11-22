using UnityEngine;

public class LightSpinning : MonoBehaviour {
    void Update() {
        transform.Rotate(new Vector3(0, 1, 0), .1f);
    }
}
