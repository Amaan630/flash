using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class SRS_RenderDepthWithReplacement : ScriptableRendererFeature
{
    public class CustomRenderPass : ScriptableRenderPass
    {

        private Settings settings;
        private FilteringSettings filteringSettings;
        private ProfilingSampler _profilingSampler;
        private List<ShaderTagId> shaderTagsList = new List<ShaderTagId>();
        private RTHandle rtCustomColor, rtCameraDepth;

        public CustomRenderPass(Settings settings, string name)
        {
            this.settings = settings;
            filteringSettings = new FilteringSettings(settings.queue, settings.layerMask);

            // Use default tags
            shaderTagsList.Add(new ShaderTagId("SRPDefaultUnlit"));
            shaderTagsList.Add(new ShaderTagId("UniversalForward"));
            shaderTagsList.Add(new ShaderTagId("UniversalForwardOnly"));

            _profilingSampler = new ProfilingSampler(name);
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            rtCustomColor = renderingData.cameraData.renderer.cameraColorTargetHandle;
            RTHandle rtCameraDepth = renderingData.cameraData.renderer.cameraDepthTargetHandle;

            ConfigureTarget(rtCustomColor, rtCameraDepth);
            ConfigureClear(ClearFlag.Color, new Color(0, 0, 0, 0));
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get();
            // Set up profiling scope for Profiler & Frame Debugger
            using (new ProfilingScope(cmd, _profilingSampler))
            {
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                SortingCriteria sortingCriteria = renderingData.cameraData.defaultOpaqueSortFlags;
                DrawingSettings drawingSettings = CreateDrawingSettings(shaderTagsList, ref renderingData, sortingCriteria);

                drawingSettings.overrideShader = settings.replacementShader;
                drawingSettings.overrideShaderPassIndex = 0;

                context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref filteringSettings);
            }
            // Execute Command Buffer one last time and release it
            // (otherwise we get weird recursive list in Frame Debugger)
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }

        public override void OnCameraCleanup(CommandBuffer cmd) { }
    }

    // Exposed Settings
    [System.Serializable]
    public class Settings
    {
        public RenderPassEvent _event = RenderPassEvent.AfterRenderingOpaques;

        public LayerMask layerMask = ~0;
        public RenderQueueRange queue = RenderQueueRange.opaque;
        public Shader replacementShader; //Use Hidden/NOT_Lonely/Weatherade/DepthRenderer
    }

    public Settings settings = new Settings();

    // Feature Methods

    private CustomRenderPass m_ScriptablePass;

    public override void Create()
    {
        m_ScriptablePass = new CustomRenderPass(settings, name);
        m_ScriptablePass.renderPassEvent = settings._event;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        CameraType cameraType = renderingData.cameraData.cameraType;
        if (cameraType == CameraType.Preview) return; // Ignore feature for editor/inspector previews & asset thumbnails
        renderer.EnqueuePass(m_ScriptablePass);
    }

    protected override void Dispose(bool disposing)
    {

    }
}