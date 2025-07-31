using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(ObjectFader))]
public class ObjectFaderEditor : Editor
{
    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();

        GUILayout.Space(10);
        GUILayout.Label("Test Fade Controls", EditorStyles.boldLabel);

        ObjectFader fader = (ObjectFader)target;

        GUI.enabled = Application.isPlaying;

        if (GUILayout.Button("⤴ Fade In"))
        {
            fader.FadeIn();
        }

        if (GUILayout.Button("⤵ Fade Out"))
        {
            fader.FadeOut();
        }

        GUI.enabled = true;
    }
}
