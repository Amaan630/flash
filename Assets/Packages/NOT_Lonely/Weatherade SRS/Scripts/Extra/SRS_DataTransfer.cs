using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

#if UNITY_EDITOR
[ExecuteInEditMode]
#endif

public class SRS_DataTransfer : MonoBehaviour
{
    private void OnEnable()
    {
        //SRS_Manager.srs_dataTransfer = this;
        RenderPipelineManager.beginCameraRendering += OnCamPreRender;
    }

    private void OnDisable()
    {
        //SRS_Manager.srs_dataTransfer = null;
        RenderPipelineManager.beginCameraRendering -= OnCamPreRender;
    }

    private void OnCamPreRender(ScriptableRenderContext context, Camera cam)
    {
        if ((Application.isPlaying && cam.tag == "MainCamera") || !Application.isPlaying)
        {
            Shader.SetGlobalVector("_viewCamUp", cam.transform.up);
            Shader.SetGlobalVector("_viewCamRight", cam.transform.right);
            //Debug.Log($"{cam.name} up vector = {cam.transform.up}");
        }
    }
}
